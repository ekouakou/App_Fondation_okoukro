import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'screens/dashboard_screen.dart';
import 'screens/adherents_screen.dart';
import 'screens/cotisations_screen.dart';
import 'screens/paiements_screen.dart';
import 'screens/liste_paiements_screen.dart';
import 'screens/benefices_screen.dart';
import 'screens/rapports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'config/app_theme.dart';
import 'utils/constants.dart';
import 'firebase_options.dart';

// Provider pour ThemeService
final themeServiceProvider = ChangeNotifierProvider((ref) => ThemeService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialiser Firebase avec les options spécifiques à la plateforme
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialisé avec succès pour ${defaultTargetPlatform.name}');
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
    print('L\'application continuera sans Firebase pour ${defaultTargetPlatform.name}');
  }

  // Forcer le mode portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeService = ref.watch(themeServiceProvider);
    
    // Charger le thème au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      themeService.loadTheme();
    });
    
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      home: Builder(
        builder: (context) {
          final authService = context.watch<AuthService>();
          // Afficher l'écran d'authentification si l'utilisateur n'est pas connecté
          if (!authService.isAuthenticated) {
            return const AuthScreen();
          }
          // Sinon afficher l'application principale
          return MainScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    DashboardScreen(),
    AdherentsScreen(),
    CotisationsScreen(),
    PaiementsScreen(),
    ListePaiementsScreen(),
    BeneficesScreen(),
    RapportsScreen(),
    SettingsScreen(),
  ];

  final List<Map<String, dynamic>> _drawerItems = [
    {
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard,
      'label': 'Tableau de bord',
    },
    {
      'icon': Icons.people_outline,
      'selectedIcon': Icons.people,
      'label': 'Adhérents',
    },
    {
      'icon': Icons.account_balance_outlined,
      'selectedIcon': Icons.account_balance,
      'label': 'Cotisations',
    },
    {
      'icon': Icons.payment_outlined,
      'selectedIcon': Icons.payment,
      'label': 'Nouveau Paiement',
    },
    {
      'icon': Icons.history_outlined,
      'selectedIcon': Icons.history,
      'label': 'Historique',
    },
    {
      'icon': Icons.trending_up_outlined,
      'selectedIcon': Icons.trending_up,
      'label': 'Bénéfices',
    },
    {
      'icon': Icons.bar_chart_outlined,
      'selectedIcon': Icons.bar_chart,
      'label': 'Rapports',
    },
    {
      'icon': Icons.settings,
      'selectedIcon': Icons.settings,
      'label': 'Paramètres',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Charger les données initiales si nécessaire
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Gestion de cotisations',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_drawerItems.length, (index) {
              final item = _drawerItems[index];
              final isSelected = _selectedIndex == index;
              return ListTile(
                leading: Icon(
                  isSelected ? item['selectedIcon'] : item['icon'],
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  item['label'],
                  style: TextStyle(
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tableau de bord';
      case 1:
        return 'Adhérents';
      case 2:
        return 'Cotisations';
      case 3:
        return 'Nouveau Paiement';
      case 4:
        return 'Historique des Paiements';
      case 5:
        return 'Bénéfices';
      case 6:
        return 'Rapports';
      case 7:
        return 'Paramètres';
      default:
        return '';
    }
  }
}
