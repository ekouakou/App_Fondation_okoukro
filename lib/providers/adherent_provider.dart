import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adherent.dart';
import '../services/firebase_service.dart';

class AdherentNotifier extends StateNotifier<AsyncValue<List<Adherent>>> {
  AdherentNotifier() : super(const AsyncValue.loading()) {
    // Charger les adhérents automatiquement à la création
    loadAdherents();
  }

  Future<void> loadAdherents() async {
    try {
      state = const AsyncValue.loading();
      final adherents = await FirebaseService.getAllAdherents();
      state = AsyncValue.data(adherents);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAdherent(Adherent adherent) async {
    try {
      await FirebaseService.insertAdherent(adherent);
      await loadAdherents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateAdherent(Adherent adherent) async {
    try {
      await FirebaseService.updateAdherent(adherent);
      await loadAdherents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAdherent(String id) async {
    try {
      await FirebaseService.deleteAdherent(id);
      await loadAdherents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Adherent?> getAdherentById(String id) async {
    try {
      return await FirebaseService.getAdherentById(id);
    } catch (error) {
      return null;
    }
  }

  List<Adherent> getAdherentsActifs() {
    return state.value?.where((a) => a.estActif).toList() ?? [];
  }

  Future<void> clearAllData() async {
    try {
      state = const AsyncValue.loading();
      
      // Vider toutes les collections dans l'ordre
      await FirebaseService.clearAllFinancialData();
      
      // Recharger la liste
      await loadAdherents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> resetWithNewAdherents(List<Adherent> newAdherents) async {
    try {
      state = const AsyncValue.loading();
      
      // Vider tous les adhérents existants
      await FirebaseService.clearAllAdherents();
      
      // Insérer les nouveaux adhérents
      await FirebaseService.insertMultipleAdherents(newAdherents);
      
      // Recharger la liste
      await loadAdherents();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  List<Adherent> searchAdherents(String query) {
    if (query.isEmpty) return state.value ?? [];
    
    final lowerQuery = query.toLowerCase();
    return state.value?.where((adherent) =>
      adherent.nom.toLowerCase().contains(lowerQuery) ||
      adherent.prenom.toLowerCase().contains(lowerQuery) ||
      adherent.telephone.contains(query) ||
      adherent.email.toLowerCase().contains(lowerQuery)
    ).toList() ?? [];
  }
}

final adherentProvider = StateNotifierProvider<AdherentNotifier, AsyncValue<List<Adherent>>>((ref) {
  final notifier = AdherentNotifier();
  // Charger les adhérents automatiquement au démarrage
  Future.microtask(() => notifier.loadAdherents());
  return notifier;
});

final adherentsActifsProvider = Provider<List<Adherent>>((ref) {
  return ref.watch(adherentProvider).maybeWhen(
    data: (adherents) => adherents.where((a) => a.estActif).toList(),
    orElse: () => [],
  );
});
