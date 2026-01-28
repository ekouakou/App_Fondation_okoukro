import 'dart:async';
import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'bottom_sheet_menu.dart';
import '../screens/home_screen.dart';
import '../screens/messages_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../services/api_service.dart';
import '../services/mock_api_service.dart';
import '../services/remote_api_service.dart';

/// Wrapper principal qui contient le BottomNav et gère la navigation
class MainScreenWrapper extends StatefulWidget {
  final Widget child;
  
  const MainScreenWrapper({super.key, required this.child});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();

  /// Récupère l'instance de MainScreenWrapper depuis le contexte
  static _MainScreenWrapperState of(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenWrapperState>()!;
  }

  /// Récupère l'instance de MainScreenWrapper depuis le contexte (peut retourner null)
  static _MainScreenWrapperState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_MainScreenWrapperState>();
  }
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int _currentIndex = 0;
  late ApiService _apiService;
  String? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _apiService = AppConfig.MOCK_MODE ? MockApiService() : RemoteApiService();
    final user = AuthService.instance.getCurrentUser();
    _currentUserId = user?.id;
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    try {
      _notificationSubscription = NotificationService().notificationStream.listen(
        (notificationData) => _handleNotification(notificationData),
      );
    } catch (e) {
      print('⚠️ NotificationService non disponible: $e');
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.getSurfaceColor(isDark),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
              Text(
                body,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Fermer',
            textColor: AppColors.primary,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  ApiService get apiService => _apiService;
  String? get currentUserId => _currentUserId;

  /// Met à jour l'utilisateur actuel (utile après reconnexion)
  void refreshCurrentUser() {
    final user = AuthService.instance.getCurrentUser();
    _currentUserId = user?.id;
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      showMenuBottomSheet(context);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0: return const HomeScreen();
      case 1: return const MessagesScreen();
      case 2: return const NotesPlaceholderScreen();
      default: return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child is MainScreenChild ? widget.child : _getCurrentScreen(),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// Interface pour les écrans qui peuvent être affichés dans le MainScreenWrapper
abstract class MainScreenChild {
  const MainScreenChild();
}

/// Écran placeholder pour les notes
class NotesPlaceholderScreen extends StatelessWidget implements MainScreenChild {
  const NotesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notes',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
          ),
        ),
        backgroundColor: AppColors.getSurfaceColor(isDark),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade, 
              size: 64, 
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un enfant depuis l\'écran d\'accueil',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
