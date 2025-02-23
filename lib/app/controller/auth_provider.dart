import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  late SharedPreferences prefs;
  final AuthService _authService = AuthService();

  User? _currentUser;
  User? get currentUser => _currentUser; // Obtener el usuario actual

  AuthProvider() {
    _loadUser();
  }

  /// **Carga el usuario desde SharedPreferences**
  Future<void> _loadUser() async {
    prefs = await SharedPreferences.getInstance();
    String? storedUser = prefs.getString("_user");

    if (storedUser != null) {
      _currentUser = User.fromJson(jsonDecode(storedUser));
      notifyListeners();
    }
  }

  /// **Guarda el usuario en SharedPreferences**
  Future<void> _saveUser() async {
    if (_currentUser != null) {
      await prefs.setString("_user", jsonEncode(_currentUser!.toJson()));
    } else {
      await prefs.remove("_user"); // Elimina si no hay usuario
    }
  }

  /// **Login del usuario con el servicio de autenticación**
  Future<void> login(User user) async {
    try {
      bool success = await _authService.login(user.toJson());

      if (success) {
        _currentUser = user;
        await _saveUser();
        notifyListeners();
      } else {
        throw Exception('Failed to login user');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  /// **Logout del usuario**
  Future<void> logout() async {
    try {
      if (_currentUser == null) return;

      bool success = await _authService.logout(_currentUser!.toJson());

      if (success) {
        _currentUser = null;
        await _saveUser();
        notifyListeners();
      } else {
        throw Exception('Failed to logout user');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
