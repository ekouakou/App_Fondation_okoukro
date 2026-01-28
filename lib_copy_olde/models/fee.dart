/// Modèle représentant des frais de scolarité
class Fee {
  final String id;
  final String childId;
  final String type; // Type de frais (Inscription, Réinscription, Scolarité, etc.)
  final double amount; // Montant
  final DateTime dueDate; // Date d'échéance
  final DateTime? paidDate; // Date de paiement
  final bool isPaid; // Statut de paiement
  final String? paymentMethod; // Méthode de paiement
  final String? reference; // Référence de paiement

  Fee({
    required this.id,
    required this.childId,
    required this.type,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.isPaid,
    this.paymentMethod,
    this.reference,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as String,
      childId: json['childId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidDate: json['paidDate'] != null 
          ? DateTime.parse(json['paidDate'] as String) 
          : null,
      isPaid: json['isPaid'] as bool,
      paymentMethod: json['paymentMethod'] as String?,
      reference: json['reference'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'type': type,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'reference': reference,
    };
  }
}

