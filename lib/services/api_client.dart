import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({
    http.Client? client,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _client = client ?? http.Client();

  Future<dynamic> get(String path) async {
    final response = await _client.get(_uri(path));
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await _client.patch(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (body is Map<String, dynamic> && body['detail'] != null) {
      throw ApiException(body['detail'].toString());
    }

    throw ApiException('Error de conexion con el servidor');
  }
}
