import 'note.dart';

/// Modèle représentant une note depuis l'API Pouls Scolaire
class NoteApi {
  final int? id;
  final String? matriculeEleve;
  final String? nomEleve;
  final String? prenomEleve;
  final int? matiereId;
  final String? matiereLibelle;
  final double? note;
  final double? coef;
  final String? dateNote;
  final int? numeroDevoir;
  final double? moyenne;
  final int? rang;
  final int? effectif;
  final String? appreciation;
  final int? periodeId;
  final String? periodeLibelle;
  final double? noteSur; // Note sur (depuis evaluation.noteSur)

  NoteApi({
    this.id,
    this.matriculeEleve,
    this.nomEleve,
    this.prenomEleve,
    this.matiereId,
    this.matiereLibelle,
    this.note,
    this.coef,
    this.dateNote,
    this.numeroDevoir,
    this.moyenne,
    this.rang,
    this.effectif,
    this.appreciation,
    this.periodeId,
    this.periodeLibelle,
    this.noteSur,
  });

  factory NoteApi.fromJson(Map<String, dynamic> json) {
    return NoteApi(
      id: json['id'] as int?,
      matriculeEleve: json['matriculeEleve'] as String?,
      nomEleve: json['nomEleve'] as String?,
      prenomEleve: json['prenomEleve'] as String?,
      matiereId: json['matiereId'] as int?,
      matiereLibelle: json['matiereLibelle'] as String?,
      note: json['note'] != null ? (json['note'] as num).toDouble() : null,
      coef: json['coef'] != null ? (json['coef'] as num).toDouble() : null,
      dateNote: json['dateNote'] as String?,
      numeroDevoir: json['numeroDevoir'] as int?,
      moyenne: json['moyenne'] != null ? (json['moyenne'] as num).toDouble() : null,
      rang: json['rang'] as int?,
      effectif: json['effectif'] as int?,
      appreciation: json['appreciation'] as String?,
      periodeId: json['periodeId'] as int?,
      periodeLibelle: json['periodeLibelle'] as String?,
      noteSur: json['noteSur'] != null ? (json['noteSur'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matriculeEleve': matriculeEleve,
      'nomEleve': nomEleve,
      'prenomEleve': prenomEleve,
      'matiereId': matiereId,
      'matiereLibelle': matiereLibelle,
      'note': note,
      'coef': coef,
      'dateNote': dateNote,
      'numeroDevoir': numeroDevoir,
      'moyenne': moyenne,
      'rang': rang,
      'effectif': effectif,
      'appreciation': appreciation,
      'periodeId': periodeId,
      'periodeLibelle': periodeLibelle,
      'noteSur': noteSur,
    };
  }

  /// Parse une date qui peut avoir différents formats
  static DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    
    try {
      // Essayer de parser le format standard ISO 8601
      return DateTime.parse(dateString);
    } catch (e) {
      // Si le format standard échoue, essayer de nettoyer le format
      try {
        // Enlever [UTC] ou autres suffixes non standard
        String cleanedDate = dateString;
        if (cleanedDate.contains('[')) {
          cleanedDate = cleanedDate.substring(0, cleanedDate.indexOf('['));
        }
        // Enlever les espaces en fin
        cleanedDate = cleanedDate.trim();
        return DateTime.parse(cleanedDate);
      } catch (e2) {
        print('⚠️ Erreur lors du parsing de la date: $dateString');
        return null;
      }
    }
  }

  /// Convertit en Note pour compatibilité avec l'existant
  Note toNote(String childId) {
    final parsedDate = parseDate(dateNote);
    return Note(
      id: id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      childId: childId,
      subject: matiereLibelle ?? '',
      grade: note ?? 0.0,
      coefficient: coef ?? 1.0,
      date: parsedDate ?? DateTime.now(),
      assignmentNumber: numeroDevoir?.toString() ?? '1',
      average: moyenne,
      rank: rang,
      totalStudents: effectif,
      mention: appreciation,
      noteSur: noteSur,
    );
  }
}

