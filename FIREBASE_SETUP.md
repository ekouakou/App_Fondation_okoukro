# Configuration Firebase pour OKOUKRO_FONDATION

Ce document décrit l'implémentation de Firebase comme base de données pour l'application de gestion de cotisations.

## Étapes d'installation

### 1. Configuration du projet Firebase

1. Créez un nouveau projet sur la [Console Firebase](https://console.firebase.google.com/)
2. Activez les services suivants :
   - Firestore Database
   - Authentication (optionnel)
3. Configurez les règles de sécurité Firestore pour permettre l'accès aux données

### 2. Configuration Android

1. Téléchargez le fichier `google-services.json` depuis la console Firebase
2. Placez-le dans le dossier `android/app/`
3. Les configurations Gradle ont déjà été ajoutées dans :
   - `android/build.gradle.kts`
   - `android/app/build.gradle.kts`

### 3. Configuration iOS

1. Téléchargez le fichier `GoogleService-Info.plist` depuis la console Firebase
2. Placez-le dans le dossier `ios/Runner/`
3. Ajoutez-le au projet Xcode dans le target Runner
4. Installez CocoaPods si nécessaire :
   ```bash
   cd ios
   pod install
   ```

## Configuration spécifique au projet

### Informations du projet Firebase
- **ID du projet**: `fondation-okoukro-app`
- **Numéro de projet**: `833147631416`
- **ID d'application Android**: `dev.ekdev.fondation_okoukro_app`
- **ID d'application iOS**: `dev.ekdev.fondation_okoukro_app`
- **Package Android**: `dev.ekdev.fondation_okoukro_app`
- **Bundle iOS**: `dev.ekdev.fondation_okoukro_app`

### Fichiers de configuration déjà créés
- `android/app/google-services.json` ✅
- `ios/Runner/GoogleService-Info.plist` ✅
- `lib/firebase_options.dart` ✅ (configuré pour toutes les plateformes)

### Configuration Gradle
Les fichiers Gradle ont été mis à jour avec :
- **Firebase BOM v34.7.0** pour la gestion des versions
- **SDK Firebase** : Analytics, Firestore, Auth
- **Plugin google-services** v4.4.4
- **Application ID** mis à jour vers `dev.ekdev.fondation_okoukro_app`

L'application utilise maintenant le fichier `firebase_options.dart` pour la configuration. Pour générer ce fichier automatiquement :

1. Installez FlutterFire CLI :
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Configurez votre projet :
   ```bash
   flutterfire configure
   ```

3. Ou mettez à jour manuellement le fichier `lib/firebase_options.dart` avec vos clés Firebase :
   - Remplacez `your-project-id` par votre ID de projet
   - Remplacez `your-web-api-key` par votre clé API web
   - Remplacez `your-android-app-id` par votre ID d'application Android
   - Remplacez `your-ios-app-id` par votre ID d'application iOS
   - Remplacez `your-sender-id` par votre ID d'expéditeur

## Structure des données

### Collections Firestore

L'application utilise les collections suivantes :

- `adherents` : Informations sur les adhérents
- `cotisations` : Cotisations annuelles par adhérent
- `paiements` : Paiements effectués par les adhérents
- `benefices` : Bénéfices distribués aux adhérents
- `benefices/{beneficeId}/parts` : Parts de bénéfices par adhérent (sous-collection)

### Schéma des documents

#### Adherents
```json
{
  "nom": "Nom",
  "prenom": "Prénom",
  "telephone": "123456789",
  "email": "email@example.com",
  "adresse": "Adresse",
  "dateAdhesion": timestamp,
  "estActif": true,
  "photoUrl": ""
}
```

#### Cotisations
```json
{
  "adherentId": "ID_adherent",
  "montantAnnuel": 12000,
  "annee": 2024,
  "dateModification": timestamp,
  "motifModification": "Raison de la modification"
}
```

#### Paiements
```json
{
  "adherentId": "ID_adherent",
  "annee": 2024,
  "montantVerse": 6000,
  "datePaiement": timestamp,
  "statut": "complete",
  "methode": "espece",
  "referenceTransaction": "",
  "notes": ""
}
```

#### Benefices
```json
{
  "annee": 2024,
  "montantTotal": 500000,
  "dateDistribution": timestamp,
  "description": "Description du bénéfice",
  "estDistribue": false
}
```

#### Parts de bénéfices (sous-collection)
```json
{
  "adherentId": "ID_adherent",
  "beneficeId": "ID_benefice",
  "montantPart": 25000,
  "pourcentage": 5.0,
  "totalCotisationsAdherent": 12000
}
```

## Services implémentés

### FirebaseService
Classe principale qui gère toutes les opérations Firestore :

- CRUD pour toutes les entités
- Requêtes par filtre (adhérent, année, etc.)
- Streams pour les mises à jour en temps réel
- Gestion des sous-collections pour les parts de bénéfices
- Gestion des erreurs

### Initialisation Firebase
L'initialisation est maintenant gérée dans `main.dart` avec `firebase_options.dart` :

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Modèles mis à jour
Tous les modèles ont été enrichis avec :
- `toFirebaseMap()` : Conversion pour Firestore
- `fromFirebaseMap()` : Création depuis Firestore
- Gestion des timestamps Firebase

### Providers mis à jour
Tous les providers utilisent maintenant `FirebaseService` au lieu de `DatabaseService`.

## Migration depuis SQLite

L'application conserve la compatibilité avec SQLite pendant la transition. Pour migrer complètement vers Firebase :

1. Exportez les données existantes depuis SQLite
2. Importez-les dans Firestore
3. Configurez les options Firebase dans `firebase_options.dart`
4. Supprimez les dépendances SQLite de `pubspec.yaml`
5. Supprimez `services/database_service.dart`

## Règles de sécurité Firestore

Pour le développement, utilisez ces règles permissives :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

Pour la production, configurez des règles plus strictes selon vos besoins.

## Dépannage

### Erreurs courantes

1. **"Missing plugin"** : Assurez-vous d'avoir exécuté `flutter pub get`
2. **"Firebase not initialized"** : Vérifiez que `Firebase.initializeApp()` est appelé dans `main.dart`
3. **iOS build failed** : Installez CocoaPods et exécutez `pod install` dans le dossier iOS
4. **Permission denied** : Vérifiez les règles de sécurité Firestore
5. **Invalid API key** : Vérifiez les clés dans `firebase_options.dart`

### Logs de débogage

Activez les logs Firebase pour le débogage :

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Prochaines étapes

1. Configurer l'authentification Firebase
2. Implémenter la synchronisation hors ligne
3. Ajouter des indexes Firestore pour optimiser les performances
4. Configurer les notifications push via Firebase Cloud Messaging
5. Mettre en place des règles de sécurité plus strictes pour la production
