# Déploiement des règles de sécurité Firebase

## Problème
L'erreur `cloud_firestore/permission-denied` indique que les règles de sécurité Firebase ne permettent pas l'accès à la collection `rapports`.

## Solution
Le fichier `firestore.rules` a été créé avec les règles nécessaires pour autoriser l'accès à toutes les collections de l'application.

## Comment déployer les règles

### Méthode 1: Via la console Firebase
1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Dans le menu de gauche, allez dans "Firestore Database"
4. Cliquez sur l'onglet "Règles" (Rules)
5. Remplacez le contenu existant par le contenu du fichier `firestore.rules`
6. Cliquez sur "Publier" (Publish)

### Méthode 2: Via Firebase CLI
1. Installez Firebase CLI si ce n'est pas déjà fait:
   ```bash
   npm install -g firebase-tools
   ```

2. Connectez-vous à Firebase:
   ```bash
   firebase login
   ```

3. Initialisez Firebase dans votre projet (si ce n'est pas déjà fait):
   ```bash
   firebase init firestore
   ```

4. Déployez les règles:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Contenu des règles
Les règles autorisent les utilisateurs authentifiés à:
- Lire et écrire dans toutes les collections
- Créer, mettre à jour et supprimer des documents
- Lister et obtenir des documents

### Collections couvertes:
- `adherents` - Gestion des adhérents
- `cotisations` - Gestion des cotisations
- `paiements` - Gestion des paiements
- `benefices` - Gestion des bénéfices
- `rapports` - Gestion des rapports

## Sécurité
⚠️ **Important**: Ces règles autorisent tous les utilisateurs authentifiés à accéder à toutes les données. Pour une application en production, vous devriez implémenter des règles plus spécifiques basées sur les rôles utilisateurs et d'autres critères de sécurité.

## Test après déploiement
Après avoir déployé les règles, redémarrez votre application. L'erreur `permission-denied` devrait disparaître et vous devriez pouvoir:
- Voir la liste des rapports
- Générer de nouveaux rapports
- Éditer les rapports existants
- Filtrer et rechercher des rapports
