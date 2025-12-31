import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Cotisation {
  final String id;
  final String adherentId;
  final int montantAnnuel; // Montant de contribution de l'adhérent pour cette année
  final int montantPaye; // Montant déjà payé
  final int annee;
  final DateTime dateModification;
  final String? motifModification;

  Cotisation({
    String? id,
    required this.adherentId,
    required this.montantAnnuel,
    this.montantPaye = 0,
    required this.annee,
    DateTime? dateModification,
    this.motifModification,
  }) : id = id ?? const Uuid().v4(),
       dateModification = dateModification ?? DateTime.now();

  // Getters
  int get resteAPayer => montantAnnuel - montantPaye;
  double get pourcentagePaye => montantAnnuel > 0 ? (montantPaye / montantAnnuel) * 100 : 0;
  bool get estSoldee => montantPaye >= montantAnnuel;
  String get statut {
    if (montantPaye == 0) return 'Non payée';
    if (montantPaye >= montantAnnuel) return 'Soldée';
    return 'Partiellement payée';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adherentId': adherentId,
      'montantAnnuel': montantAnnuel,
      'montantPaye': montantPaye,
      'annee': annee,
      'dateModification': dateModification.toIso8601String(),
      'motifModification': motifModification,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'adherentId': adherentId,
      'montantAnnuel': montantAnnuel,
      'montantPaye': montantPaye,
      'annee': annee,
      'dateModification': Timestamp.fromDate(dateModification),
      'motifModification': motifModification,
    };
  }

  factory Cotisation.fromMap(Map<String, dynamic> map) {
    return Cotisation(
      id: map['id'],
      adherentId: map['adherentId'],
      montantAnnuel: map['montantAnnuel'],
      montantPaye: map['montantPaye'] ?? 0,
      annee: map['annee'],
      dateModification: DateTime.parse(map['dateModification']),
      motifModification: map['motifModification'],
    );
  }

  factory Cotisation.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return Cotisation(
      id: documentId,
      adherentId: map['adherentId'],
      montantAnnuel: map['montantAnnuel'],
      montantPaye: map['montantPaye'] ?? 0,
      annee: map['annee'],
      dateModification: (map['dateModification'] as Timestamp).toDate(),
      motifModification: map['motifModification'],
    );
  }

  Cotisation copyWith({
    String? adherentId,
    int? montantAnnuel,
    int? montantPaye,
    int? annee,
    DateTime? dateModification,
    String? motifModification,
  }) {
    return Cotisation(
      id: id,
      adherentId: adherentId ?? this.adherentId,
      montantAnnuel: montantAnnuel ?? this.montantAnnuel,
      montantPaye: montantPaye ?? this.montantPaye,
      annee: annee ?? this.annee,
      dateModification: dateModification ?? this.dateModification,
      motifModification: motifModification ?? this.motifModification,
    );
  }

  String get montantFormate => '$montantAnnuel FCFA';
  String get montantPayeFormate => '$montantPaye FCFA';
  String get resteFormate => '$resteAPayer FCFA';
}
