import 'package:app_finanzas/app/model/sync_status.dart';

class Category {
  final int? id;
  final String name;

  final String? type;
  final String? icon;
  final bool? isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  Category({
    this.id,
    required this.name,
    this.type,
    this.icon,
    this.isArchived,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int?,
        name: (json['name'] ?? '').toString(),
        type: json['type']?.toString(),
        icon: json['icon']?.toString(),
        isArchived: json['is_archived'] is bool
            ? json['is_archived'] as bool
            : (json['is_archived'] != null
                ? (json['is_archived'].toString() == '1' ||
                    json['is_archived'].toString().toLowerCase() == 'true')
                : null),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        syncStatus: syncStatusFromString(json['sync_status']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'icon': (icon != null && icon!.trim().isEmpty) ? null : icon,
      };

  Map<String, dynamic> toStorageJson() => {
        'id': id,
        'name': name,
        'type': type,
        'icon': (icon != null && icon!.trim().isEmpty) ? null : icon,
        'is_archived': isArchived,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'sync_status': syncStatusToString(syncStatus),
      };
}
