class Goal {
  
  final int id;
  final String name;
  final double amount;
  final String description;
  final DateTime date;

  Goal({
    required this.id,
    required this.name,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sin nombre', // Evita posibles errores con valores nulos
      amount: (json['amount'] as num).toDouble(), // Evita posibles errores con valores nulos
      description: json['description'] ?? 'Sin descripción', // Evita posibles errores con valores nulos
      date: DateTime.parse(json['date'] ?? DateTime.now().toString()), // Evita posibles errores con valores nulos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
