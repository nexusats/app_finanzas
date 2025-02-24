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
  Transaction? _selectedTransaction;

  Transaction? get selectedTransaction => _selectedTransaction;
  List<Transaction> get transactions => List.unmodifiable(_transactions); // Protección de datos

  TransactionsProvider() {
    _loadTransactions();
  }

  /// 🏦 Cálculo de ingresos
  double getTotalIncomes() => _transactions
      .where((t) => t.type == TransactionType.I)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// 📉 Cálculo de egresos
  double getTotalExpenses() => _transactions
      .where((t) => t.type == TransactionType.E)
      .fold(0.0, (sum, t) => sum + t.amount);

  /// 💰 Balance final
  double getBalance() => getTotalIncomes() - getTotalExpenses();

  /// 📦 Carga inicial de transacciones
  Future<void> _loadTransactions() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    try {
      final fetchedTransactions = await _transactionService.getTransactions();
      _transactions
        ..clear()
        ..addAll(fetchedTransactions.map((e) => Transaction.fromJson(e as Map<String, dynamic>)));

      await _saveTransactions(); // Guarda en cache tras la carga exitosa
    } catch (_) {
      final storedTransactions = _prefs?.getStringList("_transactions");
      if (storedTransactions != null) {
        _transactions
          ..clear()
          ..addAll(storedTransactions.map((json) => Transaction.fromJson(jsonDecode(json))));
      }
    }
    notifyListeners();
  }

  /// 🔍 Obtiene una transacción por ID
  Future<void> fetchTransactionById(int id) async {
    if (_selectedTransaction?.id == id) return; // Evita llamadas innecesarias

    try {
      final data = await _transactionService.getTransactionById(id);
      _selectedTransaction = data != null ? Transaction.fromJson(data) : null;
    } catch (_) {
      _selectedTransaction = null;
    } 
    notifyListeners();
  }

  /// 💾 Guarda transacciones en caché local
  Future<void> _saveTransactions() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(
      "_transactions",
      _transactions.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  /// ➕ Agrega una transacción
  Future<void> addTransaction(BuildContext context, Transaction transaction) async {
    try {
      final success = await _transactionService.createTransaction(transaction.toJson());
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

  /// ❌ Elimina una transacción
  Future<void> removeTransaction(BuildContext context, Transaction transaction) async {
    _transactions.remove(transaction);
    await _saveTransactions();
    notifyListeners();
    CustomSnackbar.show(context, "Transacción eliminada");
  }
}
