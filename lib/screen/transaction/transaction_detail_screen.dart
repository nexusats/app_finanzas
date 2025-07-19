import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  // ignore: library_private_types_in_public_api
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTransaction();
  }

  Future<void> _fetchTransaction() async {
    final transactionProvider =
        Provider.of<TransactionsProvider>(context, listen: false);

    // ⚡ Evita hacer la petición si la transacción ya está cargada
    if (transactionProvider.selectedTransaction?.id == widget.transactionId) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await transactionProvider.fetchTransactionById(widget.transactionId);
    } catch (e) {
      CustomSnackbar.show(context, "Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Transacción"),
        backgroundColor: ConfigGlobal.backgroundColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransactionsProvider>(
        builder: (context, transactionProvider, child) {
          final transaction = transactionProvider.selectedTransaction;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transaction == null) {
            return const Center(child: Text("No se encontró la transacción"));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Descripción: ${transaction.description}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Monto: \$${transaction.amount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Fecha: ${transaction.date}",
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }
}
