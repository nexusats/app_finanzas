import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/category_expense.dart';
import 'package:app_finanzas/app/services/category_service.dart';

class CategoryEditScreen extends StatefulWidget {
  final CategoryExpense? category;

  const CategoryEditScreen({super.key, this.category});

  @override
  State<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final CategoryService _categoryService = CategoryService();

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
      final data = {
        "name": _nameController.text.trim(),
      };

      bool success;
      if (widget.category == null) {
        success = await _categoryService.createCategory(data);
      } else {
        success = await _categoryService.updateCategory(widget.category!.id!, data);
      }

      if (success) {
        Navigator.pop(context, true);
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
