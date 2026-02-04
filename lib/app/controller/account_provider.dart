import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/account.dart';
import 'package:app_finanzas/app/services/account_service.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:app_finanzas/app/model/sync_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();

  final List<Account> _accounts = [];
  bool _isLoading = false;

  bool _loadedOnce = false;
  Future<void>? _inFlight;

  static const Duration _ttl = Duration(minutes: 10);
  DateTime? _lastFetchAt;

  List<Account> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;

  AccountProvider() {
    _warmFromLocal();
  }

  Future<void> _warmFromLocal() async {
    final cached = await LocalDatabase.getAccounts();
    _accounts
      ..clear()
      ..addAll(_visibleAccounts(cached));
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    await LocalDatabase.saveAccounts(_accounts);
  }

  bool _isFresh() {
    if (_lastFetchAt == null) return false;
    return DateTime.now().difference(_lastFetchAt!) < _ttl;
  }

  Future<void> fetchIfNeeded({bool force = false}) async {
    if (_inFlight != null) return _inFlight!;
    if (_loadedOnce && !force && _isFresh()) return;

    _inFlight = _fetchFromApi(forceLoadingUi: !_loadedOnce)
        .whenComplete(() => _inFlight = null);

    return _inFlight!;
  }

  Future<void> refresh() => fetchIfNeeded(force: true);

  Future<void> _fetchFromApi({required bool forceLoadingUi}) async {
    if (forceLoadingUi) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      if (!await _isOnline()) return;
      final response = await _accountService.getAccounts();

      // Lista vacía puede ser válida, no es “advertencia”
      _accounts
        ..clear()
        ..addAll(
          response
              .map((e) => Account.fromJson(e))
              .map(
                (account) => Account(
                  id: account.id,
                  userId: account.userId,
                  name: account.name,
                  initialBalance: account.initialBalance,
                  currentBalance: account.currentBalance,
                  currentBalanceFormatted: account.currentBalanceFormatted,
                  isArchived: account.isArchived,
                  createdAt: account.createdAt,
                  updatedAt: account.updatedAt,
                  syncStatus: SyncStatus.synced,
                ),
              )
              .toList(),
        );

      _loadedOnce = true;
      _lastFetchAt = DateTime.now();
      await _saveToLocal();
    } catch (_) {
      // Si falla, te quedas con local cache
    } finally {
      if (forceLoadingUi) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // -------- CRUD --------

  Future<bool> createAccount(Map<String, dynamic> accountData) async {
    if (await _isOnline()) {
      final ok = await _accountService.createAccount(accountData);
      if (ok) {
        await refresh();
      }
      return ok;
    }

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final account = Account(
      id: tempId,
      name: (accountData['name'] ?? '').toString(),
      initialBalance: accountData['initial_balance'] is num
          ? (accountData['initial_balance'] as num).toDouble()
          : double.tryParse(accountData['initial_balance']?.toString() ?? ''),
      isArchived: accountData['is_archived'] as bool?,
      syncStatus: SyncStatus.pendingCreate,
    );
    _accounts.add(account);
    await LocalDatabase.upsertAccount(account);
    notifyListeners();
    return true;
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> accountData) async {
    if (await _isOnline()) {
      final ok = await _accountService.updateAccount(id, accountData);
      if (ok) {
        await refresh();
      }
      return ok;
    }

    final index = _accounts.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = _accounts[index];
    final updated = Account(
      id: existing.id,
      userId: existing.userId,
      name: (accountData['name'] ?? existing.name).toString(),
      initialBalance: accountData['initial_balance'] is num
          ? (accountData['initial_balance'] as num).toDouble()
          : existing.initialBalance,
      currentBalance: existing.currentBalance,
      currentBalanceFormatted: existing.currentBalanceFormatted,
      isArchived: accountData['is_archived'] as bool? ?? existing.isArchived,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    _accounts[index] = updated;
    await LocalDatabase.upsertAccount(updated);
    notifyListeners();
    return true;
  }

  Future<void> removeAccount(Account account) async {
    // Optimista: quita local primero (UI rápida)
    _accounts.removeWhere((e) => e.id == account.id);
    notifyListeners();

    if (!await _isOnline()) {
      final pending = Account(
        id: account.id,
        userId: account.userId,
        name: account.name,
        initialBalance: account.initialBalance,
        currentBalance: account.currentBalance,
        currentBalanceFormatted: account.currentBalanceFormatted,
        isArchived: account.isArchived,
        createdAt: account.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingDelete,
      );
      await LocalDatabase.upsertAccount(pending);
      return;
    }

    if (account.id == null) return;
    final ok = await _accountService.deleteAccount(account.id!);
    if (!ok) {
      await refresh();
    } else {
      _lastFetchAt = DateTime.now();
      await LocalDatabase.removeAccount(account);
    }
  }

  Future<void> clear() async {
    _accounts.clear();
    _isLoading = false;
    _loadedOnce = false;
    _lastFetchAt = null;
    await LocalDatabase.saveAccounts([]);
    notifyListeners();
  }

  List<Account> _visibleAccounts(List<Account> accounts) {
    return accounts
        .where((account) => account.syncStatus != SyncStatus.pendingDelete)
        .toList();
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
