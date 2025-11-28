import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "expenses-categories";

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

  Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(categoryData),
    );
    print(response.body);
    return response.statusCode == 201;
  }

  Future<List<dynamic>> getCategories() async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'];
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> categoryData) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(categoryData),
    );

    return response.statusCode == 201;
  }

  Future<bool> deleteCategory(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    return response.statusCode == 200;
  }
}
