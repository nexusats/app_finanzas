import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "transactions";

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

  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(transactionData),
    );

    return response.statusCode == 201;
  }

  Future<List<dynamic>> getTransactions() async {
    final url = Uri.parse('$baseUrl/$module');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // soporte para respuesta paginada: data.data
      final data = body['data'];
      if (data is Map<String, dynamic> && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }

      // soporte por si alguna vez viene plana: data:[]
      if (body['data'] is List) {
        return body['data'] as List<dynamic>;
      }

      return [];
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) async {
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

  Future<bool> updateTransaction(
      int id, Map<String, dynamic> transactionData) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(transactionData),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteTransaction(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);

    return response.statusCode == 200;
  }
}
