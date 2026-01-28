import 'note_api.dart';

// Helper function to parse dynamic values to int
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

// Helper function to parse dynamic values to double
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is String) return double.tryParse(value);
  if (value is num) return value.toDouble();
  return null;
}

/// Modèle représentant la réponse de l'API list-matricule-notes-moyennes
class NoteClasseDto {
  final EleveNote? eleve;
  final ClasseNote? classe;
  final double? moyenne;
  final String? observation;
  final int? rang; // Rang global de l'élève
  final List<MatiereNote> matieres;
  final Map<String, dynamic>? noteMatiereMap; // Map contenant les rangs par matière

  NoteClasseDto({
    this.eleve,
    this.classe,
    this.moyenne,
    this.observation,
    this.rang,
    required this.matieres,
    this.noteMatiereMap,
  });

  factory NoteClasseDto.fromJson(Map<String, dynamic> json) {
    // Parser notesMatiereMap qui est un tableau de {key: {...}, value: [...]}
    final List<MatiereNote> matieresList = [];
    if (json['notesMatiereMap'] != null && json['notesMatiereMap'] is List) {
      final notesMatiereMapList = json['notesMatiereMap'] as List<dynamic>;
      for (final item in notesMatiereMapList) {
        if (item is Map<String, dynamic>) {
          try {
            final matiereNote = MatiereNote.fromJson(item);
            matieresList.add(matiereNote);
          } catch (e) {
            print('⚠️ Erreur lors du parsing d\'une matière: $e');
          }
        }
      }
    }
    
    // Extraire le rang depuis periode.rang si disponible, sinon depuis le niveau racine
    int? rang;
    if (json['periode'] != null && json['periode'] is Map<String, dynamic>) {
      final periode = json['periode'] as Map<String, dynamic>;
      rang = _parseInt(periode['rang']) ?? _parseInt(json['rang']);
    } else {
      rang = _parseInt(json['rang']);
    }
    
    return NoteClasseDto(
      eleve: json['eleve'] != null
          ? EleveNote.fromJson(json['eleve'] as Map<String, dynamic>)
          : null,
      classe: json['classe'] != null
          ? ClasseNote.fromJson(json['classe'] as Map<String, dynamic>)
          : null,
      moyenne: _parseDouble(json['moyenne']),
      observation: json['appreciation'] as String? ?? json['observation'] as String?, // Use 'appreciation' as general observation
      rang: rang,
      matieres: matieresList,
      noteMatiereMap: json['notesMatiereMap'] != null
          ? { for (var item in (json['notesMatiereMap'] as List)) item['key']['id'].toString(): item['key'] }
          : null,
    );
  }
}

/// Modèle représentant l'élève dans la réponse des notes
class EleveNote {
  final int id;
  final String matricule;
  final String nom;
  final String prenom;
  final String? sexe;
  final String? urlPhoto;

  EleveNote({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    this.sexe,
    this.urlPhoto,
  });

  factory EleveNote.fromJson(Map<String, dynamic> json) {
    return EleveNote(
      id: _parseInt(json['id']) ?? 0,
      matricule: json['matricule'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      sexe: json['sexe'] as String?,
      urlPhoto: json['urlPhoto'] as String?,
    );
  }
}

/// Modèle représentant la classe dans la réponse des notes
class ClasseNote {
  final int id;
  final String libelle;
  final int? effectif; // Ajouté pour l'effectif de la classe

  ClasseNote({
    required this.id,
    required this.libelle,
    this.effectif,
  });

  factory ClasseNote.fromJson(Map<String, dynamic> json) {
    return ClasseNote(
      id: _parseInt(json['id']) ?? 0,
      libelle: json['libelle'] as String? ?? '',
      effectif: _parseInt(json['effectif']),
    );
  }
}

/// Modèle représentant une matière avec ses notes
class MatiereNote {
  final String matiereId; // Extrait depuis matiereEcole.id
  final String matiereLibelle;
  final double? moyenne;
  final double? coef;
  final double? moyenneCoef;
  final String? appreciation;
  final int? rang; // Rang de la matière (depuis noteMatiereMap.key.rang)
  final List<NoteDetail> notes;
  final MatiereEcole? matiereEcole; // Objet contenant l'ID de la matière

  MatiereNote({
    required this.matiereId,
    required this.matiereLibelle,
    this.moyenne,
    this.coef,
    this.moyenneCoef,
    this.appreciation,
    this.rang,
    required this.notes,
    this.matiereEcole,
  });

  factory MatiereNote.fromJson(Map<String, dynamic> json) {
    // L'objet MatiereNote est en fait le "key" de l'élément dans notesMatiereMap
    final keyJson = json['key'] as Map<String, dynamic>?;
    final valueList = json['value'] as List<dynamic>?;

    if (keyJson == null) {
      return MatiereNote(matiereId: '', matiereLibelle: '', notes: []);
    }

    // Extraire l'ID depuis matiereEcole.id ou matiereId
    String? extractedMatiereId;
    MatiereEcole? matiereEcole;

    if (keyJson['matiereEcole'] != null) {
      matiereEcole = MatiereEcole.fromJson(keyJson['matiereEcole'] as Map<String, dynamic>);
      extractedMatiereId = matiereEcole.id.toString();
    } else if (keyJson['id'] != null) { // Assuming 'id' at key level is the matiereId
      extractedMatiereId = keyJson['id'].toString();
    } else if (keyJson['matiereId'] != null) { // Fallback if matiereId is directly present
      extractedMatiereId = keyJson['matiereId'].toString();
    }

    return MatiereNote(
      matiereId: extractedMatiereId ?? '',
      matiereLibelle: keyJson['libelle'] as String? ?? '',
      moyenne: _parseDouble(keyJson['moyenne']),
      coef: _parseDouble(keyJson['coef']),
      moyenneCoef: _parseDouble(keyJson['moyenneCoef']),
      appreciation: keyJson['appreciation'] as String?,
      rang: _parseInt(keyJson['rang']),
      notes: valueList
              ?.map((n) => NoteDetail.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      matiereEcole: matiereEcole,
    );
  }
}

/// Modèle représentant l'objet matiereEcole
class MatiereEcole {
  final int id;

  MatiereEcole({
    required this.id,
  });

  factory MatiereEcole.fromJson(Map<String, dynamic> json) {
    return MatiereEcole(
      id: _parseInt(json['id']) ?? 0,
    );
  }
}

/// Modèle représentant une note détaillée
class NoteDetail {
  final int? id;
  final int? evaluationId;
  final int? evaluationNumero;
  final String? evaluationType;
  final double? note;
  final double? noteSur;
  final bool? isTestLourd;
  final String? dateNote;
  final Evaluation? evaluation; // Objet evaluation contenant les informations

  NoteDetail({
    this.id,
    this.evaluationId,
    this.evaluationNumero,
    this.evaluationType,
    this.note,
    this.noteSur,
    this.isTestLourd,
    this.dateNote,
    this.evaluation,
  });

  factory NoteDetail.fromJson(Map<String, dynamic> json) {
    // Extraire les informations depuis l'objet evaluation si présent
    Evaluation? evaluation;
    if (json['evaluation'] != null) {
      evaluation = Evaluation.fromJson(json['evaluation'] as Map<String, dynamic>);
    }

    return NoteDetail(
      id: _parseInt(json['id']),
      evaluationId: _parseInt(json['evaluationId']) ?? evaluation?.id,
      evaluationNumero: _parseInt(json['evaluationNumero']) ?? evaluation?.numero,
      evaluationType: json['evaluationType'] as String? ?? evaluation?.type?.libelle, // Use type.libelle from evaluation
      note: _parseDouble(json['note']),
      noteSur: _parseDouble(json['noteSur']) ?? _parseDouble(evaluation?.noteSur), // noteSur can be string
      isTestLourd: json['isTestLourd'] as bool? ?? false,
      dateNote: json['dateNote'] as String? ?? evaluation?.date, // Use evaluation.date
      evaluation: evaluation,
    );
  }
}

/// Modèle représentant l'objet evaluation
class Evaluation {
  final int? id;
  final int? numero;
  final TypeEvaluation? type; // Type d'évaluation
  final String? date; // Date de l'évaluation
  final String? noteSur; // Note sur (peut être string)

  Evaluation({
    this.id,
    this.numero,
    this.type,
    this.date,
    this.noteSur,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: _parseInt(json['id']),
      numero: _parseInt(json['numero']),
      type: json['type'] != null ? TypeEvaluation.fromJson(json['type'] as Map<String, dynamic>) : null,
      date: json['date'] as String?,
      noteSur: json['noteSur']?.toString(), // Can be string
    );
  }
}

/// Modèle représentant le type d'évaluation
class TypeEvaluation {
  final int? id;
  final String? libelle;

  TypeEvaluation({this.id, this.libelle});

  factory TypeEvaluation.fromJson(Map<String, dynamic> json) {
    return TypeEvaluation(
      id: _parseInt(json['id']),
      libelle: json['libelle'] as String?,
    );
  }
}
