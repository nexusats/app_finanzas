import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "goals";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("_token");
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Crear meta
  Future<bool> createGoal(Map<String, dynamic> goalData) async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(goalData),
    );

    return response.statusCode == 201;
  }

  // Obtener todas las metas
  Future<List<dynamic>> getGoals() async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      return [];
    }
  }

  // Obtener una meta por ID
  Future<Map<String, dynamic>?> getGoalById(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  }

  // Actualizar meta
  Future<bool> updateGoal(
      int id, Map<String, dynamic> goalData) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(goalData),
    );

    return response.statusCode == 200;
  }

  // Eliminar meta
  Future<bool> deleteGoal(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);

    return response.statusCode == 200;
  }
}
