import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/app/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  static const String _storageKey = 'categories';

  final List<Category> _categories = [];
  bool _isLoading = false;

  bool _loadedOnce = false;
  Future<void>? _inFlight;

  // TTL simple para no pedir lo mismo cada vez que abres la pantalla
  static const Duration _ttl = Duration(minutes: 10);
  DateTime? _lastFetchAt;

  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;

  CategoryProvider() {
    // Solo calienta desde local. Nada de API aquí.
    _warmFromLocal();
  }

  Future<void> _warmFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _categories
          ..clear()
          ..addAll(decoded.map((e) => Category.fromJson(e)).toList());
      }
    } catch (_) {
      // cache corrupto? lo ignoramos
    }

    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_categories.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  bool _isFresh() {
    if (_lastFetchAt == null) return false;
    return DateTime.now().difference(_lastFetchAt!) < _ttl;
  }

  /// Llamada recomendada desde UI:
  /// - la primera vez: intenta API
  /// - luego respeta TTL (no spamea)
  Future<void> fetchIfNeeded({bool force = false}) async {
    if (_inFlight != null) return _inFlight!;
    if (_loadedOnce && !force && _isFresh()) return;

    _inFlight = _fetchFromApi(forceLoadingUi: !_loadedOnce)
        .whenComplete(() => _inFlight = null);

    return _inFlight!;
  }

  /// Para pull-to-refresh o acciones donde sí quieres traer lo último
  Future<void> refresh() => fetchIfNeeded(force: true);

  Future<void> _fetchFromApi({required bool forceLoadingUi}) async {
    if (forceLoadingUi) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _categoryService.getCategories();

      // OJO: lista vacía puede ser válida. No lo trates como error.
      _categories
        ..clear()
        ..addAll(response.map((e) => Category.fromJson(e)).toList());

      _loadedOnce = true;
      _lastFetchAt = DateTime.now();
      await _saveToLocal();
    } catch (_) {
      // si falla, te quedas con el cache local (ya está cargado)
    } finally {
      if (forceLoadingUi) {
        _isLoading = false;
        notifyListeners();
      } else {
        // igual notifica por si cambió data
        notifyListeners();
      }
    }
  }

  // -------- CRUD (optimista + refresh controlado) --------

  Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    final ok = await _categoryService.createCategory(categoryData);
    if (ok) {
      // Trae el listado real (ids, orden, etc)
      await refresh();
    }
    return ok;
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final ok = await _categoryService.updateCategory(id, categoryData);
    if (ok) {
      await refresh();
    }
    return ok;
  }

  Future<void> removeCategory(Category category) async {
    // Optimista: quita local primero (UI rápida)
    _categories.removeWhere((e) => e.id == category.id);
    notifyListeners();
    await _saveToLocal();

    final ok = await _categoryService.deleteCategory(category.id!);
    if (!ok) {
      // si falló, re-sincroniza
      await refresh();
    } else {
      // marca fetch reciente para no volver a pedir inmediatamente
      _lastFetchAt = DateTime.now();
    }
  }

  Future<void> clear() async {
    _categories.clear();
    _isLoading = false;
    _loadedOnce = false;
    _lastFetchAt = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    notifyListeners();
  }
}
