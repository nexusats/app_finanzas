class CategoryExpense {
  
  final String nameCategory;

  CategoryExpense({
    required this.nameCategory,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) {
    return CategoryExpense(
      nameCategory: json['nameCategory'] ?? 'Sin nombre', // Evita posibles errores con valores nulos
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nameCategory': nameCategory,
    };
  }
}
