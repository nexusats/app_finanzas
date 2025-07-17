class CategoryExpense {
  final int? id;
  final String nameCategory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  CategoryExpense({
    this.id,
    required this.nameCategory,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) => CategoryExpense(
        id: json['id'],
        nameCategory: json['name'],
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': nameCategory,
      };
}