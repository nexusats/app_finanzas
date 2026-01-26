import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_finanzas/app/core/loading_registry.dart';

class TransactionService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "transactions";

  String? _tokenCache;
  DateTime? _tokenAt;

  Future<String?> _getToken() async {
    final fresh = _tokenCache != null &&
        _tokenAt != null &&
        DateTime.now().difference(_tokenAt!).inMinutes < 30;

    if (fresh) return _tokenCache;

    final prefs = await SharedPreferences.getInstance();
    _tokenCache = prefs.getString("_token");
    _tokenAt = DateTime.now();
    return _tokenCache;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> createTransaction(Map<String, dynamic> transactionData) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(transactionData),
      );
      return response.statusCode == 201;
    });
  }

  Future<List<dynamic>> getTransactions() {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);

      final data = body['data'];
      if (data is Map<String, dynamic> && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }

      if (body['data'] is List) {
        return body['data'] as List<dynamic>;
      }

      return [];
    });
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    });
  }

  Future<bool> updateTransaction(int id, Map<String, dynamic> transactionData) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(transactionData),
      );
      return response.statusCode == 200;
    });
  }

  Future<bool> deleteTransaction(int id) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200;
    });
  }
}
