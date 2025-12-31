import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rapport.dart';
import '../models/cotisation.dart';
import '../models/benefice.dart';
import '../models/adherent.dart';
import '../services/firebase_service.dart';
import '../services/export_service.dart';

class RapportNotifier extends StateNotifier<AsyncValue<List<Rapport>>> {
  RapportNotifier() : super(const AsyncValue.loading());

  Future<void> loadRapports() async {
    try {
      state = const AsyncValue.loading();
      final rapports = await FirebaseService.getAllRapports();
      state = AsyncValue.data(rapports);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addRapport(Rapport rapport) async {
    try {
      await FirebaseService.insertRapport(rapport);
      await loadRapports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateRapport(Rapport rapport) async {
    try {
      await FirebaseService.updateRapport(rapport);
      await loadRapports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteRapport(String rapportId) async {
    try {
      await FirebaseService.deleteRapport(rapportId);
      await loadRapports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Rapport> genererRapportCotisations({
    required DateTime dateDebut,
    required DateTime dateFin,
    String? adherentId,
    String titre = 'Rapport des cotisations',
    String description = '',
    String generePar = '',
  }) async {
    try {
      // Récupérer les données nécessaires
      final cotisations = await FirebaseService.getAllCotisations();
      final adherents = await FirebaseService.getAllAdherents();

      // Filtrer les cotisations selon la période et l'adhérent
      List<Cotisation> cotisationsFiltrees = cotisations.where((cotisation) {
        final annee = cotisation.annee;
        final dateCotisation = DateTime(annee);
        
        bool estDansPeriode = (dateCotisation.isAfter(dateDebut.subtract(Duration(days: 1))) && 
                                dateCotisation.isBefore(dateFin.add(Duration(days: 1))));
        
        bool estAdherentCorrespond = adherentId == null || cotisation.adherentId == adherentId;
        
        return estDansPeriode && estAdherentCorrespond;
      }).toList();

      // Calculer les statistiques
      double totalCotisations = 0.0;
      int nombreCotisations = cotisationsFiltrees.length;
      List<Map<String, dynamic>> detailsCotisations = [];

      for (var cotisation in cotisationsFiltrees) {
        final adherent = adherents.firstWhere(
          (a) => a.id == cotisation.adherentId,
          orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
        );

        totalCotisations += cotisation.montantPaye;

        detailsCotisations.add({
          'adherentId': cotisation.adherentId,
          'adherentNom': adherent.nomComplet,
          'annee': cotisation.annee,
          'montantTotal': cotisation.montantAnnuel,
          'montantPaye': cotisation.montantPaye,
          'resteAPayer': cotisation.resteAPayer,
          'pourcentagePaye': cotisation.pourcentagePaye,
          'estSoldee': cotisation.estSoldee,
          'dateModification': cotisation.dateModification.toIso8601String(),
          'motifModification': cotisation.motifModification,
        });
      }

      // Créer le rapport
      final rapport = Rapport(
        titre: titre.isNotEmpty ? titre : 'Rapport des cotisations',
        type: TypeRapport.cotisations,
        periode: _determinerPeriode(dateDebut, dateFin),
        dateDebut: dateDebut,
        dateFin: dateFin,
        adherentId: adherentId,
        description: description.isNotEmpty ? description : 'Rapport généré automatiquement',
        generePar: generePar,
        donnees: {
          'totalCotisations': totalCotisations,
          'nombreCotisations': nombreCotisations,
          'nombreAdherents': adherentId != null ? 1 : detailsCotisations.map((d) => d['adherentId']).toSet().length,
          'detailsCotisations': detailsCotisations,
        },
      );

      await addRapport(rapport);
      return rapport;
    } catch (error) {
      throw Exception('Erreur lors de la génération du rapport: $error');
    }
  }

  Future<Rapport> genererRapportBenefices({
    required DateTime dateDebut,
    required DateTime dateFin,
    String titre = 'Rapport des bénéfices',
    String description = '',
    String generePar = '',
  }) async {
    try {
      // Récupérer les données
      final benefices = await FirebaseService.getAllBenefices();

      // Filtrer les bénéfices selon la période
      List<Benefice> beneficesFiltres = benefices.where((benefice) {
        return benefice.dateDistribution.isAfter(dateDebut.subtract(Duration(days: 1))) && 
               benefice.dateDistribution.isBefore(dateFin.add(Duration(days: 1)));
      }).toList();

      // Calculer les statistiques
      double totalBenefices = 0.0;
      List<Map<String, dynamic>> detailsBenefices = [];

      for (var benefice in beneficesFiltres) {
        totalBenefices += benefice.montantTotal;

        detailsBenefices.add({
          'beneficeId': benefice.id,
          'annee': benefice.annee,
          'montantTotal': benefice.montantTotal,
          'dateDistribution': benefice.dateDistribution.toIso8601String(),
          'description': benefice.description,
          'estDistribue': benefice.estDistribue,
        });
      }

      // Créer le rapport
      final rapport = Rapport(
        titre: titre.isNotEmpty ? titre : 'Rapport des bénéfices',
        type: TypeRapport.benefices,
        periode: _determinerPeriode(dateDebut, dateFin),
        dateDebut: dateDebut,
        dateFin: dateFin,
        description: description.isNotEmpty ? description : 'Rapport généré automatiquement',
        generePar: generePar,
        donnees: {
          'totalBenefices': totalBenefices,
          'nombreBenefices': beneficesFiltres.length,
          'detailsBenefices': detailsBenefices,
        },
      );

      await addRapport(rapport);
      return rapport;
    } catch (error) {
      throw Exception('Erreur lors de la génération du rapport: $error');
    }
  }

  Future<Rapport> genererRapportGlobal({
    required DateTime dateDebut,
    required DateTime dateFin,
    String? adherentId,
    String titre = 'Rapport global',
    String description = '',
    String generePar = '',
  }) async {
    try {
      // Générer les deux sous-rapports
      final rapportCotisations = await genererRapportCotisations(
        dateDebut: dateDebut,
        dateFin: dateFin,
        adherentId: adherentId,
        titre: '',
        description: '',
        generePar: generePar,
      );

      final rapportBenefices = await genererRapportBenefices(
        dateDebut: dateDebut,
        dateFin: dateFin,
        titre: '',
        description: '',
        generePar: generePar,
      );

      // Combiner les données
      final rapport = Rapport(
        titre: titre.isNotEmpty ? titre : 'Rapport global',
        type: TypeRapport.global,
        periode: _determinerPeriode(dateDebut, dateFin),
        dateDebut: dateDebut,
        dateFin: dateFin,
        adherentId: adherentId,
        description: description.isNotEmpty ? description : 'Rapport global généré automatiquement',
        generePar: generePar,
        donnees: {
          'totalCotisations': rapportCotisations.totalCotisations,
          'totalBenefices': rapportBenefices.totalBenefices,
          'solde': rapportCotisations.totalCotisations - rapportBenefices.totalBenefices,
          'nombreCotisations': rapportCotisations.nombreCotisations,
          'nombreBenefices': rapportBenefices.donnees['nombreBenefices'] ?? 0,
          'nombreAdherents': rapportCotisations.nombreAdherents,
          'detailsCotisations': rapportCotisations.detailsCotisations,
          'detailsBenefices': rapportBenefices.detailsBenefices,
        },
      );

      await addRapport(rapport);
      return rapport;
    } catch (error) {
      throw Exception('Erreur lors de la génération du rapport global: $error');
    }
  }

  Future<Rapport> genererRapportAdherent({
    required String adherentId,
    required DateTime dateDebut,
    required DateTime dateFin,
    String titre = 'Rapport adhérent',
    String description = '',
    String generePar = '',
  }) async {
    try {
      // Récupérer les données de l'adhérent
      final adherents = await FirebaseService.getAllAdherents();
      final adherent = adherents.firstWhere((a) => a.id == adherentId);

      // Générer le rapport pour cet adhérent
      final rapport = await genererRapportCotisations(
        dateDebut: dateDebut,
        dateFin: dateFin,
        adherentId: adherentId,
        titre: titre.isNotEmpty ? titre : 'Rapport de ${adherent.nomComplet}',
        description: description.isNotEmpty ? description : 'Rapport individuel généré automatiquement',
        generePar: generePar,
      );

      // Mettre à jour le type et les données spécifiques à l'adhérent
      final rapportAdherent = rapport.copyWith(
        type: TypeRapport.adherent,
        donnees: {
          ...rapport.donnees,
          'adherentNom': adherent.nomComplet,
          'adherentTelephone': adherent.telephone,
          'adherentEmail': adherent.email,
          'dateAdhesion': adherent.dateAdhesion.toIso8601String(),
          'montantAnnuelContribution': adherent.montantAnnuelContribution,
        },
      );

      await updateRapport(rapportAdherent);
      return rapportAdherent;
    } catch (error) {
      throw Exception('Erreur lors de la génération du rapport de l\'adhérent: $error');
    }
  }

  PeriodeRapport _determinerPeriode(DateTime dateDebut, DateTime dateFin) {
    final difference = dateFin.difference(dateDebut).inDays;

    if (difference <= 31) {
      return PeriodeRapport.mensuel;
    } else if (difference <= 92) {
      return PeriodeRapport.trimestriel;
    } else if (difference <= 184) {
      return PeriodeRapport.semestriel;
    } else if (difference <= 366) {
      return PeriodeRapport.annuel;
    } else {
      return PeriodeRapport.personnalise;
    }
  }

  List<Rapport> getRapportsByType(TypeRapport type) {
    return state.value?.where((r) => r.type == type).toList() ?? [];
  }

  List<Rapport> getRapportsByAdherent(String adherentId) {
    return state.value?.where((r) => r.adherentId == adherentId).toList() ?? [];
  }

  List<Rapport> getRapportsByPeriode(DateTime debut, DateTime fin) {
    return state.value?.where((r) {
      return r.dateDebut.isAfter(debut.subtract(Duration(days: 1))) && 
             r.dateFin.isBefore(fin.add(Duration(days: 1)));
    }).toList() ?? [];
  }

  Future<void> exporterRapport(Rapport rapport, List<Adherent> adherents, {String format = 'pdf'}) async {
    try {
      switch (format.toLowerCase()) {
        case 'json':
          await ExportService.exportRapportJSON(rapport, adherents);
          break;
        case 'csv':
        case 'excel':
          await ExportService.exportRapportCSV(rapport, adherents);
          break;
        case 'pdf':
        default:
          await ExportService.exportRapportPDF(rapport, adherents);
          break;
      }
    } catch (error) {
      throw Exception('Erreur lors de l\'exportation: $error');
    }
  }
}

final rapportProvider = StateNotifierProvider<RapportNotifier, AsyncValue<List<Rapport>>>((ref) {
  final notifier = RapportNotifier();
  // Charger les rapports automatiquement au démarrage
  Future.microtask(() => notifier.loadRapports());
  return notifier;
});

final rapportsByTypeProvider = Provider.family<List<Rapport>, TypeRapport>((ref, type) {
  return ref.watch(rapportProvider).maybeWhen(
    data: (rapports) => rapports.where((r) => r.type == type).toList(),
    orElse: () => [],
  );
});

final rapportsByAdherentProvider = Provider.family<List<Rapport>, String>((ref, adherentId) {
  return ref.watch(rapportProvider).maybeWhen(
    data: (rapports) => rapports.where((r) => r.adherentId == adherentId).toList(),
    orElse: () => [],
  );
});
