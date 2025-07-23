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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.nameCategory ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CategoryExpenseProvider>(context, listen: false);
      final name = _nameController.text.trim();
      bool success = false;

      if (widget.category == null) {
        // Crear
        success = await provider.createCategory({"name": name});
      } else {
        // Actualizar
        success = await provider.updateCategory(widget.category!.id!, {"name": name});
      }

      if (success) {
        Navigator.pop(context); // Sin necesidad de pasar `true`
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría guardada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error al guardar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Nueva Categoría' : 'Editar Categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCategory,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
