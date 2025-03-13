import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetSelectsService {
  static Future<Map<String, dynamic>> fetchData(List<String> fields) async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

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

    // Convertimos el array de campos a query parameters
    final String queryString = Uri.encodeQueryComponent(jsonEncode(fields));
    final Uri url = Uri.parse('$baseUrl/getData?fields=$queryString');
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true &&
            responseData['data'] is Map<String, dynamic>) {
          return responseData['data'];
        } else {
          throw Exception('Formato de datos incorrecto');
        }
      } else {
        throw Exception('Error al cargar los datos');
      }
    } catch (e) {
      return {};
    }
  }
}
