// Import nécessaire pour TimeOfDay
import 'package:flutter/material.dart';

/// Modèle représentant une entrée d'emploi du temps
class TimetableEntry {
  final String id;
  final String childId;
  final String dayOfWeek; // Jour de la semaine
  final TimeOfDay startTime; // Heure de début
  final TimeOfDay endTime; // Heure de fin
  final String subject; // Matière
  final String? room; // Salle
  final String? teacher; // Professeur

  TimetableEntry({
    required this.id,
    required this.childId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room,
    this.teacher,
  });

  String get timeRange => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');
    
    return TimetableEntry(
      id: json['id'] as String,
      childId: json['childId'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      subject: json['subject'] as String,
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'dayOfWeek': dayOfWeek,
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'subject': subject,
      'room': room,
      'teacher': teacher,
    };
  }
}

