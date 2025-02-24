import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/screen/transaction/transaction_detail_screen.dart';

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

          if (transactions.isEmpty) {
            return const Center(
              child: Text("No hay transacciones disponibles"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) => _buildTransactionItem(
                context, transactions[index]), // Se pasa `context`
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    // Validación para asegurar que `transaction.id` sea un entero válido
    final transactionId = transaction.id;
    if (transactionId == null) {
      return const SizedBox(); // Evita errores si `id` es nulo o de otro tipo
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(
          transaction.type == TransactionType.I
              ? Icons.attach_money
              : Icons.money_off,
          color:
              transaction.type == TransactionType.I ? Colors.green : Colors.red,
        ),
        title: Text(transaction.description ?? ""),
        subtitle: Text("Monto: \$${transaction.amount.toStringAsFixed(2)}"),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // Obtener transacción por ID y navegar a la pantalla de detalles
            Provider.of<TransactionsProvider>(context, listen: false)
                .fetchTransactionById(transactionId)
                .then((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailScreen(transactionId: transactionId),
                ),
              );
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text("Error al obtener detalles de la transacción")),
              );
            });
          },
        ),
      ),
    );
  }
}
