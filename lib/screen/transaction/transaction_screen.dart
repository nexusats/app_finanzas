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

class TransactionScreen extends StatefulWidget {
  final bool showAppBar;

  const TransactionScreen({super.key, this.showAppBar = true});

  @override
  State<TransactionScreen> createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  late Future<Map<String, dynamic>> _metaFuture;

  @override
  void initState() {
    super.initState();
    _metaFuture = _loadMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().fetchTransactions();
    });
  }

  Future<Map<String, dynamic>> _loadMeta() async {
    // Reusa tus resources existentes:
    // GET /accounts  y GET /categories
    // Ajusta GetSelectsService para que devuelva:
    // { "accounts": [...], "categories": [...] }
    final data = await GetSelectsService.fetchData(['accounts', 'categories']);
    return {
      'accounts': (data['accounts'] ?? []) as List<dynamic>,
      'categories': (data['categories'] ?? []) as List<dynamic>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _metaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final meta = snapshot.data ?? const {};
        final accounts = (meta['accounts'] ?? []) as List<dynamic>;
        final categories = (meta['categories'] ?? []) as List<dynamic>;

        return _buildContent(context, accounts, categories);
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
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorState() {
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
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Error al cargar datos del formulario'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() => _metaFuture = _loadMeta()),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<dynamic> accounts,
    List<dynamic> categories,
  ) {
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
      floatingActionButton: _buildFloatingActionButtons(accounts, categories),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return widget.showAppBar
        ? AppBar(
            title: const Text("Movimientos"),
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
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Container(width: 40, height: 40, color: Colors.white),
            title: Container(
              width: double.infinity,
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(width: 120, height: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No hay movimientos todavía"));
  }

  Widget _buildTransactionsListView(List<Transaction> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (context, index) =>
          _buildTransactionItem(transactions[index]),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    final icon = t.type == 'income'
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final color = t.type == 'income' ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text((t.note ?? '').isEmpty ? 'Sin nota' : t.note!),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Monto: \$${t.amount.toStringAsFixed(2)}"),
            Text("Fecha: ${DateFormat('dd/MM/yyyy').format(t.date)}"),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _openEditModal(t),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(
    List<dynamic> accounts,
    List<dynamic> categories,
  ) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      backgroundColor: ConfigGlobal.backgroundColor,
      foregroundColor: Colors.white,
      overlayOpacity: 0,
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
          onTap: () => _showAddTransactionModal(accounts, categories),
        ),
      ],
    );
  }

  void _refreshTransactions() {
    context.read<TransactionsProvider>().fetchTransactions();
  }

  void _openEditModal(Transaction t) async {
    // Reusa el meta ya cargado para no pedirlo otra vez
    final meta = await _metaFuture;
    final accounts = (meta['accounts'] ?? []) as List<dynamic>;
    final categories = (meta['categories'] ?? []) as List<dynamic>;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ConfigGlobal.backgroundSecondColor,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: TransactionFormModal(
                transaction: t,
                accounts: accounts,
                categories: categories,
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTransactionModal(
    List<dynamic> accounts,
    List<dynamic> categories,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ConfigGlobal.backgroundSecondColor,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: TransactionFormModal(
                accounts: accounts,
                categories: categories,
              ),
            );
          },
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                 Transaction Form Modal (API resource real)                 */
/*  Campos necesarios según tu API:
    - amount (required)
    - type (income|expense) (required)
    - account_id (required)
    - category_id (required, del mismo type)
    - date (required)
    - note (optional)
   -------------------------------------------------------------------------- */

class TransactionFormModal extends StatefulWidget {
  final Transaction? transaction;
  final List<dynamic> accounts; // [{id,name,...}]
  final List<dynamic> categories; // [{id,name,type,...}]

  const TransactionFormModal({
    super.key,
    this.transaction,
    required this.accounts,
    required this.categories,
  });

  @override
  State<TransactionFormModal> createState() => TransactionFormModalState();
}

class TransactionFormModalState extends State<TransactionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense'; // por defecto gasto
  String? _selectedAccountId;
  String? _selectedCategoryId;

  final Map<String, String> _typeLabels = const {
    'income': 'Ingreso',
    'expense': 'Gasto',
  };

  @override
  void initState() {
    super.initState();

    final t = widget.transaction;
    if (t != null) {
      _selectedType = t.type;
      _selectedDate = t.date;
      _amountController.text = t.amount.toStringAsFixed(2);
      _noteController.text = t.note ?? '';
      _selectedAccountId = t.accountId?.toString();
      _selectedCategoryId = t.categoryId?.toString();
    } else {
      // defaults si hay data
      if (widget.accounts.isNotEmpty) {
        _selectedAccountId = "${widget.accounts.first['id']}";
      }
    }

    // si la categoría no es del tipo actual, la limpiamos
    _sanitizeCategoryByType();
  }

  void _sanitizeCategoryByType() {
    if (_selectedCategoryId == null) return;
    final cat = widget.categories.firstWhere(
      (c) => "${c['id']}" == _selectedCategoryId,
      orElse: () => null,
    );
    if (cat == null || (cat['type']?.toString() ?? '') != _selectedType) {
      _selectedCategoryId = null;
    }
  }

  List<dynamic> _categoriesForSelectedType() {
    return widget.categories
        .where((c) => (c['type']?.toString() ?? '') == _selectedType)
        .toList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Editar movimiento' : 'Agregar movimiento',
                style: TextStyle(
                  fontSize: ConfigGlobal.sizeTitle,
                  fontWeight: FontWeight.bold,
                  color: ConfigGlobal.backgroundColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildTypeDropdown(),
              const SizedBox(height: 12),
              _buildDateSelector(),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 12),
              _buildAccountDropdown(),
              const SizedBox(height: 12),
              _buildCategoryDropdown(),
              const SizedBox(height: 12),
              _buildNoteField(),
              const SizedBox(height: 18),
              _buildSubmitButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: const InputDecoration(
        labelText: "Tipo",
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedType = value;
          _selectedCategoryId = null; // cambia tipo => cambia catálogo
        });
      },
      items: _typeLabels.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Fecha",
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate))),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingrese un monto';
        final amount = double.tryParse(value);
        if (amount == null) return 'Monto inválido';
        if (amount <= 0) return 'El monto debe ser mayor a 0';
        return null;
      },
    );
  }

  Widget _buildAccountDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      decoration: const InputDecoration(
        labelText: "Cuenta",
        border: OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Seleccione una cuenta' : null,
      onChanged: (v) => setState(() => _selectedAccountId = v),
      items: widget.accounts.map<DropdownMenuItem<String>>((a) {
        return DropdownMenuItem<String>(
          value: "${a['id']}",
          child: Text(a['name']?.toString() ?? 'Sin nombre'),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDropdown() {
    final cats = _categoriesForSelectedType();

    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: _selectedType == 'income'
            ? "Categoría (Ingreso)"
            : "Categoría (Gasto)",
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Seleccione una categoría' : null,
      onChanged: (v) => setState(() => _selectedCategoryId = v),
      items: cats.map<DropdownMenuItem<String>>((c) {
        return DropdownMenuItem<String>(
          value: "${c['id']}",
          child: Text(c['name']?.toString() ?? 'Sin nombre'),
        );
      }).toList(),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Nota (opcional)',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null) return null;
        if (v.length > 500) return 'Máximo 500 caracteres';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(isEditing ? "Actualizar" : "Guardar"),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final amountParsed = double.tryParse(_amountController.text.trim());
    if (amountParsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido')),
      );
      return;
    }

    final isEditing = widget.transaction != null;

    final tx = Transaction(
      id: isEditing ? widget.transaction!.id : null,
      type: _selectedType,
      amount: amountParsed,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      accountId: int.parse(_selectedAccountId!),
      categoryId: int.parse(_selectedCategoryId!),

      // Mantén lo demás como estaba en tu modelo si existe, pero no lo uses para API
      // files: widget.transaction?.files ?? const [],
    );

    final provider = context.read<TransactionsProvider>();

    if (isEditing) {
      provider.updateTransaction(context, tx);
    } else {
      provider.addTransaction(context, tx);
    }

    Navigator.pop(context);
  }
}
