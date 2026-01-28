/// Modèle représentant une matière
class Matiere {
  final int id;
  final String? code;
  final String libelle;
  final String? codeVieEcole;
  final dynamic pec;
  final dynamic bonus;
  final dynamic niveauEnseignement;
  final dynamic moyenne;
  final dynamic rang;
  final dynamic coef;
  final dynamic appreciation;
  final dynamic eleveMatiereIsClassed;
  final dynamic matiereParent;
  final String? parentMatiereLibelle;
  final dynamic numOrdre;
  final dynamic categorie;
  final dynamic dateCreation;
  final dynamic dateUpdate;
  final dynamic user;

  Matiere({
    required this.id,
    this.code,
    required this.libelle,
    this.codeVieEcole,
    this.pec,
    this.bonus,
    this.niveauEnseignement,
    this.moyenne,
    this.rang,
    this.coef,
    this.appreciation,
    this.eleveMatiereIsClassed,
    this.matiereParent,
    this.parentMatiereLibelle,
    this.numOrdre,
    this.categorie,
    this.dateCreation,
    this.dateUpdate,
    this.user,
  });

  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      id: json['id'] as int,
      code: json['code'] as String?,
      libelle: json['libelle'] as String,
      codeVieEcole: json['code_vie_ecole'] as String?,
      pec: json['pec'],
      bonus: json['bonus'],
      niveauEnseignement: json['niveauEnseignement'],
      moyenne: json['moyenne'],
      rang: json['rang'],
      coef: json['coef'],
      appreciation: json['appreciation'],
      eleveMatiereIsClassed: json['eleveMatiereIsClassed'],
      matiereParent: json['matiereParent'],
      parentMatiereLibelle: json['parentMatiereLibelle'] as String?,
      numOrdre: json['numOrdre'],
      categorie: json['categorie'],
      dateCreation: json['dateCreation'],
      dateUpdate: json['dateUpdate'],
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'libelle': libelle,
      'code_vie_ecole': codeVieEcole,
      'pec': pec,
      'bonus': bonus,
      'niveauEnseignement': niveauEnseignement,
      'moyenne': moyenne,
      'rang': rang,
      'coef': coef,
      'appreciation': appreciation,
      'eleveMatiereIsClassed': eleveMatiereIsClassed,
      'matiereParent': matiereParent,
      'parentMatiereLibelle': parentMatiereLibelle,
      'numOrdre': numOrdre,
      'categorie': categorie,
      'dateCreation': dateCreation,
      'dateUpdate': dateUpdate,
      'user': user,
    };
  }
}

