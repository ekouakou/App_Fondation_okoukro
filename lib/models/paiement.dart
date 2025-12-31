import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutPaiement {
  enAttente,
  complete,
  partiel,
  retard,
}

enum MethodePaiement {
  espece,
  mobileMoney,
  virement,
  cheque,
}

class Paiement {
  final String id;
  final String adherentId;
  final int annee;
  final int montantVerse;
  final DateTime datePaiement;
  final StatutPaiement statut;
  final MethodePaiement methode;
  final String? referenceTransaction;
  final String? notes;

  Paiement({
    String? id,
    required this.adherentId,
    required this.annee,
    required this.montantVerse,
    DateTime? datePaiement,
    this.statut = StatutPaiement.complete,
    this.methode = MethodePaiement.espece,
    this.referenceTransaction,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       datePaiement = datePaiement ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adherentId': adherentId,
      'annee': annee,
      'montantVerse': montantVerse,
      'datePaiement': datePaiement.toIso8601String(),
      'statut': statut.index,
      'methode': methode.index,
      'referenceTransaction': referenceTransaction,
      'notes': notes,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'adherentId': adherentId,
      'annee': annee,
      'montantVerse': montantVerse,
      'datePaiement': Timestamp.fromDate(datePaiement),
      'statut': statut.name,
      'methode': methode.name,
      'referenceTransaction': referenceTransaction,
      'notes': notes,
    };
  }

  factory Paiement.fromMap(Map<String, dynamic> map) {
    return Paiement(
      id: map['id'],
      adherentId: map['adherentId'],
      annee: map['annee'],
      montantVerse: map['montantVerse'],
      datePaiement: DateTime.parse(map['datePaiement']),
      statut: StatutPaiement.values[map['statut']],
      methode: MethodePaiement.values[map['methode']],
      referenceTransaction: map['referenceTransaction'],
      notes: map['notes'],
    );
  }

  factory Paiement.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return Paiement(
      id: documentId,
      adherentId: map['adherentId'],
      annee: map['annee'],
      montantVerse: map['montantVerse'],
      datePaiement: (map['datePaiement'] as Timestamp).toDate(),
      statut: StatutPaiement.values.firstWhere((e) => e.name == map['statut']),
      methode: MethodePaiement.values.firstWhere((e) => e.name == map['methode']),
      referenceTransaction: map['referenceTransaction'],
      notes: map['notes'],
    );
  }

  String get montantFormate => '$montantVerse FCFA';
  
  String get statutFormate {
    switch (statut) {
      case StatutPaiement.enAttente:
        return 'En attente';
      case StatutPaiement.complete:
        return 'Complet';
      case StatutPaiement.partiel:
        return 'Partiel';
      case StatutPaiement.retard:
        return 'Retard';
    }
  }

  String get methodeFormate {
    switch (methode) {
      case MethodePaiement.espece:
        return 'Espèce';
      case MethodePaiement.mobileMoney:
        return 'Mobile Money';
      case MethodePaiement.virement:
        return 'Virement';
      case MethodePaiement.cheque:
        return 'Chèque';
    }
  }

  Paiement copyWith({
    String? adherentId,
    int? annee,
    int? montantVerse,
    DateTime? datePaiement,
    StatutPaiement? statut,
    MethodePaiement? methode,
    String? referenceTransaction,
    String? notes,
  }) {
    return Paiement(
      id: id,
      adherentId: adherentId ?? this.adherentId,
      annee: annee ?? this.annee,
      montantVerse: montantVerse ?? this.montantVerse,
      datePaiement: datePaiement ?? this.datePaiement,
      statut: statut ?? this.statut,
      methode: methode ?? this.methode,
      referenceTransaction: referenceTransaction ?? this.referenceTransaction,
      notes: notes ?? this.notes,
    );
  }
}
