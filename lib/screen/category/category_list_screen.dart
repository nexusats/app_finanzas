import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app_finanzas/app/model/category_expense.dart';
import 'package:app_finanzas/app/services/category_service.dart';
import 'package:app_finanzas/screen/category/category_edit_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<CategoryExpense>> _categoriesFuture;
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = _fetchAndConvertCategories();
    });
  }

  Future<List<CategoryExpense>> _fetchAndConvertCategories() async {
    final response = await _categoryService.getCategories();
    return response.map((e) => CategoryExpense.fromJson(e)).toList();
  }

  Future<void> _deleteCategory(int id) async {
    final success = await _categoryService.deleteCategory(id);
    if (success) {
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría eliminada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la categoría')),
      );
    }
  }

  void _navigateToEditScreen(CategoryExpense? category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(category: category),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías de Gastos'),
      ),
      body: FutureBuilder<List<CategoryExpense>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay categorías registradas'));
          } else {
            final categories = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(category.nameCategory),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditScreen(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(category.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),

      // FAB expandible
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayOpacity: 0.1,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Nueva Categoría',
            onTap: () => _navigateToEditScreen(null),
          ),
          SpeedDialChild(
            child: const Icon(Icons.refresh),
            label: 'Refrescar',
            onTap: _loadCategories,
          ),
        ],
      ),
    );
  }
}
