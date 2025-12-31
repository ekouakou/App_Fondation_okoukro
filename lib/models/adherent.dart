import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Adherent {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final String adresse;
  final DateTime dateAdhesion;
  final bool estActif;
  final String photoUrl;
  final int montantAnnuelContribution; // Montant que l'adhérent s'engage à payer par an

  Adherent({
    String? id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email = '',
    this.adresse = '',
    DateTime? dateAdhesion,
    this.estActif = true,
    this.photoUrl = '',
    this.montantAnnuelContribution = 12000, // Valeur par défaut
  }) : id = id ?? const Uuid().v4(),
       dateAdhesion = dateAdhesion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'dateAdhesion': dateAdhesion.toIso8601String(),
      'estActif': estActif ? 1 : 0,
      'photoUrl': photoUrl,
      'montantAnnuelContribution': montantAnnuelContribution,
    };
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'dateAdhesion': Timestamp.fromDate(dateAdhesion),
      'estActif': estActif,
      'photoUrl': photoUrl,
      'montantAnnuelContribution': montantAnnuelContribution,
    };
  }

  factory Adherent.fromMap(Map<String, dynamic> map) {
    return Adherent(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      telephone: map['telephone'],
      email: map['email'] ?? '',
      adresse: map['adresse'] ?? '',
      dateAdhesion: DateTime.parse(map['dateAdhesion']),
      estActif: map['estActif'] == 1,
      photoUrl: map['photoUrl'] ?? '',
      montantAnnuelContribution: map['montantAnnuelContribution'] ?? 12000,
    );
  }

  factory Adherent.fromFirebaseMap(Map<String, dynamic> map, String documentId) {
    return Adherent(
      id: documentId,
      nom: map['nom'],
      prenom: map['prenom'],
      telephone: map['telephone'],
      email: map['email'] ?? '',
      adresse: map['adresse'] ?? '',
      dateAdhesion: (map['dateAdhesion'] as Timestamp).toDate(),
      estActif: map['estActif'] ?? true,
      photoUrl: map['photoUrl'] ?? '',
      montantAnnuelContribution: map['montantAnnuelContribution'] ?? 12000,
    );
  }

  String get nomComplet => '$prenom $nom';
  
  Adherent copyWith({
    String? nom,
    String? prenom,
    String? telephone,
    String? email,
    String? adresse,
    DateTime? dateAdhesion,
    bool? estActif,
    String? photoUrl,
    int? montantAnnuelContribution,
  }) {
    return Adherent(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      dateAdhesion: dateAdhesion ?? this.dateAdhesion,
      estActif: estActif ?? this.estActif,
      photoUrl: photoUrl ?? this.photoUrl,
      montantAnnuelContribution: montantAnnuelContribution ?? this.montantAnnuelContribution,
    );
  }

  String get montantContributionFormate => '$montantAnnuelContribution FCFA';
}
