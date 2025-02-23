class Goal {
  
  final String nameGoal;
  final double amount;

  Goal({
    required this.nameGoal,
    required this.amount,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      nameGoal: json['nameGoal'] ?? 'Sin nombre', // Evita posibles errores con valores nulos
      amount: json['amount'] ?? 0.0, // Evita posibles errores con valores nulos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nameGoal': nameGoal,
      'amount': amount,
    };
  }
}
