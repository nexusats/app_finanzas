class Transaction {
  final int? id;
  final int? createdBy;
  final TransactionType type;
  final double amount;
  final double? totalDebt;
  final DateTime date;
  final String? description;
  final String? source;
  final int? categoryId;
  final int? goalId;
  final String? goal;
  final int? statusId;
  final int? partnerId;

  Transaction(
      {this.id,
      this.createdBy,
      required this.type,
      required this.amount,
      this.totalDebt,
      required this.date,
      this.description,
      this.source,
      this.categoryId,
      this.goalId,
      this.goal,
      this.statusId,
      this.partnerId});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      createdBy: json['createdBy'],
      type: TransactionTypeExtension.fromString(
          json['type']), // Mejora la conversión
      amount: (json['amount'] as num).toDouble(), // Asegura que sea double
      totalDebt: (json['total_debt'] as num).toDouble(), // Asegura que sea double
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description:
          json['description'] ?? '', // Evita posibles errores con valores nulos
      source: json['source'] ?? '',
      categoryId: json['categoryId'],
      goalId: json['goalId'],
      goal: json['goal'] ?? '',
      statusId: json['status_id'] ?? 0,
      partnerId: json['partner_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created_by': createdBy,
      'type': type.toShortString(),
      'amount': amount,
      'total_debt': totalDebt,
      'date': date.toIso8601String(),
      'description': description,
      'source': source,
      'partner_id': partnerId,
      'category': categoryId,
      'goal_id': goalId,
      'goal': goal,
      'status_id': statusId
    };
  }
}

// Enum de tipos de transacción
enum TransactionType { I, E, A } // I: Ingreso, E: Egreso, A: Ahorro

// Extensión para manejar conversiones seguras
extension TransactionTypeExtension on TransactionType {
  String toShortString() {
    return toString().split('.').last; // Guarda solo "income" o "expense"
  }

  static TransactionType fromString(String? value) {
    return TransactionType.values.firstWhere(
      (e) => e.toShortString() == value,
      orElse: () => TransactionType.I, // Valor por defecto en caso de error
    );
  }
}
