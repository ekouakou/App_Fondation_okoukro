/// Modèle représentant un élève
class Eleve {
  final int idEleveInscrit;
  final int inscriptionsidEleve;
  final String matriculeEleve;
  final String nomEleve;
  final String prenomEleve;
  final String dateNaissanceEleve;
  final String classe;
  final int classeid;
  final String sexeEleve;
  final String lieuNaissance;
  final String inscriptionsStatus;
  final String inscriptionsStatutEleve;
  final String? urlPhoto;

  Eleve({
    required this.idEleveInscrit,
    required this.inscriptionsidEleve,
    required this.matriculeEleve,
    required this.nomEleve,
    required this.prenomEleve,
    required this.dateNaissanceEleve,
    required this.classe,
    required this.classeid,
    required this.sexeEleve,
    required this.lieuNaissance,
    required this.inscriptionsStatus,
    required this.inscriptionsStatutEleve,
    this.urlPhoto,
  });

  String get fullName => '$nomEleve $prenomEleve';

  factory Eleve.fromJson(Map<String, dynamic> json) {
    return Eleve(
      idEleveInscrit: json['idEleveInscrit'] as int? ?? 0,
      inscriptionsidEleve: json['inscriptionsidEleve'] as int? ?? 0,
      matriculeEleve: json['matriculeEleve'] as String? ?? '',
      nomEleve: json['nomEleve'] as String? ?? '',
      prenomEleve: json['prenomEleve'] as String? ?? '',
      dateNaissanceEleve: json['date_naissanceEleve'] as String? ?? '',
      classe: json['classe'] as String? ?? json['brancheLibelle'] as String? ?? '',
      classeid: json['classeid'] as int? ?? json['brancheid'] as int? ?? 0,
      sexeEleve: json['sexeEleve'] as String? ?? '',
      lieuNaissance: json['lieu_naissance'] as String? ?? '',
      inscriptionsStatus: json['inscriptions_status'] as String? ?? '',
      inscriptionsStatutEleve: json['inscriptions_statut_eleve'] as String? ?? '',
      urlPhoto: json['cheminphoto'] as String? ?? json['urlPhoto'] as String?, // Utiliser cheminphoto en priorité
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idEleveInscrit': idEleveInscrit,
      'inscriptionsidEleve': inscriptionsidEleve,
      'matriculeEleve': matriculeEleve,
      'nomEleve': nomEleve,
      'prenomEleve': prenomEleve,
      'date_naissanceEleve': dateNaissanceEleve,
      'classe': classe,
      'classeid': classeid,
      'sexeEleve': sexeEleve,
      'lieu_naissance': lieuNaissance,
      'inscriptions_status': inscriptionsStatus,
      'inscriptions_statut_eleve': inscriptionsStatutEleve,
      'urlPhoto': urlPhoto,
    };
  }
}

