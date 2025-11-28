// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/app/model/transaction.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app_finanzas/app/services/get_selects_service.dart';
import 'package:app_finanzas/app/controller/transactions_provider.dart';
import 'package:app_finanzas/screen/transaction/transaction_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  final bool showAppBar;

  const TransactionScreen({super.key, this.showAppBar = true});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    // mantenemos por compatibilidad si lo necesitas en el futuro
    return await GetSelectsService.fetchData(['statuses']);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final data = snapshot.data ?? {};
        final statuses = data['statuses'] ?? [];

        return _buildContent(context, statuses);
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: ConfigGlobal.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Error al cargar los datos'));
  }

  Widget _buildContent(BuildContext context, List<dynamic> statuses) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: ConfigGlobal.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: _buildTransactionList(),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return widget.showAppBar
        ? AppBar(
            title: const Text("Transacciones"),
            backgroundColor: ConfigGlobal.backgroundColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshTransactions,
              ),
            ],
          )
        : null;
  }

  Widget _buildTransactionList() {
    return Consumer<TransactionsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return _buildLoadingSkeleton();
        if (provider.transactions.isEmpty) return _buildEmptyState();
        return _buildTransactionsListView(provider.transactions);
      },
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

  Widget _buildEmptyState() {
    return const Center(child: Text("No hay transacciones disponibles"));
  }

  Widget _buildTransactionsListView(List<Transaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: transactions.length,
      itemBuilder: (context, index) =>
          _buildTransactionItem(transactions[index]),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(
          _iconForType(transaction.type),
          color: _colorForType(transaction.type),
        ),
        title: Text(transaction.note ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Monto: \$${transaction.amount.toStringAsFixed(2)}"),
            Text("Fecha: ${DateFormat('dd/MM/yyyy').format(transaction.date)}"),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _navigateToDetail(transaction.id!),
        ),
      ),
    );
  }

  IconData _iconForType(String t) {
    switch (t) {
      case 'income':
        return Icons.arrow_downward;
      case 'expense':
        return Icons.arrow_upward;
      case 'saving':
        return Icons.savings;
      case 'debt_in':
        return Icons.call_received;
      case 'debt_on':
        return Icons.call_made;
      default:
        return Icons.help_outline;
    }
  }

  Color _colorForType(String t) {
    switch (t) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'saving':
        return Colors.blue;
      case 'debt_in':
        return Colors.orange;
      case 'debt_on':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFloatingActionButtons() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      backgroundColor: ConfigGlobal.backgroundColor,
      foregroundColor: Colors.white,
      overlayOpacity: 0.1,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.refresh, color: Colors.white),
          backgroundColor: Colors.orange,
          label: 'Refrescar',
          onTap: _refreshTransactions,
        ),
        SpeedDialChild(
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: ConfigGlobal.backgroundColor,
          label: 'Agregar',
          onTap: _showAddTransactionModal,
        ),
      ],
    );
  }

  void _refreshTransactions() {
    Provider.of<TransactionsProvider>(context, listen: false)
        .fetchTransactions();
  }

  void _navigateToDetail(int transactionId) async {
    await Provider.of<TransactionsProvider>(context, listen: false)
        .fetchTransactionById(transactionId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionDetailScreen(transactionId: transactionId),
      ),
    );
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: TransactionFormModal(),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                  Transaction Form Modal (actualizado)                      */
/* -------------------------------------------------------------------------- */

class TransactionFormModal extends StatefulWidget {
  const TransactionFormModal({super.key});

  @override
  TransactionFormModalState createState() => TransactionFormModalState();
}

class TransactionFormModalState extends State<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _recurringDaysController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'income'; // income, expense, saving, debt_in, debt_on
  String? _selectedStatus;
  String? _selectedCategory;
  String? _selectedGoal;

  bool _isRecurring = false;

  late Future<List<dynamic>> _statusesFuture;
  late Future<List<dynamic>> _categoriesFuture;
  late Future<List<dynamic>> _goalsFuture;

  // Map para mostrar nombres legibles de tipos
  final Map<String, String> _typeLabels = {
    'income': 'Ingreso',
    'expense': 'Gasto',
    'saving': 'Ahorro',
    'debt_in': 'Deuda (Préstamos realizados)',
    'debt_on': 'Deuda (Préstamos recibidos)',
  };

  @override
  void initState() {
    super.initState();
    _statusesFuture = _loadStatuses();
    _categoriesFuture = _loadCategories();
    _goalsFuture = _loadGoals();
  }

  Future<List<dynamic>> _loadStatuses() async {
    final data = await GetSelectsService.fetchData(['statuses']);
    return data['statuses'] ?? [];
  }

  Future<List<dynamic>> _loadCategories() async {
    final data = await GetSelectsService.fetchData(['expenses_categories']);
    return data['expenses_categories'] ?? [];
  }

  Future<List<dynamic>> _loadGoals() async {
    final data = await GetSelectsService.fetchData(['goals']);
    return data['goals'] ?? [];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _recurringDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildTypeDropdown(),
                const SizedBox(height: 15),
                _buildDateSelector(),
                const SizedBox(height: 15),
                _buildAmountField(),
                const SizedBox(height: 15),
                _buildConditionalFields(),
                const SizedBox(height: 15),
                _buildStatusDropdown(),
                const SizedBox(height: 15),
                _buildNoteField(),
                const SizedBox(height: 15),
                _buildRecurringField(),
                const SizedBox(height: 25),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Agregar transacción',
      style: TextStyle(
        fontSize: ConfigGlobal.sizeTitle,
        fontWeight: FontWeight.bold,
        color: ConfigGlobal.backgroundColor,
      ),
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
      onChanged: (value) => setState(() => _selectedType = value!),
      items: _typeLabels.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: _selectDate,
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: const InputDecoration(
        labelText: "Monto",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      validator: _validateAmount,
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese un monto';
    final amount = double.tryParse(value);
    if (amount == null) return 'Monto inválido';
    if (amount <= 0) return 'Monto debe ser positivo';
    return null;
  }

  Widget _buildConditionalFields() {
    // expense -> categories
    // saving, debt_in, debt_on -> goals
    if (_selectedType == 'expense') {
      return _buildCategoriesDropdown();
    }
    if (_selectedType == 'saving' ||
        _selectedType == 'debt_in' ||
        _selectedType == 'debt_on') {
      return _buildGoalsDropdown();
    }
    // income -> nothing special
    return const SizedBox.shrink();
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Nota',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Ingrese una nota' : null,
    );
  }

  Widget _buildRecurringField() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Recurrente'),
          value: _isRecurring,
          onChanged: (v) => setState(() => _isRecurring = v),
        ),
        if (_isRecurring)
          TextFormField(
            controller: _recurringDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Intervalo (días)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (!_isRecurring) return null;
              if (v == null || v.isEmpty) return 'Ingrese intervalo';
              final n = int.tryParse(v);
              if (n == null || n <= 0) return 'Intervalo inválido';
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return _buildDropdown(
      future: _statusesFuture,
      label: "Estado",
      value: _selectedStatus,
      onChanged: (value) => setState(() => _selectedStatus = value),
    );
  }

  Widget _buildCategoriesDropdown() {
    return _buildDropdown(
      future: _categoriesFuture,
      label: "Categoría",
      value: _selectedCategory,
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildGoalsDropdown() {
    return _buildDropdown(
      future: _goalsFuture,
      label: "Objetivo",
      value: _selectedGoal,
      onChanged: (value) => setState(() => _selectedGoal = value),
    );
  }

  Widget _buildDropdown({
    required Future<List<dynamic>> future,
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error al cargar $label');
        }

        final items = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: "${item['id']}",
              child: Text(item['label'] ?? item['name'] ?? 'Sin nombre'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text("Guardar Transacción"),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final amountParsed = double.tryParse(_amountController.text);
    if (amountParsed == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Monto inválido')));
      return;
    }

    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seleccione un estado')));
      return;
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      type: _selectedType,
      amount: amountParsed,
      statusId: int.tryParse(_selectedStatus!) ?? 0,
      date: _selectedDate,
      note: _noteController.text.trim(),
      categoryId:
          _selectedCategory != null ? int.tryParse(_selectedCategory!) : null,
      goalId: _selectedGoal != null ? int.tryParse(_selectedGoal!) : null,
      isRecurring: _isRecurring,
      recurringIntervalDays:
          _isRecurring ? int.tryParse(_recurringDaysController.text) : null,
      files: [],
    );

    // El provider debe encargarse de enviar al backend (multipart si hay archivos).
    context.read<TransactionsProvider>().addTransaction(context, transaction);
    Navigator.pop(context);
  }
}
