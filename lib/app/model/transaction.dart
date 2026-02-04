import 'package:app_finanzas/app/model/sync_status.dart';

class Transaction {
  final int? id;
  final int? userId;

  /// income | expense
  final String type;

  final double amount;
  final DateTime date;

  final String? note;

  /// FK requeridos por API
  final int accountId;
  final int categoryId;

  /// Datos incluidos por el backend (with account/category)
  final AccountMini? account;
  final CategoryMini? category;

  /// Adjuntos (si los estás retornando)
  final List<TransactionAttachment> attachments;
  final SyncStatus syncStatus;

  Transaction({
    this.id,
    this.userId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    required this.accountId,
    required this.categoryId,
    this.account,
    this.category,
    this.attachments = const [],
    this.syncStatus = SyncStatus.synced,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // amount puede venir como string/num
    final amount = double.tryParse(json['amount']?.toString() ?? '') ?? 0.0;

    // date normalmente viene "YYYY-MM-DD" o ISO
    final dateStr = json['date']?.toString();
    final parsedDate = (dateStr != null && dateStr.isNotEmpty)
        ? DateTime.tryParse(dateStr) ?? DateTime.now()
        : DateTime.now();

    // account/category pueden venir como objeto
    final accountJson = json['account'];
    final categoryJson = json['category'];

    // attachments puede venir como lista
    final atts = (json['attachments'] is List)
        ? (json['attachments'] as List)
            .whereType<Map<String, dynamic>>()
            .map(TransactionAttachment.fromJson)
            .toList()
        : <TransactionAttachment>[];

    return Transaction(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      type: (json['type'] ?? '').toString(),
      amount: amount,
      date: parsedDate,
      note: json['note']?.toString(),
      accountId: int.tryParse(json['account_id']?.toString() ?? '') ?? 0,
      categoryId: int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
      account: accountJson is Map<String, dynamic>
          ? AccountMini.fromJson(accountJson)
          : null,
      category: categoryJson is Map<String, dynamic>
          ? CategoryMini.fromJson(categoryJson)
          : null,
      attachments: atts,
      syncStatus: syncStatusFromString(json['sync_status']?.toString()),
    );
  }

  /// Para POST/PUT según tu API:
  /// amount, type, category_id, account_id, date, note (opc)
  /// attachment_ids (si lo manejas) lo mandas desde el provider, no desde el modelo.
  Map<String, dynamic> toJson() {
    return {
      if (id != null && id! > 0) "id": id,
      "type": type,
      "amount": amount,
      "account_id": accountId,
      "category_id": categoryId,
      "date": _toApiDate(date), // "YYYY-MM-DD"
      "note": note,
    };
  }

  Map<String, dynamic> toStorageJson() {
    return {
      "id": id,
      "user_id": userId,
      "type": type,
      "amount": amount,
      "account_id": accountId,
      "category_id": categoryId,
      "date": date.toIso8601String(),
      "note": note,
      "account": account != null
          ? {"id": account!.id, "name": account!.name}
          : null,
      "category": category != null
          ? {
              "id": category!.id,
              "name": category!.name,
              "type": category!.type,
            }
          : null,
      "attachments": attachments
          .map((a) => {"id": a.id, "path": a.path})
          .toList(),
      "sync_status": syncStatusToString(syncStatus),
    };
  }

  static String _toApiDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }
}

/// Minis para relaciones (lo que tu API retorna: id, name, type)
class AccountMini {
  final int id;
  final String name;

  AccountMini({required this.id, required this.name});

  factory AccountMini.fromJson(Map<String, dynamic> json) {
    return AccountMini(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class CategoryMini {
  final int id;
  final String name;
  final String type; // income | expense

  CategoryMini({required this.id, required this.name, required this.type});

  factory CategoryMini.fromJson(Map<String, dynamic> json) {
    return CategoryMini(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
    );
  }
}

class TransactionAttachment {
  final int id;
  final String path;

  TransactionAttachment({required this.id, required this.path});

  factory TransactionAttachment.fromJson(Map<String, dynamic> json) {
    return TransactionAttachment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      path: (json['path'] ?? '').toString(),
    );
  }
}
