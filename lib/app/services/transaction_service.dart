import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? "";

  final String module = "transactions";

  // Crear transacción
  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    final url = Uri.parse('$baseUrl/$module');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(transactionData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }

  // Obtener todas las transacciones
  Future<List<dynamic>> getTransactions() async {
    final url = Uri.parse('$baseUrl/$module');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      return [];
    }
  }

  // Obtener una transacción por ID
  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      return null;
    }
  }

  // Actualizar transacción
  Future<bool> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(transactionData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // Eliminar transacción
  Future<bool> deleteTransaction(int id) async {
    final url = Uri.parse('$baseUrl/$module/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
