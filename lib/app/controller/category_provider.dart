import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/category.dart';
import 'package:app_finanzas/app/services/category_service.dart';
import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:app_finanzas/app/model/sync_status.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

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
    final cached = await LocalDatabase.getCategories();
    _categories
      ..clear()
      ..addAll(_visibleCategories(cached));
    notifyListeners();
  }

  Future<void> _saveToLocal() async {
    await LocalDatabase.saveCategories(_categories);
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
      if (!await _isOnline()) return;
      final response = await _categoryService.getCategories();

      // OJO: lista vacía puede ser válida. No lo trates como error.
      _categories
        ..clear()
        ..addAll(
          response
              .map((e) => Category.fromJson(e))
              .map(
                (category) => Category(
                  id: category.id,
                  name: category.name,
                  type: category.type,
                  icon: category.icon,
                  isArchived: category.isArchived,
                  createdAt: category.createdAt,
                  updatedAt: category.updatedAt,
                  syncStatus: SyncStatus.synced,
                ),
              )
              .toList(),
        );

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
    if (await _isOnline()) {
      final ok = await _categoryService.createCategory(categoryData);
      if (ok) {
        await refresh();
      }
      return ok;
    }

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final category = Category(
      id: tempId,
      name: (categoryData['name'] ?? '').toString(),
      type: categoryData['type']?.toString(),
      icon: categoryData['icon']?.toString(),
      syncStatus: SyncStatus.pendingCreate,
    );
    _categories.add(category);
    await LocalDatabase.upsertCategory(category);
    notifyListeners();
    return true;
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> categoryData) async {
    if (await _isOnline()) {
      final ok = await _categoryService.updateCategory(id, categoryData);
      if (ok) {
        await refresh();
      }
      return ok;
    }

    final index = _categories.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final existing = _categories[index];
    final updated = Category(
      id: existing.id,
      name: (categoryData['name'] ?? existing.name).toString(),
      type: categoryData['type']?.toString() ?? existing.type,
      icon: categoryData['icon']?.toString() ?? existing.icon,
      isArchived: categoryData['is_archived'] as bool? ?? existing.isArchived,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
    );
    _categories[index] = updated;
    await LocalDatabase.upsertCategory(updated);
    notifyListeners();
    return true;
  }

  Future<void> removeCategory(Category category) async {
    // Optimista: quita local primero (UI rápida)
    _categories.removeWhere((e) => e.id == category.id);
    notifyListeners();
    if (!await _isOnline()) {
      final pending = Category(
        id: category.id,
        name: category.name,
        type: category.type,
        icon: category.icon,
        isArchived: category.isArchived,
        createdAt: category.createdAt,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingDelete,
      );
      await LocalDatabase.upsertCategory(pending);
      return;
    }

    if (category.id == null) return;
    final ok = await _categoryService.deleteCategory(category.id!);
    if (!ok) {
      await refresh();
    } else {
      _lastFetchAt = DateTime.now();
      await LocalDatabase.removeCategory(category);
    }
  }

  Future<void> clear() async {
    _categories.clear();
    _isLoading = false;
    _loadedOnce = false;
    _lastFetchAt = null;
    await LocalDatabase.saveCategories([]);
    notifyListeners();
  }

  List<Category> _visibleCategories(List<Category> categories) {
    return categories
        .where((category) => category.syncStatus != SyncStatus.pendingDelete)
        .toList();
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
