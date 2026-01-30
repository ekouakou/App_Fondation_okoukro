import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cotisation.dart';
import '../services/firebase_service.dart';

class CotisationNotifier extends StateNotifier<AsyncValue<List<Cotisation>>> {
  CotisationNotifier() : super(const AsyncValue.loading()) {
    // Charger les cotisations automatiquement à la création
    loadCotisations();
  }

  Future<void> loadCotisations() async {
    try {
      state = const AsyncValue.loading();
      final cotisations = await FirebaseService.getAllCotisations();
      state = AsyncValue.data(cotisations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addCotisation(Cotisation cotisation) async {
    try {
      await FirebaseService.insertCotisation(cotisation);
      await loadCotisations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCotisation(Cotisation cotisation) async {
    try {
      await FirebaseService.updateCotisation(cotisation);
      await loadCotisations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteCotisation(String cotisationId) async {
    try {
      await FirebaseService.deleteCotisation(cotisationId);
      await loadCotisations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Cotisation?> getCotisationByAdherentAnnee(String adherentId, int annee) async {
    try {
      return await FirebaseService.getCotisationByAdherentAnnee(adherentId, annee);
    } catch (error) {
      return null;
    }
  }

  Future<List<Cotisation>> getCotisationsByAdherent(String adherentId) async {
    try {
      return await FirebaseService.getCotisationsByAdherent(adherentId);
    } catch (error) {
      return [];
    }
  }

  List<Cotisation> getCotisationsByAnnee(int annee) {
    return state.value?.where((c) => c.annee == annee).toList() ?? [];
  }

  List<Cotisation> getCotisationsByAdherentSync(String adherentId) {
    return state.value?.where((c) => c.adherentId == adherentId).toList() ?? [];
  }

  Future<void> augmenterCotisation({
    required String adherentId,
    required int annee,
    required int nouveauMontant,
    String? motif,
  }) async {
    try {
      final cotisationExistante = await getCotisationByAdherentAnnee(adherentId, annee);
      
      if (cotisationExistante != null) {
        final cotisationMaj = cotisationExistante.copyWith(
          montantAnnuel: nouveauMontant,
          dateModification: DateTime.now(),
          motifModification: motif ?? 'Augmentation de cotisation',
        );
        await updateCotisation(cotisationMaj);
      } else {
        final nouvelleCotisation = Cotisation(
          adherentId: adherentId,
          montantAnnuel: nouveauMontant,
          annee: annee,
          motifModification: motif ?? 'Nouvelle cotisation',
        );
        await addCotisation(nouvelleCotisation);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Map<int, int> getTotalCotisationsParAnnee() {
    final Map<int, int> totaux = {};
    for (var cotisation in state.value ?? []) {
      totaux[cotisation.annee] = (totaux[cotisation.annee] ?? 0) + cotisation.montantAnnuel as int;
    }
    return totaux;
  }

  Future<void> clearAllCotisations() async {
    try {
      state = const AsyncValue.loading();
      await FirebaseService.clearAllCotisations();
      await loadCotisations();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  int getTotalCotisationsAnnee(int annee) {
    return getCotisationsByAnnee(annee)
        .fold(0, (sum, cotisation) => sum + cotisation.montantAnnuel as int);
  }
}

final cotisationProvider = StateNotifierProvider<CotisationNotifier, AsyncValue<List<Cotisation>>>((ref) {
  final notifier = CotisationNotifier();
  // Charger les cotisations automatiquement au démarrage
  Future.microtask(() => notifier.loadCotisations());
  return notifier;
});

final cotisationsAnneeProvider = Provider.family<int, int>((ref, annee) {
  return ref.watch(cotisationProvider).maybeWhen(
    data: (cotisations) => cotisations
        .where((c) => c.annee == annee)
        .fold(0, (sum, c) => sum + c.montantAnnuel),
    orElse: () => 0,
  );
});
