import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';

class TransactionScreen extends StatelessWidget {
  final bool showAppBar;

  const TransactionScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text("Transacciones"),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
      body: Consumer<TransactionsProvider>(
        builder: (context, transactionProvider, child) {
          final transactions = transactionProvider.transactions;
          print(transactions);
          if (transactions.isEmpty) {
            return const Center(child: Text("No hay transacciones disponibles"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) => _buildTransactionItem(transactions[index]),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(
          transaction.type == TransactionType.I ? Icons.attach_money : Icons.money_off,
          color: transaction.type == TransactionType.I ? Colors.green : Colors.red,
        ),
        title: Text(transaction.description ?? ""),
        subtitle: Text("Monto: \$${transaction.amount.toStringAsFixed(2)}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
