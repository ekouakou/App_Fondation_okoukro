/// Modèle représentant une classe
class Classe {
  final int id;
  final String libelle;
  final String code;
  final int effectif;
  final Map<String, dynamic>? branche;
  final Map<String, dynamic>? ecole;

  Classe({
    required this.id,
    required this.libelle,
    required this.code,
    required this.effectif,
    this.branche,
    this.ecole,
  });

  factory Classe.fromJson(Map<String, dynamic> json) {
    return Classe(
      id: json['id'] as int? ?? 0,
      libelle: json['libelle'] as String? ?? '',
      code: json['code'] as String? ?? '',
      effectif: json['effectif'] as int? ?? 0,
      branche: json['branche'] as Map<String, dynamic>?,
      ecole: json['ecole'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'libelle': libelle,
      'code': code,
      'effectif': effectif,
      'branche': branche,
      'ecole': ecole,
    };
  }
}

