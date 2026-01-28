/// Modèle représentant une période (trimestre, semestre, etc.)
class Periode {
  final int id;
  final String libelle;
  final int niveau;
  final String coef;
  final String isfinal;
  final Periodicite periodicite;

  Periode({
    required this.id,
    required this.libelle,
    required this.niveau,
    required this.coef,
    required this.isfinal,
    required this.periodicite,
  });

  factory Periode.fromJson(Map<String, dynamic> json) {
    return Periode(
      id: json['id'] as int? ?? 0,
      libelle: json['libelle'] as String? ?? '',
      niveau: json['niveau'] as int? ?? 0,
      coef: json['coef'] as String? ?? '',
      isfinal: json['isfinal'] as String? ?? '',
      periodicite: Periodicite.fromJson(
        json['periodicite'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'niveau': niveau,
      'coef': coef,
      'isfinal': isfinal,
      'periodicite': periodicite.toJson(),
    };
  }
}

/// Modèle représentant la périodicité
class Periodicite {
  final int id;
  final String code;
  final String libelle;
  final String ordre;
  final String isDefault;

  Periodicite({
    required this.id,
    required this.code,
    required this.libelle,
    required this.ordre,
    required this.isDefault,
  });

  factory Periodicite.fromJson(Map<String, dynamic> json) {
    return Periodicite(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      libelle: json['libelle'] as String? ?? '',
      ordre: json['ordre'] as String? ?? '',
      isDefault: json['isDefault'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'ordre': ordre,
      'isDefault': isDefault,
    };
  }
}

