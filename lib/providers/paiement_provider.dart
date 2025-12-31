import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paiement.dart';
import '../services/firebase_service.dart';

class PaiementNotifier extends StateNotifier<AsyncValue<List<Paiement>>> {
  PaiementNotifier() : super(const AsyncValue.loading());

  Future<void> loadPaiements() async {
    try {
      state = const AsyncValue.loading();
      final paiements = await FirebaseService.getAllPaiements();
      state = AsyncValue.data(paiements);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addPaiement(Paiement paiement) async {
    try {
      await FirebaseService.insertPaiement(paiement);
      await loadPaiements();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<Paiement>> getPaiementsByAdherent(String adherentId) async {
    try {
      return await FirebaseService.getPaiementsByAdherent(adherentId);
    } catch (error) {
      return [];
    }
  }

  Future<List<Paiement>> getPaiementsByAnnee(int annee) async {
    try {
      return await FirebaseService.getPaiementsByAnnee(annee);
    } catch (error) {
      return [];
    }
  }

  List<Paiement> getPaiementsByAnneeSync(int annee) {
    return state.value?.where((p) => p.annee == annee).toList() ?? [];
  }

  List<Paiement> getPaiementsByAdherentSync(String adherentId) {
    return state.value?.where((p) => p.adherentId == adherentId).toList() ?? [];
  }

  List<Paiement> getPaiementsByStatut(StatutPaiement statut) {
    return state.value?.where((p) => p.statut == statut).toList() ?? [];
  }

  Map<int, int> getTotalPaiementsParAnnee() {
    final Map<int, int> totaux = {};
    for (var paiement in state.value ?? []) {
      totaux[paiement.annee] = (totaux[paiement.annee] ?? 0) + paiement.montantVerse as int;
    }
    return totaux;
  }

  int getTotalPaiementsAnnee(int annee) {
    final paiementsAnnee = getPaiementsByAnneeSync(annee);
    if (paiementsAnnee.isEmpty) return 0;
    return paiementsAnnee.fold(0, (sum, paiement) => sum + (paiement.montantVerse as int));
  }

  int getTotalPaiementsAdherentAnnee(String adherentId, int annee) {
    final paiementsAnnee = state.value
        ?.where((p) => p.adherentId == adherentId && p.annee == annee)
        .toList() ?? [];
    if (paiementsAnnee.isEmpty) return 0;
    return paiementsAnnee.fold(0, (sum, p) => sum + (p.montantVerse as int));
  }

  Map<StatutPaiement, int> getStatistiquesParStatut(int annee) {
    final Map<StatutPaiement, int> stats = {};
    for (var statut in StatutPaiement.values) {
      stats[statut] = 0;
    }
    
    for (var paiement in getPaiementsByAnneeSync(annee)) {
      stats[paiement.statut] = (stats[paiement.statut] ?? 0) + 1;
    }
    
    return stats;
  }

  List<Paiement> getPaiementsEnRetard() {
    return state.value?.where((p) => p.statut == StatutPaiement.retard).toList() ?? [];
  }

  List<Paiement> getPaiementsEnAttente() {
    return state.value?.where((p) => p.statut == StatutPaiement.enAttente).toList() ?? [];
  }

  Future<void> markPaiementAsComplete(String paiementId) async {
    try {
      final paiements = state.value ?? [];
      final paiement = paiements.firstWhere((p) => p.id == paiementId);
      
      final paiementMaj = paiement.copyWith(
        statut: StatutPaiement.complete,
        datePaiement: DateTime.now(),
      );
      
      // Note: En pratique, il faudrait une méthode updatePaiement dans DatabaseService
      await addPaiement(paiementMaj);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final paiementProvider = StateNotifierProvider<PaiementNotifier, AsyncValue<List<Paiement>>>((ref) {
  return PaiementNotifier();
});

final paiementsAnneeProvider = Provider.family<int, int>((ref, annee) {
  final paiementState = ref.watch(paiementProvider);
  return paiementState.maybeWhen(
    data: (paiements) => paiements
        .where((p) => p.annee == annee)
        .fold(0, (sum, p) => sum + p.montantVerse),
    orElse: () => 0,
  );
});

final paiementsEnRetardProvider = Provider<List<Paiement>>((ref) {
  return ref.watch(paiementProvider).maybeWhen(
    data: (paiements) => paiements.where((p) => p.statut == StatutPaiement.retard).toList(),
    orElse: () => [],
  );
});
