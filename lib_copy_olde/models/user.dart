/// Modèle représentant un utilisateur (parent)
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final int smsCredits;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.smsCredits = 0,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      smsCredits: json['smsCredits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'smsCredits': smsCredits,
    };
  }

  /// Crée une copie de l'utilisateur avec des crédits SMS modifiés
  User copyWith({int? smsCredits}) {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      smsCredits: smsCredits ?? this.smsCredits,
    );
  }
}

