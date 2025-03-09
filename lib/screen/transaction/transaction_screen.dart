import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/screen/transaction/transaction_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  final bool showAppBar;

  const TransactionScreen({super.key, this.showAppBar = true});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
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
          color:
              transaction.type == TransactionType.I ? Colors.green : Colors.red,
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
            title: Container(
                width: double.infinity, height: 16, color: Colors.white),
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
            Provider.of<TransactionsProvider>(context, listen: false)
                .fetchTransactions();
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
    final TextEditingController _collaboratorController =
        TextEditingController();
    final TextEditingController _sourceController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();

    DateTime? _selectedDate;
    TransactionType? _selectedType =
        TransactionType.I; // Establecer valor predeterminado
    String _selectedStatus = "Pendiente";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Nueva Transacción",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Dropdown para seleccionar el tipo de transacción
                    DropdownButtonFormField<TransactionType>(
                      value: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Tipo de Transacción",
                        border: OutlineInputBorder(),
                      ),
                      items: TransactionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == TransactionType.I
                                ? "Ingreso"
                                : (type == TransactionType.E
                                    ? "Gasto"
                                    : "Ahorro"),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Campo para el monto
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Monto",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Mostrar los campos adicionales solo si es tipo "Ingreso"
                    if (_selectedType == TransactionType.I) ...[
                      TextField(
                        controller: _collaboratorController,
                        decoration: const InputDecoration(
                          labelText: "Colaborador",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: "Fuente",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Estado",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Pendiente", "Confirmado", "Rechazado"]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Descripción",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Selector de fecha
                      ListTile(
                        title: Text(
                          _selectedDate == null
                              ? "Seleccionar fecha"
                              : "Fecha: ${_selectedDate!.toLocal()}"
                                  .split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        if (_amountController.text.isNotEmpty) {
                          // Aquí guardas la transacción o haces lo que necesites con los datos
                          final transaction = Transaction(
                            id: DateTime.now().millisecondsSinceEpoch,
                            description: _descriptionController.text,
                            amount: double.parse(_amountController.text),
                            type: _selectedType ??
                                TransactionType
                                    .I, // Si no hay valor, usa 'Ingreso' por defecto
                            date: _selectedDate ?? DateTime.now(),
                          );

                          // Agregar la transacción a tu provider o base de datos
                          // Ejemplo:
                          // Provider.of<TransactionsProvider>(context, listen: false).addTransaction(transaction);
                          Navigator.pop(
                              context); // Cierra el modal después de guardar
                        } else {
                          // Mensaje de error si falta el monto
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Por favor, ingresa el monto")),
                          );
                        }
                      },
                      child: const Text("Guardar"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
