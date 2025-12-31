class AppConstants {
  static const String appName = 'Okoukro Fondation';
  static const String appVersion = '1.0.0';
  
  // Couleurs principales
  static const int primaryColorValue = 0xFF1976D2;
  static const int secondaryColorValue = 0xFF32CD32;
  static const int accentColorValue = 0xFFFF6B35;
  
  // Devise
  static const String devise = 'FCFA';
  static const String symboleDevise = 'FCFA';
  
  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Limites
  static const int minMontantCotisation = 1000;
  static const int maxMontantCotisation = 10000000;
  static const int maxAdherents = 1000;
  
  // Messages
  static const String succesMessage = 'Opération réussie';
  static const String errorMessage = 'Une erreur est survenue';
  static const String confirmationMessage = 'Êtes-vous sûr?';
  
  // Notifications
  static const String channelId = 'okoukro_fondation';
  static const String channelName = 'Notifications Okoukro Fondation';
  static const String channelDescription = 'Rappels de cotisations et autres notifications';
}

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String adherents = '/adherents';
  static const String cotisations = '/cotisations';
  static const String paiements = '/paiements';
  static const String benefices = '/benefices';
  static const String rapports = '/rapports';
  static const String settings = '/settings';
}

class AppStrings {
  // Général
  static const String oui = 'Oui';
  static const String non = 'Non';
  static const String annuler = 'Annuler';
  static const String confirmer = 'Confirmer';
  static const String enregistrer = 'Enregistrer';
  static const String modifier = 'Modifier';
  static const String supprimer = 'Supprimer';
  static const String ajouter = 'Ajouter';
  static const String rechercher = 'Rechercher';
  static const String filtrer = 'Filtrer';
  static const String exporter = 'Exporter';
  static const String importer = 'Importer';
  static const String rafraichir = 'Rafraîchir';
  
  // Navigation
  static const String tableauBord = 'Tableau de bord';
  static const String adherents = 'Adhérents';
  static const String cotisations = 'Cotisations';
  static const String paiements = 'Paiements';
  static const String benefices = 'Bénéfices';
  static const String rapports = 'Rapports';
  static const String parametres = 'Paramètres';
  
  // Adhérents
  static const String nom = 'Nom';
  static const String prenom = 'Prénom';
  static const String telephone = 'Téléphone';
  static const String email = 'Email';
  static const String adresse = 'Adresse';
  static const String dateAdhesion = 'Date d\'adhésion';
  static const String photo = 'Photo';
  static const String nouvelAdherent = 'Nouvel adhérent';
  static const String modifierAdherent = 'Modifier l\'adhérent';
  static const String supprimerAdherent = 'Supprimer l\'adhérent';
  
  // Cotisations
  static const String montantAnnuel = 'Montant annuel';
  static const String annee = 'Année';
  static const String nouvelleCotisation = 'Nouvelle cotisation';
  static const String modifierCotisation = 'Modifier la cotisation';
  static const String augmenterCotisation = 'Augmenter la cotisation';
  static const String motifModification = 'Motif de modification';
  
  // Paiements
  static const String montantVerse = 'Montant versé';
  static const String datePaiement = 'Date de paiement';
  static const String statut = 'Statut';
  static const String methode = 'Méthode';
  static const String reference = 'Référence';
  static const String notes = 'Notes';
  static const String nouveauPaiement = 'Nouveau paiement';
  static const String modifierPaiement = 'Modifier le paiement';
  
  // Bénéfices
  static const String montantTotal = 'Montant total';
  static const String dateDistribution = 'Date de distribution';
  static const String description = 'Description';
  static const String nouveauBenefice = 'Nouveau bénéfice';
  static const String distribuerBenefice = 'Distribuer le bénéfice';
  static const String partBenefice = 'Part du bénéfice';
  static const String pourcentage = 'Pourcentage';
  
  // Statuts et méthodes
  static const String statutEnAttente = 'En attente';
  static const String statutComplet = 'Complet';
  static const String statutPartiel = 'Partiel';
  static const String statutRetard = 'Retard';
  
  static const String methodeEspece = 'Espèce';
  static const String methodeMobileMoney = 'Mobile Money';
  static const String methodeVirement = 'Virement';
  static const String methodeCheque = 'Chèque';
  
  // Messages
  static const String adherentAjoute = 'Adhérent ajouté avec succès';
  static const String adherentModifie = 'Adhérent modifié avec succès';
  static const String adherentSupprime = 'Adhérent supprimé avec succès';
  static const String cotisationAjoutee = 'Cotisation ajoutée avec succès';
  static const String cotisationModifiee = 'Cotisation modifiée avec succès';
  static const String paiementAjoute = 'Paiement ajouté avec succès';
  static const String paiementModifie = 'Paiement modifié avec succès';
  static const String beneficeAjoute = 'Bénéfice ajouté avec succès';
  static const String beneficeDistribue = 'Bénéfice distribué avec succès';
  
  static const String confirmationSuppression = 'Êtes-vous sûr de vouloir supprimer cet élément?';
  static const String champObligatoire = 'Ce champ est obligatoire';
  static const String formatInvalide = 'Format invalide';
  static const String montantInvalide = 'Montant invalide';
  static const String telephoneInvalide = 'Numéro de téléphone invalide';
  static const String emailInvalide = 'Adresse email invalide';
}
