import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_finanzas/app/model/goal.dart';
import 'package:app_finanzas/app/services/goal_service.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';

class GoalsProvider extends ChangeNotifier {
  final List<Goal> _goals = [];
  final GoalService _goalService = GoalService();
  SharedPreferences? _prefs;
  Goal? _selectedGoal;
  bool _isLoading = true;

  List<Goal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  Goal? get selectedGoal => _selectedGoal;

  GoalsProvider() {
    _loadGoals();
  }

  Future<void> fetchGoals() async => _loadGoals();

  Future<void> _loadGoals() async {
    _isLoading = true;
    notifyListeners();

    _prefs ??= await SharedPreferences.getInstance();

    try {
      final fetchedGoals = await _goalService.getGoals();

      _goals
        ..clear()
        ..addAll(fetchedGoals.map((e) => Goal.fromJson(e)));
      await _saveGoals();
    } catch (e) {
      final cachedGoals = _prefs?.getStringList("_goals");
      if (cachedGoals != null) {
        _goals
          ..clear()
          ..addAll(cachedGoals.map((json) => Goal.fromJson(jsonDecode(json))));
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
    } catch (e) {
      _selectedGoal = null;
    }

    notifyListeners();
  }

  Future<void> _saveGoals() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(
      "_goals",
      _goals.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }

  Future<void> addGoal(BuildContext context, Goal goal) async {
    try {
      final success = await _goalService.createGoal(goal.toJson());
      if (success) {
        _goals.add(goal);
        await _saveGoals();
        notifyListeners();

        if (context.mounted) {
          CustomSnackbar.show(context, "Meta agregada exitosamente");
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(context, "Error al agregar la meta", isError: true);
        }
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
      }
    }
  }

  Future<void> updateGoal(BuildContext context, Goal goal) async {
    try {
      final success = await _goalService.updateGoal(goal.id, goal.toJson());
      if (success) {
        final index = _goals.indexWhere((g) => g.id == goal.id);
        if (index != -1) {
          _goals[index] = goal;
          await _saveGoals();
          notifyListeners();

          if (context.mounted) {
            CustomSnackbar.show(context, "Meta actualizada exitosamente");
          }
        }
      } else {
        if (context.mounted) {
          CustomSnackbar.show(context, "Error al actualizar la meta", isError: true);
        }
      }
    } catch (error) {
      if (context.mounted) {
        CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
      }
    }
  }

  Future<void> removeGoal(BuildContext context, Goal goal) async {
    try {
      final success = await _goalService.deleteGoal(goal.id);
      if (success) {
        _goals.removeWhere((g) => g.id == goal.id);
        await _saveGoals();
        notifyListeners();
        CustomSnackbar.show(context, "Meta eliminada");
      } else {
        CustomSnackbar.show(context, "Error al eliminar la meta", isError: true);
      }
    } catch (e) {
      CustomSnackbar.show(context, "Error al eliminar: $e", isError: true);
    }
  }

  void selectGoal(Goal? goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  void clearSelectedGoal() {
    _selectedGoal = null;
    notifyListeners();
  }
}
