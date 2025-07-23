import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/model/category_expense.dart';
import 'package:app_finanzas/app/services/category_service.dart';

class CategoryExpenseProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  final String _storageKey = 'categories_expense';

  List<CategoryExpense> _categories = [];
  bool _isLoading = true;

  List<CategoryExpense> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryExpenseProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await _loadCategoriesFromLocal();
    fetchFromApiAndUpdateLocal(); // ⚡ Refresca desde API sin bloquear UI
  }

  Future<void> _loadCategoriesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      _categories = (jsonDecode(data) as List)
          .map((e) => CategoryExpense.fromJson(e))
          .toList();
    } else {
      _categories = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadCategoriesFromLocalStorage() async {
    _isLoading = true;
    notifyListeners();
    await _loadCategoriesFromLocal();
  }

  Future<void> _saveCategoriesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_categories.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    final success = await _categoryService.createCategory(categoryData);
    if (success) {
      await fetchFromApiAndUpdateLocal();
    }
    return success;
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final success = await _categoryService.updateCategory(id, categoryData);
    if (success) {
      await fetchFromApiAndUpdateLocal();
    }
    return success;
  }

  Future<void> fetchFromApiAndUpdateLocal() async {
    final response = await _categoryService.getCategories();
    _categories = response.map((e) => CategoryExpense.fromJson(e)).toList();
    await _saveCategoriesToLocal();
    notifyListeners();
  }

  Future<void> removeCategory(CategoryExpense category) async {
    final success = await _categoryService.deleteCategory(category.id!);
    if (success) {
      _categories.removeWhere((e) => e.id == category.id);
      await _saveCategoriesToLocal();
      notifyListeners();
    }
  }
}
