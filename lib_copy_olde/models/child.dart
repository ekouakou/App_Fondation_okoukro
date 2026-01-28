/// Modèle représentant un enfant (élève)
class Child {
  final String id;
  final String firstName;
  final String lastName;
  final String establishment;
  final String grade; // Classe
  final String? photoUrl;
  final String parentId;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.establishment,
    required this.grade,
    this.photoUrl,
    required this.parentId,
  });

  String get fullName => '$firstName $lastName';

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      establishment: json['establishment'] as String,
      grade: json['grade'] as String,
      photoUrl: json['photoUrl'] as String?,
      parentId: json['parentId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'establishment': establishment,
      'grade': grade,
      'photoUrl': photoUrl,
      'parentId': parentId,
    };
  }
}

