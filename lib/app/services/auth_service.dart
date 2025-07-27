import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "auth";

  /// **Login de usuario**
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$module/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData["message"],
          "user": responseData["user"],
          "token": responseData["token"],
        };
      } else {
        return {"success": false, "message": responseData["message"] ?? "Error en las credenciales"};
      }
    } catch (error) {
      return {"success": false, "message": "Error de conexión: $error"};
    }
  }

  /// **Register de usuario**
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData["message"],
          "user": responseData["user"],
          "token": responseData["token"],
        };
      } else {
        return {"success": false, "message": responseData["message"] ?? "Error en las credenciales"};
      }
    } catch (error) {
      return {"success": false, "message": "Error de conexión: $error"};
    }
  }

  /// **Reset Password del usuario**
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": responseData["message"] ?? "Enlace de restablecimiento enviado"};
      } else {
        return {"success": false, "message": responseData["message"] ?? "Error al enviar el enlace de restablecimiento"};
      }
    } catch (error) {
      return {"success": false, "message": "Error de conexión: $error"};
    }
  }

  /// **Logout de usuario**
  Future<Map<String, dynamic>> logout(String token) async {
    final url = Uri.parse('$baseUrl/$module/logout');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "message": responseData["message"] ?? "Sesión cerrada correctamente", "statusCode": response.statusCode};
      } else {
        return {"success": false, "message": responseData["message"] ?? "Error al cerrar sesión", "statusCode": response.statusCode};
      }
    } catch (error) {
      return {"success": false, "message": "Error de conexión: $error"};
    }
  }
}
