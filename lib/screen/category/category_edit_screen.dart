import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/app/controller/category_provider.dart';

class CategoryEditModal extends StatefulWidget {
  final Category? category;

  const CategoryEditModal({super.key, this.category});

  @override
  State<CategoryEditModal> createState() => _CategoryEditModalState();
}

class _CategoryEditModalState extends State<CategoryEditModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _iconController;

  String? _selectedType;

  // Solo lo que soporta el API: income | expense
  final Map<String, String> categoryTypes = const {
    "income": "Ingreso",
    "expense": "Gasto",
  };

  final Map<String, IconData> icons = {
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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _iconController = TextEditingController(text: widget.category?.icon ?? '');

    // Si viene un type raro (legacy), lo limpiamos para no romper el API
    final t = widget.category?.type;
    _selectedType = (t != null && categoryTypes.containsKey(t)) ? t : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CategoryProvider>(context, listen: false);

    final name = _nameController.text.trim();
    final iconRaw = _iconController.text.trim();

    // API: icon nullable, si está vacío mandamos null
    final body = <String, dynamic>{
      "type": _selectedType, // required por API
      "name": name, // required por API
      "icon": iconRaw.isEmpty ? null : iconRaw,
    };

    bool success;
    if (widget.category == null) {
      success = await provider.createCategory(body);
    } else {
      success = await provider.updateCategory(widget.category!.id!, body);
    }

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Categoría guardada correctamente'
              : 'Error al guardar categoría',
        ),
      ),
    );
  }

  void _pickIcon() async {
    final icon = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final iconKeys = icons.keys.toList();

        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: GridView.builder(
            itemCount: iconKeys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemBuilder: (_, index) {
              final iconName = iconKeys[index];

              return GestureDetector(
                onTap: () => Navigator.pop(context, iconName),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[iconName], size: 28),
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
      setState(() => _iconController.text = icon);
    }
  }

  IconData _buildIcon(String? name) {
    return (name != null && icons[name] != null)
        ? icons[name]!
        : Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.category == null
                            ? "Nueva Categoría"
                            : "Editar Categoría",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3A3A8C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        if (value.trim().length > 120) {
                          return 'Máximo 120 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: "Tipo",
                        border: OutlineInputBorder(),
                      ),
                      items: categoryTypes.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      validator: (value) =>
                          value == null ? "Seleccione un tipo" : null,
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iconController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Icono (opcional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(_buildIcon(_iconController.text)),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // limpiar icono (para mandar null)
                            IconButton(
                              tooltip: 'Quitar',
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _iconController.text = ''),
                            ),
                            IconButton(
                              tooltip: 'Buscar',
                              icon: const Icon(Icons.search),
                              onPressed: _pickIcon,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A8C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveCategory,
                        child: const Text(
                          "Guardar",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
