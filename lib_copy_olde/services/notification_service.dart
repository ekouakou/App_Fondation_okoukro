import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'pouls_scolaire_api_service.dart';
import 'auth_service.dart';
import 'database_service.dart';

/// Service pour gérer les notifications push
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final PoulsScolaireApiService _apiService = PoulsScolaireApiService();

  String? _fcmToken;
  StreamController<Map<String, dynamic>>? _notificationStreamController;
  Stream<Map<String, dynamic>>? _notificationStream;
  FirebaseMessaging? _firebaseMessaging;

  /// Stream pour écouter les notifications reçues
  Stream<Map<String, dynamic>> get notificationStream {
    _notificationStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    _notificationStream ??= _notificationStreamController!.stream;
    return _notificationStream!;
  }

  /// Initialise le service de notifications
  Future<void> initialize() async {
    try {
      // Initialiser FirebaseMessaging seulement maintenant
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 Permission de notification: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notifications autorisées');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Notifications provisoires');
      } else {
        print('❌ Notifications refusées');
        return;
      }

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      await _getFCMToken();

      // Configurer les handlers pour les notifications
      _setupNotificationHandlers();

      // Écouter les changements de token
      _firebaseMessaging?.onTokenRefresh.listen((newToken) {
        print('🔄 Token FCM rafraîchi: $newToken');
        _fcmToken = newToken;
        _saveTokenToPreferences(newToken);
        _registerTokenToBackend(newToken);
      });

      print('✅ Service de notifications initialisé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Initialise les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer un canal de notification pour Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pouls_ecole_notifications',
      'Notifications Pouls École',
      description: 'Notifications pour les mises à jour scolaires',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Configure les handlers pour les notifications
  void _setupNotificationHandlers() {
    // Notification reçue quand l'app est en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notification reçue (foreground): ${message.notification?.title}');
      _handleNotification(message);
      _showLocalNotification(message);
    });

    // Notification reçue quand l'app est en background et l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Notification ouverte depuis background: ${message.notification?.title}');
      _handleNotification(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    _firebaseMessaging?.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📨 App ouverte depuis une notification: ${message.notification?.title}');
        _handleNotification(message);
      }
    });
  }

  /// Gère une notification reçue
  void _handleNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final data = message.data;
    final timestamp = DateTime.now();
    
    // Générer un ID unique pour la notification
    final notificationId = '${timestamp.millisecondsSinceEpoch}_${message.hashCode}';
    
    // Déterminer l'expéditeur depuis les données ou utiliser une valeur par défaut
    String? sender;
    if (data.containsKey('sender')) {
      sender = data['sender'] as String?;
    } else if (data.containsKey('type')) {
      // Utiliser le type comme expéditeur si disponible
      final type = data['type'] as String?;
      if (type != null) {
        // Mapper les types aux noms d'expéditeurs
        switch (type.toLowerCase()) {
          case 'note_added':
          case 'note_updated':
            sender = 'Système de notes';
            break;
          case 'message_received':
            sender = 'Messagerie';
            break;
          case 'fee_added':
            sender = 'Comptabilité';
            break;
          case 'absence':
            sender = 'Secrétariat';
            break;
          default:
            sender = 'Direction de l\'établissement';
        }
      }
    } else {
      sender = 'Direction de l\'établissement';
    }
    
    // Récupérer l'utilisateur actuel pour associer la notification
    final user = await _getCurrentUser();
    final parentId = user?.id;
    
    // Sauvegarder la notification dans la base de données
    try {
      final databaseService = DatabaseService.instance;
      await databaseService.saveNotification(
        id: notificationId,
        title: title,
        body: body,
        data: data.isNotEmpty ? data : null,
        timestamp: timestamp,
        sender: sender,
        parentId: parentId,
      );
      print('✅ Notification sauvegardée: $title');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la notification: $e');
    }
    
    // Émettre l'événement sur le stream
    final streamData = {
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
    _notificationStreamController?.add(streamData);
  }

  /// Affiche une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pouls_ecole_notifications',
        'Notifications Pouls École',
        channelDescription: 'Notifications pour les mises à jour scolaires',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _notificationStreamController?.add({
          'title': data['title'] ?? 'Notification',
          'body': data['body'] ?? '',
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('⚠️ Erreur lors du parsing du payload: $e');
      }
    }
  }

  /// Obtient le token FCM
  Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging?.getToken();
      if (_fcmToken != null) {
        print('🔑 Token FCM obtenu: $_fcmToken');
        await _saveTokenToPreferences(_fcmToken!);
        await _registerTokenToBackend(_fcmToken!);
      }
      return _fcmToken;
    } catch (e) {
      print('❌ Erreur lors de l\'obtention du token FCM: $e');
      return null;
    }
  }

  /// Sauvegarde le token dans les préférences
  Future<void> _saveTokenToPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('⚠️ Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Enregistre le token auprès du backend
  Future<void> _registerTokenToBackend(String token) async {
    try {
      final user = await _getCurrentUser();
      if (user != null) {
        print('📤 Enregistrement du token pour l\'utilisateur: ${user.id}');
        // Déterminer le type d'appareil
        final deviceType = Platform.isIOS ? 'ios' : 'android';
        
        // Récupérer les matricules des enfants de l'utilisateur
        final matricules = await _getMatriculesForUser(user.id);
        print('📋 Matricules trouvés: ${matricules.length}');
        
        if (matricules.isEmpty) {
          print('⚠️ Aucun matricule trouvé pour l\'utilisateur. Le token sera enregistré sans matricule.');
        }
        
        // Enregistrer le token via l'API avec les matricules
        final success = await _apiService.registerNotificationToken(
          token,
          user.id,
          deviceType: deviceType,
          matricules: matricules.isNotEmpty ? matricules : null,
        );
        
        if (success) {
          print('✅ Token enregistré avec succès avec ${matricules.length} matricule(s)');
        } else {
          print('⚠️ Échec de l\'enregistrement du token, mais l\'opération continue');
        }
      } else {
        print('⚠️ Aucun utilisateur connecté, token non enregistré');
      }
    } catch (e) {
      print('⚠️ Erreur lors de l\'enregistrement du token: $e');
      // Ne pas faire échouer l'application si l'enregistrement du token échoue
      // L'utilisateur pourra toujours utiliser l'application
    }
  }
  
  /// Récupère les matricules des enfants d'un utilisateur
  Future<List<String>> _getMatriculesForUser(String userId) async {
    try {
      final databaseService = DatabaseService.instance;
      final childrenInfo = await databaseService.getChildrenInfoByParent(userId);
      
      // Extraire les matricules non null
      final matricules = childrenInfo
          .map((info) => info['matricule'] as String?)
          .where((matricule) => matricule != null && matricule.isNotEmpty)
          .cast<String>()
          .toList();
      
      return matricules;
    } catch (e) {
      print('⚠️ Erreur lors de la récupération des matricules: $e');
      return [];
    }
  }

  /// Récupère l'utilisateur actuel
  Future<User?> _getCurrentUser() async {
    try {
      // Utiliser AuthService pour obtenir l'utilisateur actuel
      final authService = AuthService.instance;
      return authService.getCurrentUser();
    } catch (e) {
      print('⚠️ Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Obtient le token FCM actuel
  String? get token => _fcmToken;
  
  /// Obtient le token FCM de manière asynchrone (récupère depuis Firebase si nécessaire)
  Future<String?> getTokenAsync() async {
    // Si le token est déjà en mémoire, le retourner
    if (_fcmToken != null) {
      return _fcmToken;
    }
    
    // Sinon, essayer de le récupérer depuis les préférences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_token');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        _fcmToken = savedToken;
        print('✅ Token FCM récupéré depuis les préférences');
        return _fcmToken;
      }
      
      // Si pas dans les préférences, essayer de l'obtenir depuis Firebase
      print('🔄 Tentative d\'obtention du token FCM depuis Firebase...');
      try {
        _fcmToken = await _firebaseMessaging?.getToken();
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          await _saveTokenToPreferences(_fcmToken!);
          print('✅ Token FCM obtenu depuis Firebase');
          return _fcmToken;
        }
      } catch (firebaseError) {
        // Gérer spécifiquement les erreurs Firebase
        final errorStr = firebaseError.toString().toLowerCase();
        if (errorStr.contains('service_not_available') || 
            errorStr.contains('firebase installations service is unavailable')) {
          print('⚠️ Service Firebase temporairement indisponible. Le token sera récupéré plus tard.');
          print('   Causes possibles :');
          print('   - Problème de connexion internet');
          print('   - Google Play Services non disponible sur l\'émulateur');
          print('   - Configuration Firebase incomplète (google-services.json)');
          print('   - Le service Firebase est temporairement en panne');
        } else {
          print('❌ Erreur Firebase lors de l\'obtention du token: $firebaseError');
        }
      }
      
      return _fcmToken;
    } catch (e) {
      print('❌ Erreur lors de la récupération asynchrone du token: $e');
      return null;
    }
  }

  /// Supprime le token (déconnexion)
  Future<void> deleteToken() async {
    try {
      final user = await _getCurrentUser();
      final token = _fcmToken;
      
      // Supprimer le token du backend si l'utilisateur est connecté et qu'on a un token
      if (user != null && token != null) {
        print('🗑️ Suppression du token du backend pour l\'utilisateur: ${user.id}');
        await _apiService.unregisterNotificationToken(token, user.id);
      }
      
      // Supprimer le token FCM localement
      await _firebaseMessaging?.deleteToken();
      _fcmToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      print('🗑️ Token FCM supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du token: $e');
    }
  }

  /// S'abonne à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging?.subscribeToTopic(topic);
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement au topic $topic: $e');
    }
  }

  /// Se désabonne d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging?.unsubscribeFromTopic(topic);
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      print('❌ Erreur lors du désabonnement du topic $topic: $e');
    }
  }
}

/// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Notification en background: ${message.notification?.title}');
  // Traitement des notifications en background
}

