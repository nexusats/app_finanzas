import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:app_finanzas/app/services/transaction_service.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:app_finanzas/app/model/sync_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TransactionsProvider extends ChangeNotifier {
  final List<Transaction> _transactions = [];
  final TransactionService _transactionService = TransactionService();

  Transaction? _selectedTransaction;

  bool _isLoading = false; // UI loading (una sola fuente de verdad)
  bool _loadedOnce = false; // ya cargó al menos una vez desde API
  Future<void>? _inFlight; // dedupe de requests simultáneos

  Transaction? get selectedTransaction => _selectedTransaction;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  TransactionsProvider() {
    // Importante: NO pegues al API aquí.
    // Solo carga cache local para que la UI no arranque vacía.
    _warmFromCache();
  }

  // ----------------------
  //   CACHE FIRST (LOCAL)
  // ----------------------

  Future<void> _warmFromCache() async {
    final stored = await LocalDatabase.getTransactions();
    _transactions
      ..clear()
      ..addAll(_visibleTransactions(stored));
    notifyListeners();
  }

  Future<void> _saveTransactions() async {
    await LocalDatabase.saveTransactions(_transactions);
  }

  // ----------------------
  //   FETCH (DEDUPE + IF NEEDED)
  // ----------------------

  static const Duration _ttl = Duration(minutes: 5);
  DateTime? _lastFetchAt;

  bool _isFresh() {
    if (_lastFetchAt == null) return false;
    return DateTime.now().difference(_lastFetchAt!) < _ttl;
  }

  Future<void> fetchTransactionsIfNeeded({bool force = false}) async {
    if (_inFlight != null) return _inFlight!;
    if (_loadedOnce && !force && _isFresh()) return;

    _inFlight = _loadFromApi().whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> fetchTransactions({bool force = true}) async {
    // alias explícito: si llamas fetchTransactions(), por defecto fuerza refresh
    return fetchTransactionsIfNeeded(force: force);
  }

  Future<void> _loadFromApi() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!await _isOnline()) return;
      final fetched = await _transactionService.getTransactions();

      _transactions
        ..clear()
        ..addAll(
          fetched
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .map(
                (transaction) => Transaction(
                  id: transaction.id,
                  userId: transaction.userId,
                  type: transaction.type,
                  amount: transaction.amount,
                  date: transaction.date,
                  note: transaction.note,
                  accountId: transaction.accountId,
                  categoryId: transaction.categoryId,
                  account: transaction.account,
                  category: transaction.category,
                  attachments: transaction.attachments,
                  syncStatus: SyncStatus.synced,
                ),
              ),
        );

      _loadedOnce = true;
      _lastFetchAt = DateTime.now();
      await _saveTransactions();
    } catch (_) {
      // Si falla el API, nos quedamos con lo que haya en cache (ya está warm)
      // y solo apagamos loading.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  //   CÁLCULOS
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

  // Ajusta esto según tu modelo real: si tienes "debt" como type, úsalo.
  double getTotalDebt() => _transactions
      .where((t) => t.type == "debt")
      .fold(0.0, (sum, t) => sum + t.amount);

  double getBalance() => getTotalIncomes() - getTotalExpenses();

  double getTotalByType(String type) => _transactions
      .where((t) => t.type == type)
      .fold(0.0, (sum, t) => sum + t.amount);

  List<Transaction> getTransactionsByType(
    String type, {
    List<int> statusIds = const [8, 9],
  }) {
    // Si tienes status_id en Transaction, aplica filtro.
    // Si no, quita statusIds de la firma para no mentirle al código 😄
    return _transactions.where((t) => t.type == type).toList();
  }

  // ----------------------
  //   AGREGAR / UPDATE / DELETE
  // ----------------------

  Future<void> addTransaction(
      BuildContext context, Transaction transaction) async {
    try {
      if (await _isOnline()) {
        final success =
            await _transactionService.createTransaction(transaction.toJson());
        if (!success) {
          if (context.mounted) {
            CustomSnackbar.show(context, "Error al agregar la transacción",
                isError: true);
          }
          return;
        }

        await fetchTransactions(force: true);

        if (context.mounted) {
          CustomSnackbar.show(context, "Transacción agregada exitosamente");
        }
        return;
      }

      final tempId = -DateTime.now().millisecondsSinceEpoch;
      final pending = Transaction(
        id: transaction.id ?? tempId,
        userId: transaction.userId,
        type: transaction.type,
        amount: transaction.amount,
        date: transaction.date,
        note: transaction.note,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        account: transaction.account,
        category: transaction.category,
        attachments: transaction.attachments,
        syncStatus: SyncStatus.pendingCreate,
      );
      _transactions.add(pending);
      await LocalDatabase.upsertTransaction(pending);
      notifyListeners();

      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "Transacción guardada sin conexión",
        );
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error de conexión: $error",
            isError: true);
      }
    }
  }

  Future<void> updateTransaction(
      BuildContext context, Transaction updatedTransaction) async {
    try {
      if (await _isOnline()) {
        final success = await _transactionService.updateTransaction(
          updatedTransaction.id!,
          updatedTransaction.toJson(),
        );

        if (!success) {
          if (context.mounted) {
            CustomSnackbar.show(context, "Error al actualizar", isError: true);
          }
          return;
        }

        final index =
            _transactions.indexWhere((t) => t.id == updatedTransaction.id);

        if (index != -1) {
          _transactions[index] = updatedTransaction;
          _selectedTransaction = updatedTransaction;
          await _saveTransactions();
          notifyListeners();
        }

        if (context.mounted) {
          CustomSnackbar.show(context, "Transacción actualizada");
        }
        return;
      }

      final index =
          _transactions.indexWhere((t) => t.id == updatedTransaction.id);

      if (index != -1) {
        final pending = Transaction(
          id: updatedTransaction.id,
          userId: updatedTransaction.userId,
          type: updatedTransaction.type,
          amount: updatedTransaction.amount,
          date: updatedTransaction.date,
          note: updatedTransaction.note,
          accountId: updatedTransaction.accountId,
          categoryId: updatedTransaction.categoryId,
          account: updatedTransaction.account,
          category: updatedTransaction.category,
          attachments: updatedTransaction.attachments,
          syncStatus: SyncStatus.pendingUpdate,
        );
        _transactions[index] = pending;
        _selectedTransaction = pending;
        await LocalDatabase.upsertTransaction(pending);
        notifyListeners();
      }

      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "Transacción actualizada sin conexión",
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error: $e", isError: true);
      }
    }
  }

  Future<void> removeTransaction(
      BuildContext context, Transaction transaction) async {
    if (transaction.id == null) {
      if (context.mounted) {
        CustomSnackbar.show(context, "No se puede eliminar: id inválido",
            isError: true);
      }
      return;
    }

    try {
      if (await _isOnline()) {
        final ok =
            await _transactionService.deleteTransaction(transaction.id!);
        if (!ok) {
          if (context.mounted) {
            CustomSnackbar.show(context, "Error al eliminar", isError: true);
          }
          return;
        }

        _transactions.removeWhere((t) => t.id == transaction.id);
        await _saveTransactions();
        notifyListeners();

        await fetchTransactions(force: true);

        if (context.mounted) {
          CustomSnackbar.show(context, "Transacción eliminada");
        }
        return;
      }

      _transactions.removeWhere((t) => t.id == transaction.id);
      final pending = Transaction(
        id: transaction.id,
        userId: transaction.userId,
        type: transaction.type,
        amount: transaction.amount,
        date: transaction.date,
        note: transaction.note,
        accountId: transaction.accountId,
        categoryId: transaction.categoryId,
        account: transaction.account,
        category: transaction.category,
        attachments: transaction.attachments,
        syncStatus: SyncStatus.pendingDelete,
      );
      await LocalDatabase.upsertTransaction(pending);
      notifyListeners();

      if (context.mounted) {
        CustomSnackbar.show(
          context,
          "Transacción eliminada sin conexión",
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error: $e", isError: true);
      }
    }
  }

  // Útil para logout
  Future<void> clearLocal() async {
    _transactions.clear();
    _selectedTransaction = null;
    _loadedOnce = false;
    _isLoading = false;

    await LocalDatabase.saveTransactions([]);
    notifyListeners();
  }

  List<Transaction> _visibleTransactions(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.syncStatus != SyncStatus.pendingDelete)
        .toList();
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
