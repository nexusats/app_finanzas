class Transaction {
  final int? id;
  final int? createdBy;
  final String type; // income, expense, saving, debt_in, debt_on
  final double amount;
  final double? totalDebt;
  final DateTime date;

  final String? note; // reemplaza description
  final int? categoryId; // para expense
  final int? goalId; // para saving / debt
  final int statusId;

  final bool isRecurring;
  final int? recurringIntervalDays;
  final List<String> files;

  Transaction({
    this.id,
    this.createdBy,
    required this.type,
    required this.amount,
    this.totalDebt,
    required this.date,
    this.note,
    this.categoryId,
    this.goalId,
    required this.statusId,
    this.isRecurring = false,
    this.recurringIntervalDays,
    this.files = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      createdBy: json['created_by'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      totalDebt: json['total_debt'] != null
          ? (json['total_debt'] as num).toDouble()
          : null,
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      note: json['note'],
      categoryId: json['category_id'],
      goalId: json['goal_id'],
      statusId: json['status_id'] ?? 1,
      isRecurring: json['is_recurring'] == true,
      recurringIntervalDays: json['recurring_interval_days'],
      files: json['files'] != null ? List<String>.from(json['files']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "created_by": createdBy,
      "type": type,
      "amount": amount,
      "total_debt": totalDebt,
      "date": date.toIso8601String(),
      "note": note,
      "category_id": categoryId,
      "goal_id": goalId,
      "status_id": statusId,
      "is_recurring": isRecurring,
      "recurring_interval_days": recurringIntervalDays,
    };
  }
}
