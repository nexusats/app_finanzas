import 'package:app_finanzas/app/model/account.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/app/model/sync_status.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabase {
  static const String _accountsBoxName = 'accounts_box';
  static const String _categoriesBoxName = 'categories_box';
  static const String _transactionsBoxName = 'transactions_box';
  static const String _metaBoxName = 'meta_box';
  static const String _lastSyncKey = 'last_sync';

  static Box<Map>? _accountsBox;
  static Box<Map>? _categoriesBox;
  static Box<Map>? _transactionsBox;
  static Box? _metaBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _accountsBox ??= await Hive.openBox<Map>(_accountsBoxName);
    _categoriesBox ??= await Hive.openBox<Map>(_categoriesBoxName);
    _transactionsBox ??= await Hive.openBox<Map>(_transactionsBoxName);
    _metaBox ??= await Hive.openBox(_metaBoxName);
  }

  static Future<List<Account>> getAccounts() async {
    final values = _accountsBox?.values ?? [];
    return values
        .map((value) =>
            Account.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  static Future<void> upsertAccount(Account account) async {
    await _accountsBox?.put(
      _key(account.id),
      account.toStorageJson(),
    );
  }

  static Future<void> saveAccounts(List<Account> accounts) async {
    await _accountsBox?.clear();
    final map = {
      for (final account in accounts) _key(account.id): account.toStorageJson(),
    };
    await _accountsBox?.putAll(map);
  }

  static Future<List<Account>> getPendingAccounts() async {
    final values = await getAccounts();
    return values
        .where((account) => account.syncStatus != SyncStatus.synced)
        .toList();
  }

  static Future<void> removeAccount(Account account) async {
    await _accountsBox?.delete(_key(account.id));
  }

  static Future<List<Category>> getCategories() async {
    final values = _categoriesBox?.values ?? [];
    return values
        .map((value) =>
            Category.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  static Future<void> upsertCategory(Category category) async {
    await _categoriesBox?.put(
      _key(category.id),
      category.toStorageJson(),
    );
  }

  static Future<void> saveCategories(List<Category> categories) async {
    await _categoriesBox?.clear();
    final map = {
      for (final category in categories) _key(category.id): category.toStorageJson(),
    };
    await _categoriesBox?.putAll(map);
  }

  static Future<List<Category>> getPendingCategories() async {
    final values = await getCategories();
    return values
        .where((category) => category.syncStatus != SyncStatus.synced)
        .toList();
  }

  static Future<void> removeCategory(Category category) async {
    await _categoriesBox?.delete(_key(category.id));
  }

  static Future<List<Transaction>> getTransactions() async {
    final values = _transactionsBox?.values ?? [];
    return values
        .map((value) =>
            Transaction.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  static Future<void> upsertTransaction(Transaction transaction) async {
    await _transactionsBox?.put(
      _key(transaction.id),
      transaction.toStorageJson(),
    );
  }

  static Future<void> saveTransactions(List<Transaction> transactions) async {
    await _transactionsBox?.clear();
    final map = {
      for (final transaction in transactions)
        _key(transaction.id): transaction.toStorageJson(),
    };
    await _transactionsBox?.putAll(map);
  }

  static Future<List<Transaction>> getPendingTransactions() async {
    final values = await getTransactions();
    return values
        .where((transaction) => transaction.syncStatus != SyncStatus.synced)
        .toList();
  }

  static Future<void> removeTransaction(Transaction transaction) async {
    await _transactionsBox?.delete(_key(transaction.id));
  }

  static DateTime? getLastSyncAt() {
    final value = _metaBox?.get(_lastSyncKey);
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static Future<void> setLastSyncAt(DateTime value) async {
    await _metaBox?.put(_lastSyncKey, value.toIso8601String());
  }

  static String _key(int? id) => (id ?? DateTime.now().millisecondsSinceEpoch)
      .toString();
}
