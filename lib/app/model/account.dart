import 'package:app_finanzas/app/model/sync_status.dart';

class Account {
  final int? id;
  final int? userId;

  final String name;

  /// Del AccountController (store/update)
  final double? initialBalance;

  /// Del getData / list (según tu API)
  final double? currentBalance;
  final String? currentBalanceFormatted;

  final bool? isArchived;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  Account({
    this.id,
    this.userId,
    required this.name,
    this.initialBalance,
    this.currentBalance,
    this.currentBalanceFormatted,
    this.isArchived,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool? _toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return (s == '1' || s == 'true');
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return Account(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      name: (json['name'] ?? '').toString(),
      initialBalance: _toDouble(json['initial_balance']),
      currentBalance: _toDouble(json['current_balance']),
      currentBalanceFormatted: json['current_balance_formatted']?.toString(),
      isArchived: _toBool(json['is_archived']),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
      syncStatus: syncStatusFromString(json['sync_status']?.toString()),
    );
  }

  /// Para POST/PUT del AccountController:
  /// - name (required)
  /// - initial_balance (required)
  /// - is_archived (optional en update)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (isArchived != null) 'is_archived': isArchived,
    };
  }

  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'current_balance_formatted': currentBalanceFormatted,
      'is_archived': isArchived,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatusToString(syncStatus),
    };
  }
}
