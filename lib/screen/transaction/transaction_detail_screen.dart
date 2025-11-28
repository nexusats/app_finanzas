import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:app_finanzas/app/services/get_selects_service.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  _TransactionDetailScreenState createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();

  Future<List<dynamic>>? _categoriesFuture;
  Future<List<dynamic>>? _statusesFuture;

  dynamic _selectedCategory;
  dynamic _selectedStatus;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
    _statusesFuture = _loadStatuses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTransaction();
  }

  Future<List<dynamic>> _loadCategories() async {
    final data = await GetSelectsService.fetchData(['categories']);
    return data['categories'] ?? [];
  }

  Future<List<dynamic>> _loadStatuses() async {
    final data = await GetSelectsService.fetchData(['statuses']);
    return data['statuses'] ?? [];
  }

  Future<void> _fetchTransaction() async {
    final provider = Provider.of<TransactionsProvider>(context, listen: false);

    try {
      final categories = await _categoriesFuture;
      final statuses = await _statusesFuture;

      await provider.fetchTransactionById(widget.transactionId);
      final tx = provider.selectedTransaction;

      if (tx != null) {
        _fillFields(tx, categories!, statuses!);
      }
    } catch (e) {
      CustomSnackbar.show(context, "Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fillFields(
      Transaction tx, List<dynamic> categories, List<dynamic> statuses) {
    _descController.text = tx.note ?? '';
    _amountController.text = tx.amount.toString();
    _dateController.text = tx.date.toIso8601String().split('T').first;

    _selectedCategory = categories.firstWhere(
      (c) => c['id'] == tx.categoryId,
      orElse: () => null,
    );

    _selectedStatus = statuses.firstWhere(
      (s) => s['id'] == tx.statusId,
      orElse: () => null,
    );

    _selectedType = tx.type;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<TransactionsProvider>(context, listen: false);
    final original = provider.selectedTransaction;
    if (original == null || _selectedType == null) return;

    final updated = Transaction(
      id: original.id,
      createdBy: original.createdBy,
      type: _selectedType!,
      amount: double.tryParse(_amountController.text) ?? original.amount,
      totalDebt: original.totalDebt,
      date: DateTime.tryParse(_dateController.text) ?? original.date,
      note: _descController.text,
      categoryId: _selectedType == "expense"
          ? (_selectedCategory is Map ? _selectedCategory['id'] : null)
          : null,
      goalId: original.goalId,
      statusId:
          _selectedStatus is Map ? _selectedStatus['id'] : _selectedStatus,
      isRecurring: original.isRecurring,
      recurringIntervalDays: original.recurringIntervalDays,
      files: original.files,
    );

    await provider.updateTransaction(context, updated);
  }

  Widget _buildDropdown({
    required Future<List<dynamic>> future,
    required String label,
    required dynamic value,
    required void Function(dynamic) onChanged,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final items = snapshot.data!;
        final currentValue = value == null
            ? null
            : items.firstWhere(
                (e) => e['id'] == (value is Map ? value['id'] : value),
                orElse: () => null,
              );

        return DropdownButtonFormField<dynamic>(
          decoration: InputDecoration(labelText: label),
          value: currentValue,
          items: items.map((item) {
            return DropdownMenuItem<dynamic>(
              value: item,
              child: Text(item['label'] ?? item['name'] ?? 'Sin nombre'),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildCategoriesDropdown() {
    return _buildDropdown(
      future: _categoriesFuture!,
      label: "Categoría",
      value: _selectedCategory,
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildDropdown(
      future: _statusesFuture!,
      label: "Estado",
      value: _selectedStatus,
      onChanged: (value) => setState(() => _selectedStatus = value),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: "Tipo de Transacción",
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Seleccione un tipo' : null,
      onChanged: (value) => setState(() => _selectedType = value),
      items: const [
        DropdownMenuItem(value: "income", child: Text("Ingreso")),
        DropdownMenuItem(value: "expense", child: Text("Gasto")),
        DropdownMenuItem(value: "saving", child: Text("Ahorro")),
        DropdownMenuItem(value: "debt_in", child: Text("Entrada deuda")),
        DropdownMenuItem(value: "debt_on", child: Text("Pago deuda")),
      ],
    );
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
        builder: (context, provider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tx = provider.selectedTransaction;
          if (tx == null) {
            return const Center(child: Text("No se encontró la transacción"));
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Nota'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    validator: (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Ingrese un número válido'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  _buildTypeDropdown(),
                  const SizedBox(height: 10),
                  _buildStatusDropdown(),
                  const SizedBox(height: 10),
                  if (_selectedType == "expense") _buildCategoriesDropdown(),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _dateController,
                    decoration:
                        const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Text("Guardar Cambios"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
