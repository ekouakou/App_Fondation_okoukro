import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/benefice.dart';
import '../services/firebase_service.dart';
import '../services/calcul_service.dart';
import 'adherent_provider.dart';
import 'cotisation_provider.dart';

class BeneficeNotifier extends StateNotifier<AsyncValue<List<Benefice>>> {
  BeneficeNotifier() : super(const AsyncValue.loading()) {
    // Charger les bénéfices automatiquement à la création
    loadBenefices();
  }

  Future<void> loadBenefices() async {
    try {
      state = const AsyncValue.loading();
      final benefices = await FirebaseService.getAllBenefices();
      state = AsyncValue.data(benefices);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addBenefice(Benefice benefice) async {
    try {
      await FirebaseService.insertBenefice(benefice);
      await loadBenefices();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBenefice(Benefice benefice) async {
    try {
      await FirebaseService.updateBenefice(benefice);
      await loadBenefices();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> distribuerBenefice(Benefice benefice, int anneeDebut, int anneeFin) async {
    try {
      final adherents = await FirebaseService.getAllAdherents();
      final cotisations = await FirebaseService.getAllCotisations();
      
      final parts = CalculService.calculerPartsBenefices(
        adherents.where((a) => a.estActif).toList(),
        cotisations,
        benefice,
        anneeDebut,
        anneeFin,
      );

      await FirebaseService.insertPartsBenefices(benefice.id, parts);

      final beneficeMaj = benefice.copyWith(
        estDistribue: true,
        dateDistribution: DateTime.now(),
      );

      await updateBenefice(beneficeMaj);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Benefice> getBeneficesByAnnee(int annee) {
    return state.value?.where((b) => b.annee == annee).toList() ?? [];
  }

  List<Benefice> getBeneficesNonDistribues() {
    return state.value?.where((b) => !b.estDistribue).toList() ?? [];
  }

  List<Benefice> getBeneficesDistribues() {
    return state.value?.where((b) => b.estDistribue).toList() ?? [];
  }

  int getTotalBeneficesAnnee(int annee) {
    return getBeneficesByAnnee(annee)
        .fold(0, (sum, benefice) => sum + benefice.montantTotal as int);
  }

  Map<int, int> getTotalBeneficesParAnnee() {
    final Map<int, int> totaux = {};
    for (var benefice in state.value ?? []) {
      totaux[benefice.annee] = (totaux[benefice.annee] ?? 0) + benefice.montantTotal as int;
    }
    return totaux;
  }

  Future<List<PartBenefice>> getPartsBenefice(String beneficeId) async {
    try {
      return await FirebaseService.getPartsByBenefice(beneficeId);
    } catch (error) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistiquesDistribution(String beneficeId) async {
    try {
      final parts = await getPartsBenefice(beneficeId);
      final benefice = state.value?.firstWhere((b) => b.id == beneficeId);
      
      if (benefice == null) return {};
      
      return {
        'montantTotal': benefice.montantTotal,
        'montantDistribue': parts.fold(0, (sum, part) => sum + part.montantPart),
        'nombreBeneficiaires': parts.length,
        'partMoyenne': parts.isNotEmpty ? (benefice.montantTotal / parts.length).round() : 0,
        'dateDistribution': benefice.dateDistribution,
      };
    } catch (error) {
      return {};
    }
  }
}

final beneficeProvider = StateNotifierProvider<BeneficeNotifier, AsyncValue<List<Benefice>>>((ref) {
  return BeneficeNotifier();
});

final beneficesAnneeProvider = Provider.family<int, int>((ref, annee) {
  return ref.watch(beneficeProvider).maybeWhen(
    data: (benefices) => benefices
        .where((b) => b.annee == annee)
        .fold(0, (sum, b) => sum + b.montantTotal),
    orElse: () => 0,
  );
});

final beneficesNonDistribuesProvider = Provider<List<Benefice>>((ref) {
  return ref.watch(beneficeProvider).maybeWhen(
    data: (benefices) => benefices.where((b) => !b.estDistribue).toList(),
    orElse: () => [],
  );
});

final partsBeneficeProvider = Provider.family<Future<List<PartBenefice>>, String>((ref, beneficeId) {
  final notifier = ref.read(beneficeProvider.notifier);
  return notifier.getPartsBenefice(beneficeId);
});
