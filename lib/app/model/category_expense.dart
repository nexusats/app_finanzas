class CategoryExpense {
  final int? id;
  final String name;
  final String? type;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  CategoryExpense({
    this.id,
    required this.name,
    this.type,
    this.icon,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) =>
      CategoryExpense(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        icon: json['icon'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'icon': icon,
      };
}
