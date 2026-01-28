/// Configuration de l'application
/// 
/// MOCK_MODE : Active le mode mock (données statiques)
/// Quand MOCK_MODE = false, l'application utilisera RemoteApiService
/// pour consommer les vraies API REST (Quarkus)
class AppConfig {
  // TODO: Passer à false en production pour utiliser les vraies API
  static const bool MOCK_MODE = true;
  
  // URL de base de l'API Pouls Scolaire
  // IMPORTANT : Pour accéder à localhost depuis un émulateur/appareil :
  // - Émulateur Android : utilisez 'http://10.0.2.2:8889/api' (10.0.2.2 = localhost de la machine hôte)
  // - Appareil Android physique : utilisez l'IP locale de votre machine (ex: 'http://192.168.1.100:8889/api')
  // - Chrome/Windows Desktop : utilisez 'http://localhost:8889/api'
  // - iOS Simulator : utilisez 'http://localhost:8889/api'
  // - iOS Appareil physique : utilisez l'IP locale de votre machine (ex: 'http://192.168.1.100:8889/api')
  //
  // Pour trouver votre IP locale sur Windows :
  //   ipconfig (cherchez "Adresse IPv4" de votre carte réseau)
  // Pour trouver votre IP locale sur Mac/Linux :
  //   ifconfig ou ip addr (cherchez "inet" de votre carte réseau)
  //
  // Production :
  //static const String API_BASE_URL = 'https://api-pro.pouls-scolaire.net/api';
  
  // Configuration pour développement local (émulateur Android)
  static const String API_BASE_URL = 'http://10.0.2.2:8889/api';
  
  // Pour Chrome/Windows Desktop, décommentez cette ligne et commentez celle du dessus :
  //static const String API_BASE_URL = 'http://localhost:8889/api';
  
  // URL alternative pour le service Pouls Scolaire (utilisée par PoulsScolaireApiService)
  // Cette URL est utilisée pour les endpoints spécifiques à Pouls Scolaire
  static const String POULS_SCOLAIRE_API_URL = 'https://api-pro.pouls-scolaire.net/api';
  //static const String POULS_SCOLAIRE_API_URL = 'http://10.0.2.2:8889/api';
  
  // Pour Chrome/Windows Desktop, décommentez cette ligne et commentez celle du dessus :
  //static const String POULS_SCOLAIRE_API_URL = 'http://localhost:8889/api';
  // TODO: Configurer le timeout des requêtes HTTP
  static const Duration API_TIMEOUT = Duration(seconds: 30);
}

