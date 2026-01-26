import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_finanzas/app/core/loading_registry.dart';

class AccountService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";
  final String module = "accounts";

  String? _tokenCache;
  DateTime? _tokenAt;
  static const Duration _tokenTtl = Duration(minutes: 30);

  Future<String?> _getTokenCached() async {
    final now = DateTime.now();

    final fresh = _tokenCache != null &&
        _tokenAt != null &&
        now.difference(_tokenAt!) < _tokenTtl;

    if (fresh) return _tokenCache;

    final prefs = await SharedPreferences.getInstance();
    _tokenCache = prefs.getString("_token");
    _tokenAt = DateTime.now();
    return _tokenCache;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getTokenCached();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> createAccount(Map<String, dynamic> accountData) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(accountData),
      );

      return response.statusCode == 201;
    });
  }

  Future<List<dynamic>> getAccounts() {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];

      final data = decoded['data'];

      // Caso 1: data ya es lista
      if (data is List) return data;

      // Caso 2: data paginado: { data: [...] }
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is List) return innerData;

        // Caso 3: data trae { accounts: [...] }
        final accounts = data['accounts'];
        if (accounts is List) return accounts;
      }

      return [];
    });
  }

  Future<Map<String, dynamic>?> getAccountById(int id) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    });
  }

  Future<bool> updateAccount(int id, Map<String, dynamic> accountData) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(accountData),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    });
  }

  Future<bool> deleteAccount(int id) {
    return LoadingRegistry.run(() async {
      final url = Uri.parse('$baseUrl/$module/$id');
      final headers = await _getHeaders();

      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200;
    });
  }
}
