import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/model/user.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/screen/home_screen.dart';
import 'package:app_finanzas/app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  final AuthService _authService = AuthService();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// **Constructor: carga usuario y token al iniciar**
  AuthProvider() {
    _loadUser();
  }

  /// **Muestra alertas tipo Snackbar**
  void _showSnackbar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// **Carga usuario y token desde SharedPreferences**
  Future<void> _loadUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedUser = _prefs?.getString("_user");
    final storedToken = _prefs?.getString("_token");

    if (storedUser != null && storedToken != null) {
      _currentUser = User.fromJson(jsonDecode(storedUser));
      _token = storedToken;
      notifyListeners();
    }
  }

  /// **Guarda o elimina usuario y token en SharedPreferences**
  Future<void> _saveUser() async {
    _prefs ??= await SharedPreferences.getInstance();

    if (_currentUser != null && _token != null) {
      await _prefs!.setString("_user", jsonEncode(_currentUser!.toJson()));
      await _prefs!.setString("_token", _token!);
    } else {
      await _prefs!.remove("_user");
      await _prefs!.remove("_token");
    }
  }

  /// **Login del usuario**
  Future<void> login(
      BuildContext context, Map<String, dynamic> userData) async {
    try {
      final result = await _authService.login(userData);
      print("Respuesta del login: $result");

      if (result["success"] == true) {
        _currentUser =
            result["user"] != null ? User.fromJson(result["user"]) : null;
        _token = result["token"] ?? ""; // Usa un valor por defecto si es null

        if (_token!.isEmpty) {
          print("⚠️ Advertencia: el token está vacío");
        }

        await _saveUser();
        notifyListeners();

        print("Usuario autenticado: $_currentUser");
        print("Token guardado: $_token");

        _showSnackbar(context, "Inicio de sesión exitoso");

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showSnackbar(context, result["message"] ?? "Error desconocido",
            isError: true);
      }
    } catch (error) {
      print("Error en login: $error");
      _showSnackbar(context, "Error de conexión: $error", isError: true);
    }
  }

  /// **Logout del usuario**
  Future<void> logout(BuildContext context) async {
    try {
      if (_token == null) return;

      final result = await _authService.logout(_token!);

      if (result["success"] == true) {
        _currentUser = null;
        _token = null;
        await _saveUser();
        notifyListeners();

        _showSnackbar(context, "Sesión cerrada correctamente");

        // Redirigir a la pantalla de inicio de sesión
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        _showSnackbar(context, result["message"], isError: true);
      }
    } catch (error) {
      print("Error en logout: $error");
      _showSnackbar(context, "Error de conexión: $error", isError: true);
    }
  }
}
