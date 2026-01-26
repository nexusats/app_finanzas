import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetSelectsService {
  static Map<String, dynamic>? _cache;
  static DateTime? _cacheAt;

  static Future<Map<String, dynamic>>? _inFlight;

  static String? _tokenCache;
  static DateTime? _tokenAt;

  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _tokenTtl = Duration(minutes: 30);

  static Future<String?> _getTokenCached() async {
    final now = DateTime.now();

    final tokenFresh = _tokenCache != null &&
        _tokenAt != null &&
        now.difference(_tokenAt!) < _tokenTtl;

    if (tokenFresh) return _tokenCache;

    final prefs = await SharedPreferences.getInstance();
    _tokenCache = prefs.getString("_token");
    _tokenAt = DateTime.now();
    return _tokenCache;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getTokenCached();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static bool _isCacheFresh() {
    if (_cache == null || _cacheAt == null) return false;
    return DateTime.now().difference(_cacheAt!) < _cacheTtl;
  }

  /// fetchData(['accounts','categories'])
  /// - cachea por TTL
  /// - dedupea requests simultáneas
  /// - permite forceRefresh para pull-to-refresh
  static Future<Map<String, dynamic>> fetchData(
    List<String> fields, {
    bool forceRefresh = false,
  }) async {
    // Si ya tengo cache fresco y no forzaron refresh, devuelvo directo
    if (!forceRefresh && _isCacheFresh()) {
      return _cache!;
    }

    // Si ya hay un request en vuelo, reutilízalo
    if (_inFlight != null) {
      return _inFlight!;
    }

    _inFlight = _fetchRemote(fields).then((data) {
      _cache = data;
      _cacheAt = DateTime.now();
      return data;
    }).whenComplete(() {
      _inFlight = null;
    });

    return _inFlight!;
  }

  static Future<Map<String, dynamic>> _fetchRemote(List<String> fields) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? "";
    if (baseUrl.isEmpty) return {};

    // Query: fields=["accounts","categories"]
    final queryString = Uri.encodeQueryComponent(jsonEncode(fields));
    final url = Uri.parse('$baseUrl/getData?fields=$queryString');

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) return {};

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return {};

      final success = decoded['success'] == true;
      final data = decoded['data'];

      if (success && data is Map<String, dynamic>) {
        return data;
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  /// Útil al cerrar sesión
  static void clearCache() {
    _cache = null;
    _cacheAt = null;
    _inFlight = null;

    _tokenCache = null;
    _tokenAt = null;
  }
}
