/// Modèle représentant une école
class Ecole {
  final int ecoleid;
  final String ecolecode;
  final String ecoleclibelle;

  Ecole({
    required this.ecoleid,
    required this.ecolecode,
    required this.ecoleclibelle,
  });

  factory Ecole.fromJson(Map<String, dynamic> json) {
    return Ecole(
      ecoleid: json['ecoleid'] as int? ?? 0,
      ecolecode: json['ecolecode'] as String? ?? '',
      ecoleclibelle: json['ecoleclibelle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ecoleid': ecoleid,
      'ecolecode': ecolecode,
      'ecoleclibelle': ecoleclibelle,
    };
  }
}

