import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/goal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalProvider extends ChangeNotifier {
  final List<Goal> _goals = [];
  late SharedPreferences prefs;

  GoalProvider() {
    _initPreferences();
  }

  List<Goal> get goals => List.unmodifiable(_goals);

  Future<void> _initPreferences() async {
    prefs = await SharedPreferences.getInstance();
    await _loadGoals();
  }

  /// Cargar metas desde SharedPreferences
  Future<void> _loadGoals() async {
    final storedGoals = prefs.getStringList("_goals") ?? [];

    if (storedGoals.isNotEmpty) {
      _goals.clear();

      for (var jsonString in storedGoals) {
        try {
          final data = jsonDecode(jsonString);
          _goals.add(Goal.fromJson(data));
        } catch (e) {
          debugPrint("Error al decodificar JSON: $e");
        }
      }

      notifyListeners();
    }
  }

  /// Guardar metas en SharedPreferences
  Future<void> _saveGoals() async {
    await prefs.setStringList(
      "_goals",
      _goals.map((goal) => jsonEncode(goal.toJson())).toList(),
    );
  }

  /// Agregar una meta y guardar cambios
  Future<void> addGoal(Goal goal) async {
    _goals.add(goal);
    await _saveGoals();
    notifyListeners();
  }

  /// Eliminar una meta y guardar cambios
  Future<void> removeGoal(Goal goal) async {
    _goals.remove(goal);
    await _saveGoals();
    notifyListeners();
  }

  /// Eliminar todas las metas
  Future<void> clearGoals() async {
    _goals.clear();
    await prefs.remove("_goals");
    notifyListeners();
  }
}
