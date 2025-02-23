import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/model/category_expense.dart';

class CategoryExpenseProvider extends ChangeNotifier {
  final List<CategoryExpense> _categories = [];
  late SharedPreferences prefs;

  CategoryExpenseProvider() {
    _initPreferences();
  }

  List<CategoryExpense> get categories => List.unmodifiable(_categories);

  Future<void> _initPreferences() async {
    prefs = await SharedPreferences.getInstance();
    await _loadCategories();
  }

  /// Cargar categorías desde SharedPreferences
  Future<void> _loadCategories() async {
    final storedCategories = prefs.getStringList("_categories") ?? [];

    if (storedCategories.isNotEmpty) {
      _categories.clear();

      for (var jsonString in storedCategories) {
        try {
          final data = jsonDecode(jsonString);
          _categories.add(CategoryExpense.fromJson(data));
        } catch (e) {
          debugPrint("Error al decodificar JSON: $e");
        }
      }

      notifyListeners();
    }
  }

  /// Guardar categorías en SharedPreferences
  Future<void> _saveCategories() async {
    final jsonCategories = _categories.map((category) {
      return jsonEncode(category.toJson());
    }).toList();

    await prefs.setStringList("_categories", jsonCategories);
  }

  /// Agregar una categoría y guardar cambios
  Future<void> addCategory(CategoryExpense category) async {
    _categories.add(category);
    await _saveCategories();
    notifyListeners();
  }

  /// Eliminar una categoría y guardar cambios
  Future<void> removeCategory(CategoryExpense category) async {
    _categories.remove(category);
    await _saveCategories();
    notifyListeners();
  }

  /// Eliminar todas las categorías
  Future<void> clearCategories() async {
    _categories.clear();
    await prefs.remove("_categories");
    notifyListeners();
  }
}
