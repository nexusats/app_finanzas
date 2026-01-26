import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/account_service.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();
  static const String _storageKey = 'accounts';

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _accounts
          ..clear()
          ..addAll(decoded.map((e) => Account.fromJson(e)).toList());
      }
    } catch (_) {
      // ignore cache corrupto
    }

    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
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
      final response = await _accountService.getAccounts();

      // Lista vacía puede ser válida, no es “advertencia”
      _accounts
        ..clear()
        ..addAll(response.map((e) => Account.fromJson(e)).toList());

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
    final ok = await _accountService.createAccount(accountData);
    if (ok) {
      await refresh();
    }
    return ok;
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> accountData) async {
    final ok = await _accountService.updateAccount(id, accountData);
    if (ok) {
      await refresh();
    }
    return ok;
  }

  Future<void> removeAccount(Account account) async {
    // Optimista: quita local primero (UI rápida)
    _accounts.removeWhere((e) => e.id == account.id);
    notifyListeners();
    await _saveToLocal();

    final ok = await _accountService.deleteAccount(account.id!);
    if (!ok) {
      // si falla, re-sincroniza
      await refresh();
    } else {
      _lastFetchAt = DateTime.now();
    }
  }

  Future<void> clear() async {
    _accounts.clear();
    _isLoading = false;
    _loadedOnce = false;
    _lastFetchAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    notifyListeners();
  }
}
