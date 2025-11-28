import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/app/controller/category_expense_provider.dart';
import 'package:app_finanzas/app/model/category_expense.dart';

class CategoryEditScreen extends StatefulWidget {
  final CategoryExpense? category;

  const CategoryEditScreen({super.key, this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _iconController;

  String? _selectedType;

  final Map<String, String> categoryTypes = {
    "income": "Ingreso",
    "expense": "Gasto",
    "saving": "Ahorro",
    "debt": "Deuda",
  };

  final List<String> iconOptions = [
    "shopping_cart",
    "account_balance",
    "savings",
    "credit_card",
    "home",
    "restaurant",
    "local_gas_station",
    "school",
    "health_and_safety",
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? '');
    _selectedType = widget.category?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final provider =
        Provider.of<CategoryExpenseProvider>(context, listen: false);

    final body = {
      "name": _nameController.text.trim(),
      "icon": _iconController.text.trim(),
      "type": _selectedType,
    };

    bool success = false;

    if (widget.category == null) {
      success = await provider.createCategory(body);
    } else {
      success = await provider.updateCategory(widget.category!.id!, body);
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría guardada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar categoría')),
      );
    }
  }

  void _pickIcon() async {
    final icon = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: GridView.builder(
            itemCount: iconOptions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final iconName = iconOptions[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context, iconName),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_buildIcon(iconName), size: 28),
                    const SizedBox(height: 6),
                    Text(iconName, style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (icon != null) {
      setState(() {
        _iconController.text = icon;
      });
    }
  }

  IconData _buildIcon(String name) {
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              /// Selector tipo
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: categoryTypes.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: "Tipo",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) =>
                    value == null ? "Seleccione un tipo" : null,
              ),
              const SizedBox(height: 16),

              /// Icono
              TextFormField(
                controller: _iconController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Icono',
                  prefixIcon: Icon(
                    _buildIcon(_iconController.text),
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _pickIcon,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCategory,
                  child: const Text("Guardar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
