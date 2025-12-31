import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeRapport {
  cotisations,
  benefices,
  global,
  adherent,
}

enum PeriodeRapport {
  mensuel,
  trimestriel,
  semestriel,
  annuel,
  personnalise,
}

class Rapport {
  final String id;
  final String titre;
  final TypeRapport type;
  final PeriodeRapport periode;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? adherentId; // null si rapport pour tous les adhérents
  final String description;
  final Map<String, dynamic> donnees;
  final DateTime dateGeneration;
  final String? generePar; // ID de l'utilisateur qui a généré le rapport
  final bool estModifiable;

  Rapport({
    String? id,
    required this.titre,
    required this.type,
    required this.periode,
    required this.dateDebut,
    required this.dateFin,
    this.adherentId,
    this.description = '',
    required this.donnees,
    DateTime? dateGeneration,
    this.generePar,
    this.estModifiable = true,
  }) : id = id ?? const Uuid().v4(),
       dateGeneration = dateGeneration ?? DateTime.now();

  // Getters pour faciliter l'accès aux données
  double get totalCotisations => donnees['totalCotisations']?.toDouble() ?? 0.0;
  double get totalBenefices => donnees['totalBenefices']?.toDouble() ?? 0.0;
  int get nombreAdherents => donnees['nombreAdherents'] ?? 0;
  int get nombreCotisations => donnees['nombreCotisations'] ?? 0;
  List<Map<String, dynamic>> get detailsCotisations => 
      List<Map<String, dynamic>>.from(donnees['detailsCotisations'] ?? []);
  List<Map<String, dynamic>> get detailsBenefices => 
      List<Map<String, dynamic>>.from(donnees['detailsBenefices'] ?? []);

  String get typeFormate {
    switch (type) {
      case TypeRapport.cotisations:
        return 'Cotisations';
      case TypeRapport.benefices:
        return 'Bénéfices';
      case TypeRapport.global:
        return 'Global';
      case TypeRapport.adherent:
        return 'Adhérent';
    }
  }

  String get periodeFormate {
    switch (periode) {
      case PeriodeRapport.mensuel:
        return 'Mensuel';
      case PeriodeRapport.trimestriel:
        return 'Trimestriel';
      case PeriodeRapport.semestriel:
        return 'Semestriel';
      case PeriodeRapport.annuel:
        return 'Annuel';
      case PeriodeRapport.personnalise:
        return 'Personnalisé';
    }
  }

  String get periodeTexte {
    final debut = '${dateDebut.day}/${dateDebut.month}/${dateDebut.year}';
    final fin = '${dateFin.day}/${dateFin.month}/${dateFin.year}';
    return '$debut au $fin';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'type': type.index,
      'periode': periode.index,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin.toIso8601String(),
      'adherentId': adherentId,
      'description': description,
      'donnees': donnees,
      'dateGeneration': dateGeneration.toIso8601String(),
      'generePar': generePar,
      'estModifiable': estModifiable ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'titre': titre,
      'type': type.index,
      'periode': periode.index,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'adherentId': adherentId,
      'description': description,
      'donnees': donnees,
      'dateGeneration': Timestamp.fromDate(dateGeneration),
      'generePar': generePar,
      'estModifiable': estModifiable,
    };
  }

  factory Rapport.fromMap(Map<String, dynamic> map) {
    return Rapport(
      id: map['id'],
      titre: map['titre'],
      type: TypeRapport.values[map['type']],
      periode: PeriodeRapport.values[map['periode']],
      dateDebut: DateTime.parse(map['dateDebut']),
      dateFin: DateTime.parse(map['dateFin']),
      adherentId: map['adherentId'],
      description: map['description'] ?? '',
      donnees: Map<String, dynamic>.from(map['donnees'] ?? {}),
      dateGeneration: DateTime.parse(map['dateGeneration']),
      generePar: map['generePar'],
      estModifiable: map['estModifiable'] == 1,
    );
  }

  factory Rapport.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return Rapport(
      id: documentId,
      titre: map['titre'],
      type: TypeRapport.values[map['type']],
      periode: PeriodeRapport.values[map['periode']],
      dateDebut: (map['dateDebut'] as Timestamp).toDate(),
      dateFin: (map['dateFin'] as Timestamp).toDate(),
      adherentId: map['adherentId'],
      description: map['description'] ?? '',
      donnees: Map<String, dynamic>.from(map['donnees'] ?? {}),
      dateGeneration: (map['dateGeneration'] as Timestamp).toDate(),
      generePar: map['generePar'],
      estModifiable: map['estModifiable'] ?? true,
    );
  }

  Rapport copyWith({
    String? titre,
    TypeRapport? type,
    PeriodeRapport? periode,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? adherentId,
    String? description,
    Map<String, dynamic>? donnees,
    DateTime? dateGeneration,
    String? generePar,
    bool? estModifiable,
  }) {
    return Rapport(
      id: id,
      titre: titre ?? this.titre,
      type: type ?? this.type,
      periode: periode ?? this.periode,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      adherentId: adherentId ?? this.adherentId,
      description: description ?? this.description,
      donnees: donnees ?? this.donnees,
      dateGeneration: dateGeneration ?? this.dateGeneration,
      generePar: generePar ?? this.generePar,
      estModifiable: estModifiable ?? this.estModifiable,
    );
  }

  String get totalCotisationsFormate => '${totalCotisations.toInt()} FCFA';
  String get totalBeneficesFormate => '${totalBenefices.toInt()} FCFA';
}

class RapportCotisation {
  final String adherentId;
  final String adherentNom;
  final int annee;
  final int montantTotal;
  final int montantPaye;
  final int nombrePaiements;
  final double pourcentagePaye;
  final bool estSoldee;

  RapportCotisation({
    required this.adherentId,
    required this.adherentNom,
    required this.annee,
    required this.montantTotal,
    required this.montantPaye,
    required this.nombrePaiements,
    required this.pourcentagePaye,
    required this.estSoldee,
  });

  Map<String, dynamic> toMap() {
    return {
      'adherentId': adherentId,
      'adherentNom': adherentNom,
      'annee': annee,
      'montantTotal': montantTotal,
      'montantPaye': montantPaye,
      'nombrePaiements': nombrePaiements,
      'pourcentagePaye': pourcentagePaye,
      'estSoldee': estSoldee ? 1 : 0,
    };
  }

  factory RapportCotisation.fromMap(Map<String, dynamic> map) {
    return RapportCotisation(
      adherentId: map['adherentId'],
      adherentNom: map['adherentNom'],
      annee: map['annee'],
      montantTotal: map['montantTotal'],
      montantPaye: map['montantPaye'],
      nombrePaiements: map['nombrePaiements'],
      pourcentagePaye: map['pourcentagePaye']?.toDouble() ?? 0.0,
      estSoldee: map['estSoldee'] == 1,
    );
  }

  String get resteAPayer => '${(montantTotal - montantPaye)} FCFA';
  String get montantTotalFormate => '$montantTotal FCFA';
  String get montantPayeFormate => '$montantPaye FCFA';
  String get pourcentagePayeFormate => '${pourcentagePaye.toStringAsFixed(1)}%';
}

class RapportBenefice {
  final String beneficeId;
  final int annee;
  final int montantTotal;
  final DateTime dateDistribution;
  final String description;
  final int nombreBeneficiaires;
  final bool estDistribue;

  RapportBenefice({
    required this.beneficeId,
    required this.annee,
    required this.montantTotal,
    required this.dateDistribution,
    required this.description,
    required this.nombreBeneficiaires,
    required this.estDistribue,
  });

  Map<String, dynamic> toMap() {
    return {
      'beneficeId': beneficeId,
      'annee': annee,
      'montantTotal': montantTotal,
      'dateDistribution': dateDistribution.toIso8601String(),
      'description': description,
      'nombreBeneficiaires': nombreBeneficiaires,
      'estDistribue': estDistribue ? 1 : 0,
    };
  }

  factory RapportBenefice.fromMap(Map<String, dynamic> map) {
    return RapportBenefice(
      beneficeId: map['beneficeId'],
      annee: map['annee'],
      montantTotal: map['montantTotal'],
      dateDistribution: DateTime.parse(map['dateDistribution']),
      description: map['description'] ?? '',
      nombreBeneficiaires: map['nombreBeneficiaires'] ?? 0,
      estDistribue: map['estDistribue'] == 1,
    );
  }

  String get montantTotalFormate => '$montantTotal FCFA';
  String get dateDistributionFormate => 
      '${dateDistribution.day}/${dateDistribution.month}/${dateDistribution.year}';
}
