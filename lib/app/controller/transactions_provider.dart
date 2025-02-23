import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/transaction_service.dart';

class TransactionsProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  SharedPreferences? prefs;
  final TransactionService _transactionService = TransactionService(); // Instancia del servicio

  TransactionsProvider() {
    _loadTransactions(); // Cargar las transacciones guardadas al iniciar
  }

  List<Transaction> get transactions => _transactions;

  double getTotalIncomes() {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.I)
        .map((transaction) => transaction.amount)
        .fold(0, (previousValue, element) => previousValue + element);
  }

  double getTotalExpenses() {
    return _transactions
        .where((transaction) => transaction.type == TransactionType.E)
        .map((transaction) => transaction.amount)
        .fold(0, (previousValue, element) => previousValue + element);
  }

  double getBalance() {
    return getTotalIncomes() - getTotalExpenses();
  }

  Future<void> _loadTransactions() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? storedTransactions = prefs?.getStringList("_transactions");
    
    if (storedTransactions != null) {
      _transactions.clear();
      _transactions.addAll(
        storedTransactions.map((jsonString) => Transaction.fromJson(jsonDecode(jsonString)))
      );
    }
    notifyListeners();
  }

  Future _saveTransactions() async {
    if (prefs != null) {
      List<String> jsonTransactions = _transactions.map((transaction) => jsonEncode(transaction.toJson())).toList();
      await prefs!.setStringList("_transactions", jsonTransactions);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Realiza la solicitud al servicio para agregar la transacción
      bool success = await _transactionService.createTransaction(transaction.toJson());

      if (success) {
        // Si la transacción se ha agregado con éxito a través del servicio, se añade a la lista local
        _transactions.add(transaction);
        await _saveTransactions();
        notifyListeners();
      } else {
        // Manejo de error en caso de que la petición falle
        throw Exception('Failed to add transaction');
      }
    } catch (error) {
      // Manejo de errores
      throw Exception('Error: $error');
    }
  }

  Future<void> removeTransaction(Transaction transaction) async {
    _transactions.remove(transaction);
    await _saveTransactions();
    notifyListeners();
  }
}
