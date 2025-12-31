# Okoukro Fondation - Application de Gestion de Cotisations

Une application mobile moderne et complète pour la gestion des cotisations associatives, développée avec Flutter.

## 🎯 Objectif

Gérer les adhésions, les cotisations annuelles, les augmentations de contributions et le partage des bénéfices de façon transparente et automatique pour les associations en Afrique de l'Ouest.

## 📋 Fonctionnalités

### 🏗️ Architecture
- **Architecture MVC** avec séparation claire des responsabilités
- **State Management** avec Provider et Riverpod
- **Base de données locale** SQLite avec persistance des données
- **Navigation** avec Go Router pour une expérience fluide

### 👥 Gestion des Adhérents
- Création et modification des profils d'adhérents
- Suivi des statuts (actif/inactif)
- Recherche et filtrage avancés
- Gestion des photos de profil

### 💰 Gestion des Cotisations
- Définition des montants annuels par adhérent
- Augmentation des cotisations avec suivi des modifications
- Historique complet des changements
- Calcul automatique des totaux

### 💳 Gestion des Paiements
- Enregistrement des paiements avec statuts
- Support de multiples méthodes (Espèce, Mobile Money, Virement, Chèque)
- Suivi des paiements en retard
- Calcul des soldes restants

### 📊 Tableau de Bord
- Statistiques en temps réel
- Graphiques d'évolution des cotisations
- Vue d'ensemble des performances
- Alertes pour les paiements en retard

### 📈 Gestion des Bénéfices
- Enregistrement des bénéfices annuels
- Distribution automatique proportionnelle aux cotisations
- Suivi des distributions effectuées
- Calcul des parts individuelles

### 📑 Rapports et Export
- Génération de rapports détaillés
- Exportation en PDF et CSV
- Analyse par période
- Sauvegarde et restauration des données

### 🔔 Notifications
- Rappels de paiements
- Notifications de distribution
- Alertes personnalisables

## 🛠️ Technologies Utilisées

### Frontend (Flutter)
- **Flutter 3.10+** - Framework de développement multiplateforme
- **Dart 3.0+** - Langage de programmation
- **Material Design 3** - Interface moderne et intuitive
- **Google Fonts** - Typographie professionnelle

### State Management
- **Provider** - Gestion d'état simple et efficace
- **Riverpod** - State management avancé avec dependency injection

### Base de Données
- **SQLite** - Base de données locale robuste
- **sqflite** - Package Flutter pour SQLite

### Navigation
- **Go Router** - Navigation déclarative et routing

### Graphiques et Visualisation
- **fl_chart** - Graphiques interactifs et modernes

### Utilitaires
- **intl** - Internationalisation et formatage
- **pdf** - Génération de documents PDF
- **file_picker** - Sélection de fichiers
- **shared_preferences** - Stockage local des préférences
- **flutter_local_notifications** - Notifications locales

## 🏗️ Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/                   # Modèles de données
│   ├── adherent.dart         # Modèle Adhérent
│   ├── cotisation.dart       # Modèle Cotisation
│   ├── paiement.dart         # Modèle Paiement
│   └── benefice.dart        # Modèle Bénéfice
├── providers/                # State Management
│   ├── adherent_provider.dart
│   ├── cotisation_provider.dart
│   ├── paiement_provider.dart
│   └── benefice_provider.dart
├── services/                 # Services métier
│   ├── database_service.dart # Service base de données
│   └── calcul_service.dart   # Service de calculs
├── screens/                  # Écrans de l'application
│   ├── dashboard_screen.dart
│   ├── adherents_screen.dart
│   ├── cotisations_screen.dart
│   ├── paiements_screen.dart
│   ├── benefices_screen.dart
│   ├── rapports_screen.dart
│   └── settings_screen.dart
├── widgets/                  # Widgets réutilisables
│   ├── statistiques_card.dart
│   ├── chart_widget.dart
│   ├── loading_widget.dart
│   └── empty_state_widget.dart
└── utils/                    # Utilitaires
    ├── constants.dart        # Constantes de l'application
    └── theme.dart           # Thème et styles
```

## 📦 Installation

### Prérequis
- Flutter SDK 3.10 ou supérieur
- Dart SDK 3.0 ou supérieur
- Android Studio / VS Code
- Émulateur Android ou appareil physique

### Étapes d'installation

1. **Cloner le projet**
```bash
git clone https://github.com/votre-repo/okoukro-fondation.git
cd okoukro-fondation
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Vérifier la configuration**
```bash
flutter doctor
```

4. **Lancer l'application**
```bash
flutter run
```

## 🎨 Personnalisation

### Thème et Couleurs
Les couleurs et le thème peuvent être personnalisés dans `lib/utils/theme.dart`:

```dart
static const int primaryColorValue = 0xFF1976D2;  // Bleu principal
static const int secondaryColorValue = 0xFF32CD32; // Vert
static const int accentColorValue = 0xFFFF6B35;   // Orange
```

### Constantes
Les constantes de l'application sont définies dans `lib/utils/constants.dart`:

```dart
static const String appName = 'Okoukro Fondation';
static const String devise = 'FCFA';
static const int minMontantCotisation = 1000;
```

## 📱 Capture d'Écran

*(À ajouter lors de la finalisation)*

## 🔄 Workflow de Développement

### 1. Gestion des Adhérents
- Créer un adhérent avec ses informations de base
- Définir sa cotisation annuelle initiale
- Suivre son statut actif/inactif

### 2. Suivi des Cotisations
- Enregistrer les montants de cotisation par année
- Augmenter les cotisations quand nécessaire
- Visualiser l'historique des modifications

### 3. Gestion des Paiements
- Enregistrer chaque paiement avec sa méthode
- Mettre à jour les statuts automatiquement
- Calculer les soldes restants

### 4. Distribution des Bénéfices
- Définir le montant total des bénéfices
- Lancer la distribution automatique
- Consulter les parts de chaque adhérent

## 🧪 Tests

### Lancer les tests
```bash
flutter test
```

### Tests de couverture
```bash
flutter test --coverage
```

## 📦 Build pour la Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribuer

1. Fork le projet
2. Créer une branche de fonctionnalité (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -am 'Ajout d\'une nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créer une Pull Request

## 📝 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 📞 Support

Pour toute question ou support technique:
- Email: support@okoukro.com
- Téléphone: +225 00 00 00 00
- Documentation: [Wiki du projet](https://github.com/votre-repo/okoukro-fondation/wiki)

## 🗺️ Roadmap

### Version 1.1 (Prochaine)
- [ ] Synchronisation cloud
- [ ] Multi-associations
- [ ] Mode hors ligne avancé
- [ ] Notifications push

### Version 1.2
- [ ] Interface web d'administration
- [ ] API REST
- [ ] Analytics avancés
- [ ] Export Excel

### Version 2.0
- [ ] Application web progressive (PWA)
- [ ] Intégration paiement mobile
- [ ] Gestion des événements
- [ ] Module de communication

---

**Développé avec ❤️ pour les associations d'Afrique de l'Ouest**
