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
  bool _isLoading = true;

  Transaction? get selectedTransaction => _selectedTransaction;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  TransactionsProvider() {
    _loadTransactions();
  }

  // ----------------------
  //   MÉTODOS DE CÁLCULO
  // ----------------------

  double getTotalSavings() => _transactions
      .where((t) => t.type == "saving")
      .fold(0.0, (sum, t) => sum + t.amount);

  double getTotalIncomes() => _transactions
      .where((t) => t.type == "income")
      .fold(0.0, (sum, t) => sum + t.amount);

  double getTotalExpenses() => _transactions
      .where((t) => t.type == "expense")
      .fold(0.0, (sum, t) => sum + t.amount);

  double getTotalDebt() => _transactions
      .where((t) => t.type == "expense")
      .fold(0.0, (sum, t) => sum + t.amount);

  double getBalance() => getTotalIncomes() - getTotalExpenses();

  double getTotalByType(String type) => _transactions
      .where((t) => t.type == type)
      .fold(0.0, (sum, t) => sum + t.amount);

  List<Transaction> getTransactionsByType(
    String type, {
    List<int> statusIds = const [8, 9],
  }) {
    return _transactions.toList();
  }

  // ----------------------
  //   FETCH GENERAL
  // ----------------------

  Future<void> fetchTransactions() async {
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();

    try {
      final fetchedTransactions = await _transactionService.getTransactions();

      _transactions
        ..clear()
        ..addAll(fetchedTransactions.map(
          (e) => Transaction.fromJson(e as Map<String, dynamic>),
        ));

      await _saveTransactions();
    } catch (_) {
      final storedTransactions = _prefs?.getStringList("_transactions");
      if (storedTransactions != null) {
        _transactions
          ..clear()
          ..addAll(
            storedTransactions.map(
              (json) => Transaction.fromJson(jsonDecode(json)),
            ),
          );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // ----------------------
  //   FETCH POR ID
  // ----------------------

  Future<void> fetchTransactionById(int id) async {
    if (_selectedTransaction?.id == id) return;

    try {
      final data = await _transactionService.getTransactionById(id);
      _selectedTransaction = data != null ? Transaction.fromJson(data) : null;
    } catch (_) {
      _selectedTransaction = null;
    }

    notifyListeners();
  }

  // ----------------------
  //   GUARDAR LOCALMENTE
  // ----------------------

  Future<void> _saveTransactions() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(
      "_transactions",
      _transactions.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  // ----------------------
  //   AGREGAR
  // ----------------------

  Future<void> addTransaction(
      BuildContext context, Transaction transaction) async {
    try {
      final success =
          await _transactionService.createTransaction(transaction.toJson());

      if (success) {
        _transactions.add(transaction);
        await _saveTransactions();
        notifyListeners();

        if (context.mounted) {
          CustomSnackbar.show(context, "Transacción agregada exitosamente");
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(context, "Error al agregar la transacción",
              isError: true);
        }
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error de conexión: $error",
            isError: true);
      }
    }
  }

  // ----------------------
  //   ACTUALIZAR
  // ----------------------

  Future<void> updateTransaction(
      BuildContext context, Transaction updatedTransaction) async {
    try {
      final success = await _transactionService.updateTransaction(
        updatedTransaction.id!,
        updatedTransaction.toJson(),
      );

      if (success) {
        print("entro");
        final index =
            _transactions.indexWhere((t) => t.id == updatedTransaction.id);

        print("index: $index");
        if (index != -1) {
          print("entro2");
          _transactions[index] = updatedTransaction;
          _selectedTransaction = updatedTransaction;

          await _saveTransactions();
          notifyListeners();

          if (context.mounted) {
            CustomSnackbar.show(context, "Transacción actualizada");
          } else {
            CustomSnackbar.show(context, "Error al actualizar", isError: true);
          }
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(context, "Error al actualizar", isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error: $e", isError: true);
      }
    }
  }

  // ----------------------
  //   ELIMINAR
  // ----------------------

  Future<void> removeTransaction(
      BuildContext context, Transaction transaction) async {
    _transactions.remove(transaction);
    await _saveTransactions();
    notifyListeners();
    CustomSnackbar.show(context, "Transacción eliminada");
  }
}
