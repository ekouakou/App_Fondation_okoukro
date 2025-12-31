import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';
import '../models/rapport.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionAdherents = 'adherents';
  static const String _collectionCotisations = 'cotisations';
  static const String _collectionPaiements = 'paiements';
  static const String _collectionBenefices = 'benefices';
  static const String _collectionRapports = 'rapports';

  // ===== OPÉRATIONS ADHÉRENTS =====
  
  static Future<String> insertAdherent(Adherent adherent) async {
    try {
      await _firestore.collection(_collectionAdherents).doc(adherent.id).set(adherent.toFirebaseMap());
      return adherent.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'adhérent: $e');
    }
  }

  static Future<List<Adherent>> getAllAdherents() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionAdherents)
          .orderBy('nom')
          .orderBy('prenom')
          .get();
      
      return snapshot.docs
          .map((doc) => Adherent.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des adhérents: $e');
    }
  }

  static Future<Adherent?> getAdherentById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionAdherents).doc(id).get();
      
      if (doc.exists) {
        return Adherent.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'adhérent: $e');
    }
  }

  static Future<void> updateAdherent(Adherent adherent) async {
    try {
      await _firestore.collection(_collectionAdherents).doc(adherent.id).update(adherent.toFirebaseMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'adhérent: $e');
    }
  }

  static Future<void> deleteAdherent(String id) async {
    try {
      await _firestore.collection(_collectionAdherents).doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'adhérent: $e');
    }
  }

  // ===== OPÉRATIONS COTISATIONS =====
  
  static Future<String> insertCotisation(Cotisation cotisation) async {
    try {
      await _firestore.collection(_collectionCotisations).doc(cotisation.id).set(cotisation.toFirebaseMap());
      return cotisation.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la cotisation: $e');
    }
  }

  static Future<List<Cotisation>> getAllCotisations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionCotisations)
          .orderBy('annee', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Cotisation.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cotisations: $e');
    }
  }

  static Future<List<Cotisation>> getCotisationsByAdherent(String adherentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionCotisations)
          .where('adherentId', isEqualTo: adherentId)
          .orderBy('annee', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Cotisation.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cotisations de l\'adhérent: $e');
    }
  }

  static Future<Cotisation?> getCotisationByAdherentAnnee(String adherentId, int annee) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionCotisations)
          .where('adherentId', isEqualTo: adherentId)
          .where('annee', isEqualTo: annee)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return Cotisation.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la cotisation: $e');
    }
  }

  static Future<void> updateCotisation(Cotisation cotisation) async {
    try {
      await _firestore.collection(_collectionCotisations).doc(cotisation.id).update(cotisation.toFirebaseMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la cotisation: $e');
    }
  }

  // ===== OPÉRATIONS PAIEMENTS =====
  
  static Future<String> insertPaiement(Paiement paiement) async {
    try {
      await _firestore.collection(_collectionPaiements).doc(paiement.id).set(paiement.toFirebaseMap());
      return paiement.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du paiement: $e');
    }
  }

  static Future<List<Paiement>> getAllPaiements() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionPaiements)
          .orderBy('datePaiement', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Paiement.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements: $e');
    }
  }

  static Future<List<Paiement>> getPaiementsByAdherent(String adherentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionPaiements)
          .where('adherentId', isEqualTo: adherentId)
          .orderBy('datePaiement', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Paiement.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements de l\'adhérent: $e');
    }
  }

  static Future<List<Paiement>> getPaiementsByAnnee(int annee) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionPaiements)
          .where('annee', isEqualTo: annee)
          .orderBy('datePaiement', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Paiement.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des paiements de l\'année: $e');
    }
  }

  // ===== OPÉRATIONS BÉNÉFICES =====
  
  static Future<String> insertBenefice(Benefice benefice) async {
    try {
      await _firestore.collection(_collectionBenefices).doc(benefice.id).set(benefice.toFirebaseMap());
      return benefice.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du bénéfice: $e');
    }
  }

  static Future<List<Benefice>> getAllBenefices() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionBenefices)
          .orderBy('annee', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Benefice.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bénéfices: $e');
    }
  }

  static Future<void> updateBenefice(Benefice benefice) async {
    try {
      await _firestore.collection(_collectionBenefices).doc(benefice.id).update(benefice.toFirebaseMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bénéfice: $e');
    }
  }

  // ===== OPÉRATIONS PARTS BÉNÉFICES =====
  
  static Future<void> insertPartsBenefices(String beneficeId, List<PartBenefice> parts) async {
    try {
      final batch = _firestore.batch();
      
      for (var part in parts) {
        final docRef = _firestore
            .collection(_collectionBenefices)
            .doc(beneficeId)
            .collection('parts')
            .doc(part.adherentId);
        
        batch.set(docRef, part.toFirebaseMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout des parts de bénéfices: $e');
    }
  }

  static Future<List<PartBenefice>> getPartsByBenefice(String beneficeId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionBenefices)
          .doc(beneficeId)
          .collection('parts')
          .orderBy('montantPart', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => PartBenefice.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des parts de bénéfices: $e');
    }
  }
  
  static Future<void> clearAllData() async {
    try {
      var collections = [
        _firestore.collection(_collectionPaiements),
        _firestore.collection(_collectionCotisations),
        _firestore.collection(_collectionBenefices),
        _firestore.collection(_collectionAdherents),
      ];

      for (var collection in collections) {
        var snapshot = await collection.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des données: $e');
    }
  }

  // Stream pour les requêtes en temps réel
  static Stream<List<Adherent>> streamAllAdherents() {
    return _firestore
        .collection(_collectionAdherents)
        .orderBy('nom')
        .orderBy('prenom')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Adherent.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Paiement>> streamPaiementsByAnnee(int annee) {
    return _firestore
        .collection(_collectionPaiements)
        .where('annee', isEqualTo: annee)
        .orderBy('datePaiement', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Paiement.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // ===== OPÉRATIONS RAPPORTS =====
  
  static Future<String> insertRapport(Rapport rapport) async {
    try {
      await _firestore.collection(_collectionRapports).doc(rapport.id).set(rapport.toFirebaseMap());
      return rapport.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du rapport: $e');
    }
  }

  static Future<List<Rapport>> getAllRapports() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionRapports)
          .orderBy('dateGeneration', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rapports: $e');
    }
  }

  static Future<Rapport?> getRapportById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collectionRapports).doc(id).get();
      
      if (doc.exists) {
        return Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du rapport: $e');
    }
  }

  static Future<void> updateRapport(Rapport rapport) async {
    try {
      await _firestore.collection(_collectionRapports).doc(rapport.id).update(rapport.toFirebaseMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du rapport: $e');
    }
  }

  static Future<void> deleteRapport(String id) async {
    try {
      await _firestore.collection(_collectionRapports).doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du rapport: $e');
    }
  }

  static Future<List<Rapport>> getRapportsByType(TypeRapport type) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionRapports)
          .where('type', isEqualTo: type.index)
          .orderBy('dateGeneration', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rapports par type: $e');
    }
  }

  static Future<List<Rapport>> getRapportsByAdherent(String adherentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionRapports)
          .where('adherentId', isEqualTo: adherentId)
          .orderBy('dateGeneration', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rapports de l\'adhérent: $e');
    }
  }

  static Future<List<Rapport>> getRapportsByPeriode(DateTime dateDebut, DateTime dateFin) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionRapports)
          .where('dateDebut', isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut))
          .where('dateFin', isLessThanOrEqualTo: Timestamp.fromDate(dateFin))
          .orderBy('dateGeneration', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des rapports par période: $e');
    }
  }

  static Stream<List<Rapport>> streamRapports() {
    return _firestore
        .collection(_collectionRapports)
        .orderBy('dateGeneration', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Stream<List<Rapport>> streamRapportsByType(TypeRapport type) {
    return _firestore
        .collection(_collectionRapports)
        .where('type', isEqualTo: type.index)
        .orderBy('dateGeneration', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rapport.fromFirebaseMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
