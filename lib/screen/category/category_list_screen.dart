import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app_finanzas/app/model/category_expense.dart';
import 'package:app_finanzas/screen/category/category_edit_screen.dart';
import 'package:app_finanzas/app/controller/category_expense_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<CategoryExpenseProvider>(context, listen: false);
      provider.fetchFromApiAndUpdateLocal(); // Carga automática al iniciar
    });
  }

  void _navigateToEditScreen(BuildContext context, CategoryExpense? category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(category: category),
      ),
    );

    if (result == true) {
      Provider.of<CategoryExpenseProvider>(context, listen: false).fetchFromApiAndUpdateLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryExpenseProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: AppBar(
              backgroundColor: ConfigGlobal.backgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
            ),
          ),
          body: Container(
            padding: const EdgeInsets.only(top: 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                    ? const Center(child: Text('No hay categorías registradas'))
                    : ListView.builder(
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
                                    onPressed: () => _navigateToEditScreen(context, category),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => provider.removeCategory(category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          floatingActionButton: SpeedDial(
            icon: Icons.menu,
            activeIcon: Icons.close,
            backgroundColor: ConfigGlobal.backgroundColor,
            foregroundColor: Colors.white,
            overlayOpacity: 0.1,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'Nueva Categoría',
                onTap: () => _navigateToEditScreen(context, null),
              ),
              SpeedDialChild(
                child: const Icon(Icons.refresh),
                label: 'Refrescar',
                onTap: () => provider.fetchFromApiAndUpdateLocal(),
              ),
            ],
          ),
        );
      },
    );
  }
}
