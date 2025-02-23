import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

  final String module = "auth";

  Future<bool> login(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$module/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  // Obtener usuario logeado
  Future<Map<String, dynamic>?> getUser(int id) async {
    final url = Uri.parse('$baseUrl/user/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      return null;
    }
  }

  Future<bool> logout(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$module/logout');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }
}
