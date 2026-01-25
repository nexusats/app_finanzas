import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/account_service.dart';

class AccountProvider with ChangeNotifier {
  final AccountService _accountService = AccountService();
  final String _storageKey = 'accounts';

  List<Account> _accounts = [];
  bool _isLoading = true;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;

  AccountProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _loadAccountsFromLocal();
    fetchFromApiAndUpdateLocal();
  }

  Future<void> _loadAccountsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      try {
        final decoded = jsonDecode(data);
        _accounts = (decoded as List).map((e) => Account.fromJson(e)).toList();
      } catch (_) {
        _accounts = [];
      }
    } else {
      _accounts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAccountsToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> fetchFromApiAndUpdateLocal() async {
    try {
      final response = await _accountService.getAccounts();

      if (response.isNotEmpty) {
        _accounts = response.map((e) => Account.fromJson(e)).toList();
        await _saveAccountsToLocal();
        notifyListeners();
      } else {
        debugPrint("Advertencia: API retornó lista vacía");
      }
    } catch (e) {
      debugPrint("Error al cargar cuentas desde API: $e. Usando caché...");
    }
  }

  Future<void> reloadAccountsFromLocalStorage() async {
    _isLoading = true;
    notifyListeners();
    await _loadAccountsFromLocal();
  }

  Future<bool> createAccount(Map<String, dynamic> accountData) async {
    final success = await _accountService.createAccount(accountData);
    if (success) {
      await fetchFromApiAndUpdateLocal();
    }
    return success;
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> accountData) async {
    final success = await _accountService.updateAccount(id, accountData);
    if (success) {
      await fetchFromApiAndUpdateLocal();
    }
    return success;
  }

  Future<void> removeAccount(Account account) async {
    final success = await _accountService.deleteAccount(account.id!);
    if (success) {
      _accounts.removeWhere((e) => e.id == account.id);
      await _saveAccountsToLocal();
      notifyListeners();
    }
  }

  void clear() {
    _accounts = [];
    _isLoading = true;
    notifyListeners();
  }
}
