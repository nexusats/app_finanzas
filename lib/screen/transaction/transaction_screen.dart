import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    Provider.of<TransactionsProvider>(context, listen: false)
                        .fetchTransactions();
                  },
                ),
              ],
            )
          : null,
      body: Consumer<TransactionsProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return _buildLoadingSkeleton();
          }

          final transactions = transactionProvider.transactions;

          if (transactions.isEmpty) {
            return const Center(
              child: Text("No hay transacciones disponibles"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            itemBuilder: (context, index) =>
                _buildTransactionItem(context, transactions[index]),
          );
        },
      ),
      floatingActionButton: _buildFloatingButtons(context),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(
          transaction.type == TransactionType.I
              ? Icons.attach_money
              : Icons.money_off,
          color: transaction.type == TransactionType.I ? Colors.green : Colors.red,
        ),
        title: Text(transaction.description ?? ""),
        subtitle: Text("Monto: \$${transaction.amount.toStringAsFixed(2)}"),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            Provider.of<TransactionsProvider>(context, listen: false)
                .fetchTransactionById(transaction.id!)
                .then((_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailScreen(transactionId: transaction.id!),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            leading: Container(width: 40, height: 40, color: Colors.white),
            title: Container(width: double.infinity, height: 16, color: Colors.white),
            subtitle: Container(width: 100, height: 14, color: Colors.white),
            trailing: Container(width: 20, height: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "btn_refresh",
          onPressed: () {
            Provider.of<TransactionsProvider>(context, listen: false).fetchTransactions();
          },
          backgroundColor: Colors.orange,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "btn_add",
          onPressed: () => _showAddTransactionModal(context),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    final TextEditingController _amountController = TextEditingController();
    TransactionType _selectedType = TransactionType.I;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nueva Transacción", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                onChanged: (value) {
                  if (value != null) _selectedType = value;
                },
                decoration: const InputDecoration(
                  labelText: "Tipo de Transacción",
                  border: OutlineInputBorder(),
                ),
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == TransactionType.I ? "Ingreso" : (type == TransactionType.E ? "Gasto" : "Ahorro")),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monto",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Provider.of<TransactionsProvider>(context, listen: false).addTransaction(
                    context,
                    Transaction(
                      id: DateTime.now().millisecondsSinceEpoch,
                      description: "Nueva transacción",
                      amount: double.parse(_amountController.text),
                      type: _selectedType,
                      date: DateTime.now(),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text("Guardar"),
              ),
            ],
          ),
        );
      },
    );
  }
}
