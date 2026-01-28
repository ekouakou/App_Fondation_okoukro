import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'fr';
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _themeService.loadTheme();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _darkModeEnabled = _themeService.isDarkMode;
      _language = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('language', _language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildGeneralSection(),
          SizedBox(height: 24),
          _buildAccountSection(),
          SizedBox(height: 24),
          _buildDataSection(),
          SizedBox(height: 24),
          _buildNotificationsSection(),
          SizedBox(height: 24),
          _buildAppearanceSection(),
          SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Général',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Langue'),
                subtitle: Text(_language == 'fr' ? 'Français' : 'English'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showLanguageDialog,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Informations de l\'association'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showAssociationInfo,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    final authService = context.read<AuthService>();
    final user = authService.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compte',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Informations du compte'),
                subtitle: Text(user?.email ?? 'Utilisateur anonyme'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showAccountInfo,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Déconnexion'),
                subtitle: Text('Se déconnecter de l\'application'),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des données',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Exporter les données'),
                subtitle: Text('Exporter toutes les données au format CSV'),
                onTap: _exportData,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.download),
                title: Text('Importer les données'),
                subtitle: Text('Importer des données depuis un fichier CSV'),
                onTap: _importData,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.backup),
                title: Text('Sauvegarder la base de données'),
                subtitle: Text('Créer une sauvegarde complète'),
                onTap: _backupDatabase,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.restore),
                title: Text('Restaurer la base de données'),
                subtitle: Text('Restaurer depuis une sauvegarde'),
                onTap: _restoreDatabase,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete_sweep, color: Colors.red),
                title: Text('Effacer toutes les données'),
                subtitle: Text('Supprimer définitivement toutes les données'),
                onTap: _clearAllData,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _saveSettings();
                },
                title: Text('Activer les notifications'),
                subtitle: Text('Recevoir des rappels de cotisations'),
                secondary: Icon(Icons.notifications),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Paramètres des rappels'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showReminderSettings,
                enabled: _notificationsEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apparence',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _darkModeEnabled,
                onChanged: (value) async {
                  await _themeService.setTheme(value);
                  setState(() {
                    _darkModeEnabled = value;
                  });
                },
                title: Text('Mode sombre'),
                subtitle: Text('Activer le thème sombre'),
                secondary: Icon(Icons.dark_mode),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Thème de couleurs'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showThemeSelector,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À propos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.info),
                title: Text('Version de l\'application'),
                subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Aide et support'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showHelp,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.privacy_tip),
                title: Text('Politique de confidentialité'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showPrivacyPolicy,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.description),
                title: Text('Conditions d\'utilisation'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: _showTermsOfService,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Français'),
              value: 'fr',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssociationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations de l\'association'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Nom de l\'association'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Adresse'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Téléphone'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Informations enregistrées')),
              );
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Implémentation simplifiée sans file_picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportation des données - Fonctionnalité à implémenter')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }

  Future<void> _importData() async {
    try {
      // Implémentation simplifiée sans file_picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importation des données - Fonctionnalité à implémenter')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'import: $e')),
      );
    }
  }

  Future<void> _backupDatabase() async {
    try {
      // Implémentation simplifiée sans file_picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sauvegarde de la base de données - Fonctionnalité à implémenter')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  Future<void> _restoreDatabase() async {
    try {
      // Implémentation simplifiée sans file_picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restauration de la base de données - Fonctionnalité à implémenter')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la restauration: $e')),
      );
    }
  }

  void _showAccountInfo() {
    final authService = context.read<AuthService>();
    final user = authService.user;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informations du compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? "Non disponible"}'),
            SizedBox(height: 8),
            Text('ID: ${user?.uid ?? "Non disponible"}'),
            SizedBox(height: 8),
            Text('Email vérifié: ${user?.emailVerified == true ? "Oui" : "Non"}'),
            if (user?.emailVerified == false) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final success = await authService.sendEmailVerification();
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email de vérification envoyé!')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Envoyer l\'email de vérification'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthService>().signOut();
            },
            child: Text('Se déconnecter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Effacer toutes les données'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer toutes les données? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Toutes les données ont été effacées')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReminderSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paramètres des rappels'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fréquence des rappels'),
            SizedBox(height: 16),
            RadioListTile<String>(
              title: Text('Quotidien'),
              value: 'daily',
              groupValue: 'weekly',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: Text('Hebdomadaire'),
              value: 'weekly',
              groupValue: 'weekly',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: Text('Mensuel'),
              value: 'monthly',
              groupValue: 'weekly',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choisir un thème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Thèmes disponibles à implémenter'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aide et support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pour obtenir de l\'aide:'),
            SizedBox(height: 16),
            Text('Email: support@okoukro.com'),
            Text('Téléphone: +225 00 00 00 00'),
            SizedBox(height: 16),
            Text('Horaires: Lundi-Vendredi 8h-18h'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Politique de confidentialité'),
        content: SingleChildScrollView(
          child: Text(
            'Politique de confidentialité à implémenter...\n\n'
            'Cette application respecte votre vie privée et ne collecte que les données nécessaires '
            'au bon fonctionnement de la gestion des cotisations associatives.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conditions d\'utilisation'),
        content: SingleChildScrollView(
          child: Text(
            'Conditions d\'utilisation à implémenter...\n\n'
            'En utilisant cette application, vous acceptez les termes et conditions '
            'gouvernant l\'utilisation du logiciel de gestion des cotisations.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
