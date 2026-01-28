/// Modèle représentant une notification
class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType? type;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.type,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] != null
          ? NotificationType.fromString(json['type'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type?.toString(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}

/// Types de notifications
enum NotificationType {
  noteAdded,
  noteUpdated,
  messageReceived,
  feeAdded,
  timetableUpdated,
  general;

  static NotificationType? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'note_added':
      case 'noteadded':
        return NotificationType.noteAdded;
      case 'note_updated':
      case 'noteupdated':
        return NotificationType.noteUpdated;
      case 'message_received':
      case 'messagereceived':
        return NotificationType.messageReceived;
      case 'fee_added':
      case 'feeadded':
        return NotificationType.feeAdded;
      case 'timetable_updated':
      case 'timetableupdated':
        return NotificationType.timetableUpdated;
      default:
        return NotificationType.general;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.noteAdded:
        return 'Nouvelle note';
      case NotificationType.noteUpdated:
        return 'Note mise à jour';
      case NotificationType.messageReceived:
        return 'Nouveau message';
      case NotificationType.feeAdded:
        return 'Nouvelle facture';
      case NotificationType.timetableUpdated:
        return 'Emploi du temps mis à jour';
      case NotificationType.general:
        return 'Notification';
    }
  }
}

