import 'package:app_finanzas/app/model/account.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/app/model/sync_status.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/app/services/account_service.dart';
import 'package:app_finanzas/app/services/category_service.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:app_finanzas/app/services/transaction_service.dart';

class SyncService {
  final AccountService _accountService;
  final CategoryService _categoryService;
  final TransactionService _transactionService;

  SyncService({
    AccountService? accountService,
    CategoryService? categoryService,
    TransactionService? transactionService,
  })  : _accountService = accountService ?? AccountService(),
        _categoryService = categoryService ?? CategoryService(),
        _transactionService = transactionService ?? TransactionService();

  Future<void> syncAll() async {
    await _syncAccounts();
    await _syncCategories();
    await _syncTransactions();
    await LocalDatabase.setLastSyncAt(DateTime.now());
  }

  Future<void> _syncAccounts() async {
    final pending = await LocalDatabase.getPendingAccounts();
    for (final account in pending) {
      switch (account.syncStatus) {
        case SyncStatus.pendingCreate:
          final created = await _accountService.createAccount(account.toJson());
          if (created) {
            await LocalDatabase.upsertAccount(
              Account(
                id: account.id,
                userId: account.userId,
                name: account.name,
                initialBalance: account.initialBalance,
                currentBalance: account.currentBalance,
                currentBalanceFormatted: account.currentBalanceFormatted,
                isArchived: account.isArchived,
                createdAt: account.createdAt,
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.synced,
              ),
            );
          }
          break;
        case SyncStatus.pendingUpdate:
          if (account.id != null) {
            final ok = await _accountService.updateAccount(
              account.id!,
              account.toJson(),
            );
            if (ok) {
              await LocalDatabase.upsertAccount(
                Account(
                  id: account.id,
                  userId: account.userId,
                  name: account.name,
                  initialBalance: account.initialBalance,
                  currentBalance: account.currentBalance,
                  currentBalanceFormatted: account.currentBalanceFormatted,
                  isArchived: account.isArchived,
                  createdAt: account.createdAt,
                  updatedAt: DateTime.now(),
                  syncStatus: SyncStatus.synced,
                ),
              );
            }
          }
          break;
        case SyncStatus.pendingDelete:
          if (account.id != null) {
            final ok = await _accountService.deleteAccount(account.id!);
            if (ok) {
              await LocalDatabase.removeAccount(account);
            }
          }
          break;
        case SyncStatus.synced:
          break;
      }
    }
  }

  Future<void> _syncCategories() async {
    final pending = await LocalDatabase.getPendingCategories();
    for (final category in pending) {
      switch (category.syncStatus) {
        case SyncStatus.pendingCreate:
          final ok = await _categoryService.createCategory(category.toJson());
          if (ok) {
            await LocalDatabase.upsertCategory(
              Category(
                id: category.id,
                name: category.name,
                type: category.type,
                icon: category.icon,
                isArchived: category.isArchived,
                createdAt: category.createdAt,
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.synced,
              ),
            );
          }
          break;
        case SyncStatus.pendingUpdate:
          if (category.id != null) {
            final ok = await _categoryService.updateCategory(
              category.id!,
              category.toJson(),
            );
            if (ok) {
              await LocalDatabase.upsertCategory(
                Category(
                  id: category.id,
                  name: category.name,
                  type: category.type,
                  icon: category.icon,
                  isArchived: category.isArchived,
                  createdAt: category.createdAt,
                  updatedAt: DateTime.now(),
                  syncStatus: SyncStatus.synced,
                ),
              );
            }
          }
          break;
        case SyncStatus.pendingDelete:
          if (category.id != null) {
            final ok = await _categoryService.deleteCategory(category.id!);
            if (ok) {
              await LocalDatabase.removeCategory(category);
            }
          }
          break;
        case SyncStatus.synced:
          break;
      }
    }
  }

  Future<void> _syncTransactions() async {
    final pending = await LocalDatabase.getPendingTransactions();
    for (final transaction in pending) {
      switch (transaction.syncStatus) {
        case SyncStatus.pendingCreate:
          final ok = await _transactionService.createTransaction(
            transaction.toJson(),
          );
          if (ok) {
            await LocalDatabase.upsertTransaction(
              Transaction(
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
            );
          }
          break;
        case SyncStatus.pendingUpdate:
          if (transaction.id != null) {
            final ok = await _transactionService.updateTransaction(
              transaction.id!,
              transaction.toJson(),
            );
            if (ok) {
              await LocalDatabase.upsertTransaction(
                Transaction(
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
              );
            }
          }
          break;
        case SyncStatus.pendingDelete:
          if (transaction.id != null) {
            final ok = await _transactionService.deleteTransaction(
              transaction.id!,
            );
            if (ok) {
              await LocalDatabase.removeTransaction(transaction);
            }
          }
          break;
        case SyncStatus.synced:
          break;
      }
    }
  }
}
