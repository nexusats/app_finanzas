import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/goal.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/goal_service.dart';

class GoalsProvider extends ChangeNotifier {
  final List<Goal> _goals = [];
  SharedPreferences? _prefs;
  final GoalService _goalService = GoalService();
  Goal? _selectedGoal;
  bool _isLoading = true; // Estado de carga

  Goal? get selectedGoal => _selectedGoal;
  List<Goal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading; // Getter para el estado de carga

  GoalsProvider() {
    _loadGoals();
  }

  Future<void> fetchGoals() async {
    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    _isLoading = true;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();

    try {
      final fetchedGoals = await _goalService.getGoals();
      _goals
        ..clear()
        ..addAll(fetchedGoals.map((e) {
          final goal = Goal.fromJson(e as Map<String, dynamic>);
          return goal;
        }));

      await _saveGoals();
    } catch (_) {
      final storedGoals = _prefs?.getStringList("_goals");
      if (storedGoals != null) {
        _goals
          ..clear()
          ..addAll(storedGoals
              .map((json) => Goal.fromJson(jsonDecode(json))));
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGoalById(int id) async {
    if (_selectedGoal?.id == id) return;

    try {
      final data = await _goalService.getGoalById(id);
      _selectedGoal = data != null ? Goal.fromJson(data) : null;
    } catch (_) {
      _selectedGoal = null;
    }
    notifyListeners();
  }

  Future<void> _saveGoals() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(
      "_goals",
      _goals.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  Future<void> addGoal(
      BuildContext context, Goal goal) async {
    try {
      final success =
          await _goalService.createGoal(goal.toJson());
      if (success) {
        _goals.add(goal);
        await _saveGoals();
        notifyListeners();

        // Verifica si el widget está montado antes de mostrar el Snackbar
        if (context.mounted) {
          CustomSnackbar.show(context, "Meta agregada exitosamente");
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(context, "Error al agregar la meta",
              isError: true);
        }
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error de conexión: $error",
            isError: true);
      }
    }
  }

  Future<void> removeGoal(
      BuildContext context, Goal goal) async {
    _goals.remove(goal);
    await _saveGoals();
    notifyListeners();
    CustomSnackbar.show(context, "Meta eliminada");
  }
}
