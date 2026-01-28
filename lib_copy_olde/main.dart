import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'dart:convert';

// Handler pour les notifications en background (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Notification en background: ${message.notification?.title}');
  
  // Sauvegarder la notification dans la base de données
  try {
    final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final data = message.data;
    final timestamp = DateTime.now();
    final notificationId = '${timestamp.millisecondsSinceEpoch}_${message.hashCode}';
    
    // Déterminer l'expéditeur
    String? sender;
    if (data.containsKey('sender')) {
      sender = data['sender'] as String?;
    } else if (data.containsKey('type')) {
      final type = data['type'] as String?;
      if (type != null) {
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
    
    // Récupérer l'utilisateur actuel
    final authService = AuthService.instance;
    final user = authService.getCurrentUser();
    final parentId = user?.id;
    
    // Sauvegarder la notification
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
    print('✅ Notification sauvegardée en background: $title');
  } catch (e) {
    print('❌ Erreur lors de la sauvegarde de la notification en background: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Configurer le handler pour les notifications en background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialiser le service de notifications SEULEMENT après Firebase
    await NotificationService().initialize();
    print('✅ Service de notifications initialisé');
  } catch (e) {
    print('⚠️ Erreur lors de l\'initialisation de Firebase: $e');
    // Continuer même si Firebase échoue (pour le développement)
    // Ne pas initialiser NotificationService si Firebase échoue
  }
  
  runApp(const PoulsEcoleParentApp());
}

/// Application principale
class PoulsEcoleParentApp extends StatefulWidget {
  const PoulsEcoleParentApp({super.key});

  @override
  State<PoulsEcoleParentApp> createState() => _PoulsEcoleParentAppState();
}

class _PoulsEcoleParentAppState extends State<PoulsEcoleParentApp> {
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Pouls École Parent',
          debugShowCheckedModeBanner: false,
          theme: _themeService.lightTheme,
          darkTheme: _themeService.darkTheme,
          themeMode: _themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}

