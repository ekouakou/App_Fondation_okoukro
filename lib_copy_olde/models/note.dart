/// Modèle représentant une note
class Note {
  final String id;
  final String childId;
  final String subject; // Matière
  final double grade; // Note
  final double coefficient;
  final DateTime date;
  final String assignmentNumber; // N°Dev
  final double? average; // Moyenne de la matière
  final int? rank; // Rang
  final int? totalStudents; // Effectif
  final String? mention; // Mention (Très Bien, Bien, Assez Bien, etc.)
  final double? noteSur; // Note sur (depuis evaluation.noteSur)

  Note({
    required this.id,
    required this.childId,
    required this.subject,
    required this.grade,
    required this.coefficient,
    required this.date,
    required this.assignmentNumber,
    this.average,
    this.rank,
    this.totalStudents,
    this.mention,
    this.noteSur,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      childId: json['childId'] as String,
      subject: json['subject'] as String,
      grade: (json['grade'] as num).toDouble(),
      coefficient: (json['coefficient'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      assignmentNumber: json['assignmentNumber'] as String,
      average: json['average'] != null ? (json['average'] as num).toDouble() : null,
      rank: json['rank'] as int?,
      totalStudents: json['totalStudents'] as int?,
      mention: json['mention'] as String?,
      noteSur: json['noteSur'] != null ? (json['noteSur'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'subject': subject,
      'grade': grade,
      'coefficient': coefficient,
      'date': date.toIso8601String(),
      'assignmentNumber': assignmentNumber,
      'average': average,
      'rank': rank,
      'totalStudents': totalStudents,
      'mention': mention,
      'noteSur': noteSur,
    };
  }
}

/// Modèle pour les moyennes par matière
class SubjectAverage {
  final String subject;
  final List<Note> notes;
  final double average;
  final double coefficient;
  final double weightedAverage;
  final int? rank;
  final int? totalStudents;
  final bool viewed;

  SubjectAverage({
    required this.subject,
    required this.notes,
    required this.average,
    required this.coefficient,
    required this.weightedAverage,
    this.rank,
    this.totalStudents,
    this.viewed = false,
  });
}

/// Modèle pour les moyennes globales
class GlobalAverage {
  final double trimesterAverage;
  final int trimesterRank;
  final String trimesterMention;
  final double annualAverage;
  final int annualRank;
  final String annualMention;

  GlobalAverage({
    required this.trimesterAverage,
    required this.trimesterRank,
    required this.trimesterMention,
    required this.annualAverage,
    required this.annualRank,
    required this.annualMention,
  });
}

