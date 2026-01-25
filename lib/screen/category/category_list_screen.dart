import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_finanzas/config/global.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/screen/category/category_edit_screen.dart';
import 'package:app_finanzas/app/controller/category_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
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

  String _typeLabel(String? type) {
    if (type == 'income') return 'Ingreso';
    if (type == 'expense') return 'Gasto';
    return '';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CategoryProvider>(context, listen: false)
          .fetchFromApiAndUpdateLocal();
    });
  }

  Future<void> _navigateToEditScreen(
      BuildContext context, Category? category) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.65,
        child: CategoryEditModal(category: category),
      ),
    );

    // sin depender de "result == true" (para que refresque siempre)
    if (!mounted) return;
    Provider.of<CategoryProvider>(context, listen: false)
        .fetchFromApiAndUpdateLocal();
  }

  Future<void> _confirmArchive(
      CategoryProvider provider, Category category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archivar categoría'),
        content: Text('¿Seguro que deseas archivar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    provider.removeCategory(category);
    // opcional: refrescar del API por si el backend reordena / filtra
    await provider.fetchFromApiAndUpdateLocal();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categoría archivada')),
    );
  }

  Widget _skeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 8),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white, radius: 18),
            title: SizedBox(height: 14, width: double.infinity),
            subtitle: SizedBox(height: 12, width: 120),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        // Si el backend trae archivadas y no quieres mostrarlas:
        // final categories = provider.categories.where((c) => c.isArchived != true).toList();
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
                ? _skeletonList()
                : categories.isEmpty
                    ? const Center(child: Text('No hay categorías registradas'))
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchFromApiAndUpdateLocal(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final archived = category.isArchived == true;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: Icon(
                                  _resolveIcon(category.icon),
                                  size: 32,
                                  color: archived
                                      ? Colors.grey
                                      : ConfigGlobal.backgroundColor,
                                ),
                                title: Text(category.name),
                                subtitle: (category.type != null &&
                                        category.type!.isNotEmpty)
                                    ? Text(_typeLabel(category.type))
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: archived
                                            ? Colors.grey
                                            : Colors.blue,
                                      ),
                                      onPressed: archived
                                          ? null
                                          : () => _navigateToEditScreen(
                                              context, category),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.archive,
                                        color:
                                            archived ? Colors.grey : Colors.red,
                                      ),
                                      onPressed: archived
                                          ? null
                                          : () => _confirmArchive(
                                              provider, category),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
