import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/transaction_service.dart';

class TransactionsProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  SharedPreferences? _prefs;
  final TransactionService _transactionService = TransactionService();

  TransactionsProvider() {
    _loadTransactions();
  }

  List<Transaction> get transactions => _transactions;

  double getTotalIncomes() => _transactions
      .where((transaction) => transaction.type == TransactionType.I)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double getTotalExpenses() => _transactions
      .where((transaction) => transaction.type == TransactionType.E)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double getBalance() => getTotalIncomes() - getTotalExpenses();

  Future<void> _loadTransactions() async {
    try {
      final fetchedTransactions = await _transactionService.getTransactions();
      _transactions.clear();
      _transactions.addAll(
          fetchedTransactions.map((json) => Transaction.fromJson(json)));
      await _saveTransactions();
    } catch (error) {
      _prefs ??= await SharedPreferences.getInstance();
      List<String>? storedTransactions = _prefs?.getStringList("_transactions");

      if (storedTransactions != null) {
        _transactions.clear();
        _transactions.addAll(storedTransactions
            .map((jsonString) => Transaction.fromJson(jsonDecode(jsonString))));
      }
    }
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList("_transactions",
        _transactions.map((transaction) => jsonEncode(transaction.toJson())).toList());
  }

  Future<void> addTransaction(BuildContext context, Transaction transaction) async {
    try {
      bool success = await _transactionService.createTransaction(transaction.toJson());

      if (success) {
        _transactions.add(transaction);
        await _saveTransactions();
        notifyListeners();
        CustomSnackbar.show(context, "Transacción agregada exitosamente");
      } else {
        CustomSnackbar.show(context, "Error al agregar la transacción", isError: true);
      }
    } catch (error) {
      CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
    }
  }

  Future<void> removeTransaction(BuildContext context, Transaction transaction) async {
    _transactions.remove(transaction);
    await _saveTransactions();
    notifyListeners();
    CustomSnackbar.show(context, "Transacción eliminada");
  }
}
