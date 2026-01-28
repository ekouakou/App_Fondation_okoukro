import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/help_support_screen.dart';

class NewSettingsScreen extends StatefulWidget {
  const NewSettingsScreen({super.key});

  @override
  State<NewSettingsScreen> createState() => _NewSettingsScreenState();
}

class _NewSettingsScreenState extends State<NewSettingsScreen> {
  final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.getCurrentUser();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.white.withOpacity(0.1)
                  : AppColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.getTextColor(isDark),
              size: 16,
            ),
          ),
        ),
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Profile Card
            _buildUserProfileCard(user, isDark),
            const SizedBox(height: 24),
            
            // Settings Categories
            _buildSettingsCategory(
              'Compte',
              [
                {
                  'title': 'Profil',
                  'subtitle': 'Informations personnelles et photo',
                  'icon': Icons.person_outline,
                  'color': const Color(0xFF2196F3),
                  'onTap': () => _navigateToProfile(),
                },
                {
                  'title': 'Sécurité',
                  'subtitle': 'Mot de passe et authentification',
                  'icon': Icons.security,
                  'color': const Color(0xFF4CAF50),
                  'onTap': () => _showSecuritySettings(),
                },
                {
                  'title': 'Confidentialité',
                  'subtitle': 'Gestion des données et permissions',
                  'icon': Icons.privacy_tip_outlined,
                  'color': const Color(0xFF9C27B0),
                  'onTap': () => _showPrivacySettings(),
                },
              ],
              isDark,
            ),
            const SizedBox(height: 24),
            
            _buildSettingsCategory(
              'Apparence',
              [
                {
                  'title': 'Thème',
                  'subtitle': isDark ? 'Mode sombre' : 'Mode clair',
                  'icon': isDark ? Icons.dark_mode : Icons.light_mode,
                  'color': const Color(0xFFFF9800),
                  'onTap': () => _themeService.toggleTheme(),
                  'toggle': true,
                  'toggleValue': isDark,
                },
                {
                  'title': 'Langue',
                  'subtitle': 'Français',
                  'icon': Icons.language,
                  'color': const Color(0xFF00BCD4),
                  'onTap': () => _showLanguageSettings(),
                },
                {
                  'title': 'Taille du texte',
                  'subtitle': 'Moyenne',
                  'icon': Icons.text_fields,
                  'color': const Color(0xFF607D8B),
                  'onTap': () => _showTextSizeSettings(),
                },
              ],
              isDark,
            ),
            const SizedBox(height: 24),
            
            _buildSettingsCategory(
              'Notifications',
              [
                {
                  'title': 'Notifications push',
                  'subtitle': 'Alertes en temps réel',
                  'icon': Icons.notifications_outlined,
                  'color': const Color(0xFFF44336),
                  'onTap': () => _togglePushNotifications(),
                  'toggle': true,
                  'toggleValue': true,
                },
                {
                  'title': 'Email',
                  'subtitle': 'Notifications par email',
                  'icon': Icons.email_outlined,
                  'color': const Color(0xFF2196F3),
                  'onTap': () => _toggleEmailNotifications(),
                  'toggle': true,
                  'toggleValue': false,
                },
                {
                  'title': 'SMS',
                  'subtitle': 'Alertes par SMS',
                  'icon': Icons.sms_outlined,
                  'color': const Color(0xFF4CAF50),
                  'onTap': () => _toggleSMSNotifications(),
                  'toggle': true,
                  'toggleValue': false,
                },
              ],
              isDark,
            ),
            const SizedBox(height: 24),
            
            _buildSettingsCategory(
              'Support',
              [
                {
                  'title': 'Aide & Support',
                  'subtitle': 'FAQ, contact et ressources',
                  'icon': Icons.help_outline,
                  'color': const Color(0xFF2196F3),
                  'onTap': () => _navigateToHelpSupport(),
                },
                {
                  'title': 'Signaler un problème',
                  'subtitle': 'Nous faire remonter un bug',
                  'icon': Icons.bug_report_outlined,
                  'color': const Color(0xFFFF9800),
                  'onTap': () => _reportIssue(),
                },
                {
                  'title': 'Suggestions',
                  'subtitle': 'Proposer des améliorations',
                  'icon': Icons.lightbulb_outline,
                  'color': const Color(0xFF9C27B0),
                  'onTap': () => _sendSuggestion(),
                },
              ],
              isDark,
            ),
            const SizedBox(height: 24),
            
            _buildSettingsCategory(
              'À propos',
              [
                {
                  'title': 'Version',
                  'subtitle': '1.0.0',
                  'icon': Icons.info_outline,
                  'color': const Color(0xFF607D8B),
                  'onTap': () => _showVersionInfo(),
                },
                {
                  'title': 'Conditions d\'utilisation',
                  'subtitle': 'Mentions légales et CGU',
                  'icon': Icons.description_outlined,
                  'color': const Color(0xFF795548),
                  'onTap': () => _showTermsOfService(),
                },
                {
                  'title': 'Politique de confidentialité',
                  'subtitle': 'Comment nous protégeons vos données',
                  'icon': Icons.shield_outlined,
                  'color': const Color(0xFF4CAF50),
                  'onTap': () => _showPrivacyPolicy(),
                },
              ],
              isDark,
            ),
            const SizedBox(height: 32),
            
            // Logout Button
            _buildLogoutButton(isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(dynamic user, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToProfile(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Voir le profil',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCategory(String title, List<Map<String, dynamic>> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorderColor(isDark),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? AppColors.black.withOpacity(0.2)
                    : AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return _buildSettingsItem(
                item['title'] as String,
                item['subtitle'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
                isDark,
                onTap: item['onTap'] as VoidCallback,
                showDivider: !isLast,
                toggle: item['toggle'] as bool? ?? false,
                toggleValue: item['toggleValue'] as bool? ?? false,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark, {
    required VoidCallback onTap,
    bool showDivider = true,
    bool toggle = false,
    bool toggleValue = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: toggle ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.toSurface(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextColor(isDark, type: TextType.secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Toggle or Arrow
                  if (toggle)
                    Switch(
                      value: toggleValue,
                      onChanged: (value) => onTap(),
                      activeColor: color,
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.getTextColor(isDark, type: TextType.secondary),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Divider(
              color: AppColors.getBorderColor(isDark),
              height: 1,
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.errorGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await AuthService.instance.logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Déconnexion',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _navigateToHelpSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
    );
  }

  // Settings Methods
  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres de sécurité bientôt disponibles!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _showPrivacySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres de confidentialité bientôt disponibles!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _showLanguageSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choix de langue bientôt disponible!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _showTextSizeSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Taille du texte bientôt configurable!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _togglePushNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications push activées!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _toggleEmailNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications par email configurées!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _toggleSMSNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications par SMS configurées!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _reportIssue() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulaire de signalement bientôt disponible!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _sendSuggestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulaire de suggestions bientôt disponible!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Version de l\'application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            const SizedBox(height: 8),
            Text('Build: 20240124'),
            const SizedBox(height: 8),
            Text('Mode: ${AppConfig.MOCK_MODE ? 'Développement' : 'Production'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conditions d\'utilisation bientôt disponibles!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Politique de confidentialité bientôt disponible!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }
}
