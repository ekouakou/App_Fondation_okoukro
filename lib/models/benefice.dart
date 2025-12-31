import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Benefice {
  final String id;
  final int annee;
  final int montantTotal;
  final DateTime dateDistribution;
  final String description;
  final bool estDistribue;

  Benefice({
    String? id,
    required this.annee,
    required this.montantTotal,
    DateTime? dateDistribution,
    this.description = '',
    this.estDistribue = false,
  }) : id = id ?? const Uuid().v4(),
       dateDistribution = dateDistribution ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'annee': annee,
      'montantTotal': montantTotal,
      'dateDistribution': dateDistribution.toIso8601String(),
      'description': description,
      'estDistribue': estDistribue ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'annee': annee,
      'montantTotal': montantTotal,
      'dateDistribution': Timestamp.fromDate(dateDistribution),
      'description': description,
      'estDistribue': estDistribue,
    };
  }

  factory Benefice.fromMap(Map<String, dynamic> map) {
    return Benefice(
      id: map['id'],
      annee: map['annee'],
      montantTotal: map['montantTotal'],
      dateDistribution: DateTime.parse(map['dateDistribution']),
      description: map['description'] ?? '',
      estDistribue: map['estDistribue'] == 1,
    );
  }

  factory Benefice.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return Benefice(
      id: documentId,
      annee: map['annee'],
      montantTotal: map['montantTotal'],
      dateDistribution: (map['dateDistribution'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      estDistribue: map['estDistribue'] ?? false,
    );
  }

  String get montantFormate => '$montantTotal FCFA';
  
  Benefice copyWith({
    int? annee,
    int? montantTotal,
    DateTime? dateDistribution,
    String? description,
    bool? estDistribue,
  }) {
    return Benefice(
      id: id,
      annee: annee ?? this.annee,
      montantTotal: montantTotal ?? this.montantTotal,
      dateDistribution: dateDistribution ?? this.dateDistribution,
      description: description ?? this.description,
      estDistribue: estDistribue ?? this.estDistribue,
    );
  }
}

class PartBenefice {
  final String adherentId;
  final String beneficeId;
  final int montantPart;
  final double pourcentage;
  final int totalCotisationsAdherent;

  PartBenefice({
    required this.adherentId,
    required this.beneficeId,
    required this.montantPart,
    required this.pourcentage,
    required this.totalCotisationsAdherent,
  });

  Map<String, dynamic> toMap() {
    return {
      'adherentId': adherentId,
      'beneficeId': beneficeId,
      'montantPart': montantPart,
      'pourcentage': pourcentage,
      'totalCotisationsAdherent': totalCotisationsAdherent,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'adherentId': adherentId,
      'beneficeId': beneficeId,
      'montantPart': montantPart,
      'pourcentage': pourcentage,
      'totalCotisationsAdherent': totalCotisationsAdherent,
    };
  }

  factory PartBenefice.fromMap(Map<String, dynamic> map) {
    return PartBenefice(
      adherentId: map['adherentId'],
      beneficeId: map['beneficeId'],
      montantPart: map['montantPart'],
      pourcentage: map['pourcentage'],
      totalCotisationsAdherent: map['totalCotisationsAdherent'],
    );
  }

  factory PartBenefice.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return PartBenefice(
      adherentId: map['adherentId'],
      beneficeId: map['beneficeId'],
      montantPart: map['montantPart'],
      pourcentage: map['pourcentage'],
      totalCotisationsAdherent: map['totalCotisationsAdherent'],
    );
  }

  String get montantFormate => '$montantPart FCFA';
  
  String get pourcentageFormate => '${pourcentage.toStringAsFixed(2)}%';
}
