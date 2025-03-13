// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:app_finanzas/app/model/transaction.dart';
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
    return await GetSelectsService.fetchData(['partners', 'statuses']);
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
        final partners = data['partners'] ?? [];
        final statuses = data['statuses'] ?? [];

        return _buildContent(context, partners, statuses);
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Error al cargar los datos'));
  }

  Widget _buildContent(
      BuildContext context, List<dynamic> partners, List<dynamic> statuses) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildTransactionList(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return widget.showAppBar
        ? AppBar(
            title: const Text("Transacciones"),
            backgroundColor: Colors.blue,
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
        leading: Icon(transaction.type.icon, color: transaction.type.color),
        title: Text(transaction.description ?? ''),
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

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "btn_refresh",
          onPressed: _refreshTransactions,
          backgroundColor: Colors.orange,
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "btn_add",
          onPressed: () => _showAddTransactionModal(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
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
      builder: (context) => const TransactionFormModal(),
    );
  }
}

class TransactionFormModal extends StatefulWidget {
  const TransactionFormModal({super.key});

  @override
  TransactionFormModalState createState() => TransactionFormModalState();
}

class TransactionFormModalState extends State<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _collaboratorController = TextEditingController();
  final _sourceController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.I;
  String? _selectedStatus;
  String? _selectedPartner;
  String? _selectedCategory;
  String? _selectedGoal;

  late Future<List<dynamic>> _statusesFuture;
  late Future<List<dynamic>> _partnersFuture;
  late Future<List<dynamic>> _categoriesFuture;
  late Future<List<dynamic>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _statusesFuture = _loadStatuses();
    _partnersFuture = _loadPartners();
    _categoriesFuture = _loadCategories();
    _goalsFuture = _loadGoals();
  }

  Future<List<dynamic>> _loadStatuses() async {
    final data = await GetSelectsService.fetchData(['statuses']);
    return data['statuses'] ?? [];
  }

  Future<List<dynamic>> _loadPartners() async {
    final data = await GetSelectsService.fetchData(['partners']);
    return data['partners'] ?? [];
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
    _descriptionController.dispose();
    _collaboratorController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                _buildDescriptionField(),
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
    return DropdownButtonFormField<TransactionType>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: "Tipo de Transacción",
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Seleccione un tipo' : null,
      onChanged: (value) => setState(() => _selectedType = value!),
      items: TransactionType.values.map(_buildDropdownItem).toList(),
    );
  }

  DropdownMenuItem<TransactionType> _buildDropdownItem(TransactionType type) {
    return DropdownMenuItem(
      value: type,
      child: Text(type.displayName),
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
    switch (_selectedType) {
      case TransactionType.I:
        return Column(
          children: [
            _buildPartnersDropdown(),
            const SizedBox(height: 15),
            _buildSourceField('Fuente'),
          ],
        );
      case TransactionType.E:
        return _buildCategoriesDropdown();
      case TransactionType.A:
        return Column(
          children: [
            _buildCollaboratorField('Nombre del objetivo'),
            const SizedBox(height: 15),
            // _buildSourceField('Objetivo'),
            _buildGoalsDropdown(),
          ],
        );
    }
  }

  Widget _buildCollaboratorField(String label) {
    return TextFormField(
      controller: _collaboratorController,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => _validateConditionalField(value, label),
    );
  }

  Widget _buildSourceField(String label) {
    return TextFormField(
      controller: _sourceController,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => _validateConditionalField(value, label),
    );
  }

  String? _validateConditionalField(String? value, String fieldName) {
    if (_isFieldRequired && (value == null || value.isEmpty)) {
      return 'Ingrese $fieldName';
    }
    return null;
  }

  bool get _isFieldRequired => _selectedType != TransactionType.E;

  Widget _buildStatusDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _statusesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error al cargar los estados');
        }

        final statuses = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: "Estado",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _selectedStatus = value),
          items: statuses.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: "${item['id']}",
              child: Text(item['label']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPartnersDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _partnersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error al cargar los colaboradores');
        }

        final partners = snapshot.data ?? [];

        // Verifica que no haya valores duplicados en la lista de partners
        final uniquePartners = partners.toSet().toList();

        return DropdownButtonFormField<String>(
          value: _selectedPartner,
          decoration: const InputDecoration(
            labelText: "Colaborador",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _selectedPartner = value),
          items: uniquePartners.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: "${item['id']}",
              child: Text(item['label']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoriesDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error al cargar los categorias');
        }

        final categories = snapshot.data ?? [];

        // Verifica que no haya valores duplicados en la lista de categories
        final uniquecategories = categories.toSet().toList();

        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: "Categoria",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _selectedCategory = value),
          items: uniquecategories.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: "${item['id']}",
              child: Text(item['label']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGoalsDropdown() {
    return FutureBuilder<List<dynamic>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error al cargar los objetivos');
        }

        final goals = snapshot.data ?? [];

        // Verifica que no haya valores duplicados en la lista de goals
        final uniqueGoals = goals.toSet().toList();

        return DropdownButtonFormField<String>(
          value: _selectedGoal,
          decoration: const InputDecoration(
            labelText: "Objetivo",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _selectedGoal = value),
          items: uniqueGoals.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: "${item['id']}",
              child: Text(item['label']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Ingrese una descripción' : null,
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

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      type: _selectedType,
      date: _selectedDate,
      // collaborator: _selectedPartner,
      source: _sourceController.text,
      // status: _selectedStatus,
    );

    context.read<TransactionsProvider>().addTransaction(context, transaction);
    Navigator.pop(context);
  }
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.I:
        return 'Ingreso';
      case TransactionType.E:
        return 'Gasto';
      case TransactionType.A:
        return 'Ahorro';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.I:
        return Icons.trending_up;
      case TransactionType.E:
        return Icons.trending_down;
      case TransactionType.A:
        return Icons.savings;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.I:
        return Colors.green;
      case TransactionType.E:
        return Colors.red;
      case TransactionType.A:
        return Colors.blue;
    }
  }
}
