/// Modèle représentant une année scolaire
class AnneeScolaire {
  final int ecoleId;
  final String ecolelibelle;
  final int anneeOuverteCentraleId;
  final List<AnneeEcole> anneeEcoleList;

  AnneeScolaire({
    required this.ecoleId,
    required this.ecolelibelle,
    required this.anneeOuverteCentraleId,
    required this.anneeEcoleList,
  });

  factory AnneeScolaire.fromJson(Map<String, dynamic> json) {
    return AnneeScolaire(
      ecoleId: json['ecoleId'] as int? ?? 0,
      ecolelibelle: json['ecolelibelle'] as String? ?? '',
      anneeOuverteCentraleId: json['anneeOuverteCentraleId'] as int? ?? 0,
      anneeEcoleList: (json['anneeEcoleList'] as List?)
              ?.map((e) => AnneeEcole.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ecoleId': ecoleId,
      'ecolelibelle': ecolelibelle,
      'anneeOuverteCentraleId': anneeOuverteCentraleId,
      'anneeEcoleList': anneeEcoleList.map((e) => e.toJson()).toList(),
    };
  }
}

/// Modèle représentant une année école dans la liste
class AnneeEcole {
  final int anneeId;
  final String anneeLibelle;
  final String statut;

  AnneeEcole({
    required this.anneeId,
    required this.anneeLibelle,
    required this.statut,
  });

  factory AnneeEcole.fromJson(Map<String, dynamic> json) {
    return AnneeEcole(
      anneeId: json['anneeId'] as int? ?? 0,
      anneeLibelle: json['anneeLibelle'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anneeId': anneeId,
      'anneeLibelle': anneeLibelle,
      'statut': statut,
    };
  }
}

