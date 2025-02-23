import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GetSelectsService {
  static Future<Map<String, dynamic>> fetchData(List<String> fields) async {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

    // Convertimos el array de campos a query parameters
    final String queryString = Uri.encodeQueryComponent(jsonEncode(fields));
    final Uri url = Uri.parse('$baseUrl/getData?fields=$queryString'); 

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] is Map<String, dynamic>) {
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
