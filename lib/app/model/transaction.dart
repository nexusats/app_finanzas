class Transaction {

  final int? id;
  final int? createdBy;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description;
  final String? source;
  final int? categoryId;
  final int? goalId;
  final String? goal;


  Transaction({
    this.id,
    this.createdBy,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.source,
    this.categoryId,
    this.goalId,
    this.goal
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      createdBy: json['createdBy'],
      type: TransactionTypeExtension.fromString(json['type']), // Mejora la conversión
      amount: (json['amount'] as num).toDouble(), // Asegura que sea double
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      description: json['description'] ?? '', // Evita posibles errores con valores nulos
      source: json['source'] ?? '',
      categoryId: json['categoryId'],
      goalId: json['goalId'],
      goal: json['goal'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdBy': createdBy,
      'type': type.toShortString(), // Guarda solo el nombre sin "TransactionType."
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'source': source,
      'categoryId': categoryId,
      'goalId': goalId,
      'goal': goal
    };
  }
}

// Enum de tipos de transacción
enum TransactionType { I, E, A }  // I: Ingreso, E: Egreso, A: Ahorro

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
