import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';

class CalculService {
  
  /// Calcule le total des cotisations pour un adhérent sur une période donnée
  static int calculerTotalCotisationsAdherent(
    List<Cotisation> cotisations,
    String adherentId,
    int anneeDebut,
    int anneeFin,
  ) {
    return cotisations
        .where((c) => c.adherentId == adherentId && c.annee >= anneeDebut && c.annee <= anneeFin)
        .fold(0, (sum, cotisation) => sum + cotisation.montantAnnuel);
  }

  /// Calcule le total des cotisations pour tous les adhérents sur une période
  static Map<String, int> calculerTotauxCotisationsTousAdherents(
    List<Cotisation> cotisations,
    List<Adherent> adherents,
    int anneeDebut,
    int anneeFin,
  ) {
    Map<String, int> totaux = {};
    
    for (var adherent in adherents) {
      totaux[adherent.id] = calculerTotalCotisationsAdherent(
        cotisations,
        adherent.id,
        anneeDebut,
        anneeFin,
      );
    }
    
    return totaux;
  }

  /// Calcule le total général des cotisations de l'association
  static int calculerTotalGeneralCotisations(
    List<Cotisation> cotisations,
    int anneeDebut,
    int anneeFin,
  ) {
    return cotisations
        .where((c) => c.annee >= anneeDebut && c.annee <= anneeFin)
        .fold(0, (sum, cotisation) => sum + cotisation.montantAnnuel);
  }

  /// Calcule les parts de bénéfices pour chaque adhérent
  static List<PartBenefice> calculerPartsBenefices(
    List<Adherent> adherents,
    List<Cotisation> cotisations,
    Benefice benefice,
    int anneeDebut,
    int anneeFin,
  ) {
    Map<String, int> totauxAdherents = calculerTotauxCotisationsTousAdherents(
      cotisations,
      adherents,
      anneeDebut,
      anneeFin,
    );
    
    int totalGeneral = calculerTotalGeneralCotisations(
      cotisations,
      anneeDebut,
      anneeFin,
    );
    
    if (totalGeneral == 0) return [];
    
    List<PartBenefice> parts = [];
    
    for (var adherent in adherents) {
      int totalAdherent = totauxAdherents[adherent.id] ?? 0;
      
      if (totalAdherent > 0) {
        double pourcentage = (totalAdherent / totalGeneral) * 100;
        int montantPart = ((totalAdherent / totalGeneral) * benefice.montantTotal).round();
        
        parts.add(PartBenefice(
          adherentId: adherent.id,
          beneficeId: benefice.id,
          montantPart: montantPart,
          pourcentage: pourcentage,
          totalCotisationsAdherent: totalAdherent,
        ));
      }
    }
    
    return parts;
  }

  /// Vérifie si un adhérent est à jour dans ses paiements pour une année
  static bool verifierPaiementAdherentAnnee(
    List<Paiement> paiements,
    List<Cotisation> cotisations,
    String adherentId,
    int annee,
  ) {
    // Récupérer la cotisation de l'adhérent pour cette année
    var cotisation = cotisations.firstWhere(
      (c) => c.adherentId == adherentId && c.annee == annee,
      orElse: () => Cotisation(adherentId: adherentId, montantAnnuel: 0, annee: annee),
    );
    
    if (cotisation.montantAnnuel == 0) return true;
    
    // Calculer le total payé pour cette année
    int totalPaye = paiements
        .where((p) => p.adherentId == adherentId && p.annee == annee)
        .fold(0, (sum, paiement) => sum + paiement.montantVerse);
    
    return totalPaye >= cotisation.montantAnnuel;
  }

  /// Calcule le montant restant à payer pour un adhérent
  static int calculerRestantAPayer(
    List<Paiement> paiements,
    List<Cotisation> cotisations,
    String adherentId,
    int annee,
  ) {
    var cotisation = cotisations.firstWhere(
      (c) => c.adherentId == adherentId && c.annee == annee,
      orElse: () => Cotisation(adherentId: adherentId, montantAnnuel: 0, annee: annee),
    );
    
    int totalPaye = paiements
        .where((p) => p.adherentId == adherentId && p.annee == annee)
        .fold(0, (sum, paiement) => sum + paiement.montantVerse);
    
    return (cotisation.montantAnnuel - totalPaye).clamp(0, cotisation.montantAnnuel);
  }

  /// Génère les statistiques de l'association
  static Map<String, dynamic> genererStatistiques(
    List<Adherent> adherents,
    List<Cotisation> cotisations,
    List<Paiement> paiements,
    int annee,
  ) {
    int nombreAdherents = adherents.where((a) => a.estActif).length;
    
    int totalCotisationsAnnee = cotisations
        .where((c) => c.annee == annee)
        .fold(0, (sum, c) => sum + c.montantAnnuel);
    
    int totalPayementsAnnee = paiements
        .where((p) => p.annee == annee)
        .fold(0, (sum, p) => sum + p.montantVerse);
    
    int adherentsAJour = 0;
    int adherentsRetard = 0;
    
    for (var adherent in adherents.where((a) => a.estActif)) {
      if (verifierPaiementAdherentAnnee(paiements, cotisations, adherent.id, annee)) {
        adherentsAJour++;
      } else {
        adherentsRetard++;
      }
    }
    
    double tauxRecouvrement = totalCotisationsAnnee > 0 
        ? (totalPayementsAnnee / totalCotisationsAnnee) * 100 
        : 0.0;
    
    return {
      'nombreAdherents': nombreAdherents,
      'totalCotisationsAnnee': totalCotisationsAnnee,
      'totalPayementsAnnee': totalPayementsAnnee,
      'adherentsAJour': adherentsAJour,
      'adherentsRetard': adherentsRetard,
      'tauxRecouvrement': tauxRecouvrement,
      'montantRestant': totalCotisationsAnnee - totalPayementsAnnee,
    };
  }

  /// Calcule l'évolution des cotisations sur plusieurs années
  static Map<int, int> calculerEvolutionCotisations(
    List<Cotisation> cotisations,
    int anneeDebut,
    int anneeFin,
  ) {
    Map<int, int> evolution = {};
    
    for (int annee = anneeDebut; annee <= anneeFin; annee++) {
      evolution[annee] = cotisations
          .where((c) => c.annee == annee)
          .fold(0, (sum, c) => sum + c.montantAnnuel);
    }
    
    return evolution;
  }
}
