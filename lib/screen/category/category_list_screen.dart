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
  // --------------------------
  // Íconos disponibles
  // --------------------------
  final Map<String, IconData> iconMap = {
    "shopping_cart": Icons.shopping_cart,
    "account_balance": Icons.account_balance,
    "savings": Icons.savings,
    "credit_card": Icons.credit_card,
    "home": Icons.home,
    "restaurant": Icons.restaurant,
    "local_gas_station": Icons.local_gas_station,
    "school": Icons.school,
    "health_and_safety": Icons.health_and_safety,

    // extras del map original
    "food": Icons.fastfood,
    "shopping": Icons.shopping_cart,
    "car": Icons.directions_car,
    "money": Icons.attach_money,
    "star": Icons.star,
    "category": Icons.category,
  };

  IconData _resolveIcon(String? name) {
    if (name == null) return Icons.category;
    return iconMap[name] ?? Icons.category;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider =
          Provider.of<CategoryExpenseProvider>(context, listen: false);
      provider.fetchFromApiAndUpdateLocal();
    });
  }

  void _navigateToEditScreen(
      BuildContext context, CategoryExpense? category) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.65, // Tamaño del modal
        child: CategoryEditModal(category: category),
      ),
    );

    if (result == true) {
      Provider.of<CategoryExpenseProvider>(context, listen: false)
          .fetchFromApiAndUpdateLocal();
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                _resolveIcon(category.icon),
                                size: 32,
                                color: ConfigGlobal.backgroundColor,
                              ),
                              title: Text(category.name),
                              subtitle: category.type != null
                                  ? Text(category.type!)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _navigateToEditScreen(
                                        context, category),
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                    'Eliminar Categoría'),
                                                content: Text(
                                                    '¿Estás seguro de eliminar la categoría ${category.name}'),
                                                actions: [
                                                  TextButton(
                                                    child:
                                                        const Text('Cancelar'),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                  TextButton(
                                                    child:
                                                        const Text('Eliminar'),
                                                    onPressed: () {
                                                      provider.removeCategory(
                                                          category);
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            )
                                          }),
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
