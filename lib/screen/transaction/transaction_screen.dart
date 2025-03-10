import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
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
    TransactionType? _selectedType = TransactionType.I;
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
                    // Título del Modal
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'Agregar transacción',
                        style: TextStyle(
                          fontSize: ConfigGlobal.sizeTitle,
                          fontWeight: FontWeight.bold,
                          color: ConfigGlobal.backgroundColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Selección del tipo de transacción
                    _buildDropdownField(
                      "Tipo de Transacción",
                      [
                        {"id": "I", "label": "Ingreso"},
                        {"id": "E", "label": "Gasto"},
                        {"id": "A", "label": "Ahorro"}
                      ],
                      (value) {
                        setState(() {
                          _selectedType = TransactionType.values.firstWhere(
                            (type) => type.toString().split('.').last == value,
                            orElse: () => TransactionType.I,
                          );
                        });
                      },
                      _selectedType.toString().split('.').last,
                    ),

                    const SizedBox(height: 10),

                    // Selector de fecha
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200], // Fondo claro
                      ),
                      child: ListTile(
                        title: Text(
                          _selectedDate == null
                              ? "Seleccionar fecha"
                              : "Fecha: ${_selectedDate!.toLocal()}"
                                  .split(' ')[0],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today,
                            color: Colors.blue),
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
                    ),

                    const SizedBox(height: 10),

                    // Campo para el monto
                    _buildInputField(
                      "Monto",
                      TextInputType.number,
                      (value) {},
                      controller: _amountController,
                    ),

                    const SizedBox(height: 15),

                    // Campos adicionales según el tipo de transacción
                    if (_selectedType == TransactionType.I) ...[
                      _buildInputField(
                        "Colaborador",
                        TextInputType.text,
                        (value) {},
                        controller: _collaboratorController,
                      ),
                      const SizedBox(height: 10),
                      _buildInputField(
                        "Fuente",
                        TextInputType.text,
                        (value) {},
                        controller: _sourceController,
                      ),
                    ],

                    if (_selectedType == TransactionType.E) ...[
                      _buildInputField(
                        "Categoría",
                        TextInputType.text,
                        (value) {},
                        controller: _collaboratorController,
                      ),
                    ],

                    if (_selectedType == TransactionType.A) ...[
                      _buildInputField(
                        "Nombre del objetivo",
                        TextInputType.text,
                        (value) {},
                        controller: _collaboratorController,
                      ),
                      const SizedBox(height: 10),
                      _buildInputField(
                        "Objetivo",
                        TextInputType.text,
                        (value) {},
                        controller: _sourceController,
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Selección del estado
                    _buildDropdownField(
                      "Estado",
                      [
                        {"id": "Pendiente", "label": "Pendiente"},
                        {"id": "Confirmado", "label": "Confirmado"},
                        {"id": "Rechazado", "label": "Rechazado"},
                      ],
                      (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                      _selectedStatus,
                    ),

                    const SizedBox(height: 10),

                    // Campo de descripción
                    _buildTextArea(
                      "Descripción",
                      (value) {
                        _descriptionController.text = value;
                      },
                    ),

                    const SizedBox(height: 10),

                    // Botón de guardar
                    ElevatedButton(
                      onPressed: () {
                        if (_amountController.text.isNotEmpty) {
                          final transaction = Transaction(
                            id: DateTime.now().millisecondsSinceEpoch,
                            description: _descriptionController.text,
                            amount: double.parse(_amountController.text),
                            type: _selectedType ?? TransactionType.I,
                            date: _selectedDate ?? DateTime.now(),
                          );

                          // Guardar transacción (ejemplo con Provider)
                          // Provider.of<TransactionsProvider>(context, listen: false).addTransaction(transaction);

                          Navigator.pop(
                              context); // Cerrar modal después de guardar
                        } else {
                          // Mostrar error si falta el monto
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

// Función para construir dropdowns reutilizables
  Widget _buildDropdownField(
    String label,
    List<Map<String, String>> options,
    Function(String) onChanged,
    String selectedValue,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      value: selectedValue,
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option['id']!,
          child: Text(option['label']!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

// Función para construir campos de texto reutilizables
  Widget _buildInputField(
    String label,
    TextInputType keyboardType,
    Function(String) onChanged, {
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Ingrese $label',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: keyboardType,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

// Función para construir área de texto reutilizable
  Widget _buildTextArea(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ingrese $label',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
