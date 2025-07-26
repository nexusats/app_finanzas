import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_finanzas/app/model/user.dart';
import 'package:app_finanzas/screen/home_screen.dart';
import 'package:app_finanzas/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/screen/auth/login_screen.dart';
import 'package:app_finanzas/app/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  final AuthService _authService = AuthService();

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token?.isNotEmpty ?? false;

  /// **Constructor: carga usuario y token al iniciar**
  AuthProvider() {
    _loadUser();
  }

  /// **Carga usuario y token desde SharedPreferences**
  Future<void> _loadUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedUser = _prefs?.getString("_user");
    final storedToken = _prefs?.getString("_token");

    if (storedUser != null && storedToken != null && storedToken.isNotEmpty) {
      _currentUser = User.fromJson(jsonDecode(storedUser));
      _token = storedToken;
    } else {
      _clearSession();
    }

    notifyListeners();
  }

  /// **Guarda usuario y token en SharedPreferences**
  Future<void> _saveUser() async {
    _prefs ??= await SharedPreferences.getInstance();

    if (_currentUser != null && _token != null) {
      await _prefs!.setString("_user", jsonEncode(_currentUser!.toJson()));
      await _prefs!.setString("_token", _token!);
    } else {
      _clearSession();
    }
  }

  /// **Elimina datos de sesión**
  Future<void> _clearSession() async {
    _currentUser = null;
    _token = null;
    await _prefs?.remove("_user");
    await _prefs?.remove("_token");
    // Elimina datos almacenadas si es necesario
    await _prefs?.remove("categories_expense");
    await _prefs?.remove("_transactions");
    await _prefs?.remove("_goals");
    notifyListeners();
  }

  /// **Login del usuario**
  Future<void> login(BuildContext context, Map<String, dynamic> userData) async {
    try {
      final result = await _authService.login(userData);

      if (result["success"] == true) {
        _currentUser = result["user"] != null ? User.fromJson(result["user"]) : null;
        _token = result["token"] ?? "";

        if (_token!.isEmpty) {
          CustomSnackbar.show(context, "⚠️ Advertencia: el token está vacío", isError: true);
          return;
        }

        await _saveUser();
        notifyListeners();

        CustomSnackbar.show(context, "Inicio de sesión exitoso");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        CustomSnackbar.show(context, result["message"] ?? "Error desconocido", isError: true);
      }
    } catch (error) {
      CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
    }
  }

  /// **Register del usuario**
  Future<void> register(BuildContext context, Map<String, dynamic> userData) async {
    try {
      final result = await _authService.register(userData);

      if (result["success"] == true) {
        _currentUser = result["user"] != null ? User.fromJson(result["user"]) : null;
        _token = result["token"] ?? "";

        if (_token!.isEmpty) {
          CustomSnackbar.show(context, "⚠️ Advertencia: el token está vacío", isError: true);
          return;
        }

        await _saveUser();
        notifyListeners();

        CustomSnackbar.show(context, "Cuenta creada con exitoso");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        CustomSnackbar.show(context, result["message"] ?? "Error desconocido", isError: true);
      }
    } catch (error) {
      CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
    }
  }

  /// **Reset Password del usuario**
  Future<void> resetPassword(BuildContext context, Map<String, dynamic> userData) async {
    try {
      final result = await _authService.resetPassword(userData);

      if (result["success"] == true) {
        CustomSnackbar.show(context, "Correo enviado para restablecer la contraseña con éxito");
      } else {
        CustomSnackbar.show(context, result["message"] ?? "Error desconocido", isError: true);
      }
    } catch (error) {
      CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
    }
  }

  /// **Logout del usuario**
  Future<void> logout(BuildContext context) async {
    try {
      if (_token == null) return;

      final result = await _authService.logout(_token!);

      if (result["success"] == true) {
        _clearSession();
        CustomSnackbar.show(context, "Sesión cerrada correctamente");

        _redirectToLogin(context);
      } else {
        if (result["statusCode"] == 401) {
          CustomSnackbar.show(context, "⚠️ Sesión expirada, vuelve a iniciar sesión", isError: true);
          _clearSession();
          _redirectToLogin(context);
        } else {
          CustomSnackbar.show(context, result["message"] ?? "Error al cerrar sesión", isError: true);
        }
      }
    } catch (error) {
      CustomSnackbar.show(context, "Error de conexión: $error", isError: true);
    }
  }

  /// **Redirige a la pantalla de login eliminando el historial**
  void _redirectToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
