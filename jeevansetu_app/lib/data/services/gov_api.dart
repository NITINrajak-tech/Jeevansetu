import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class GovApi {
  GovApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.backendBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Always reads from AppConstants so the JWT set after login is used.
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AppConstants.backendAuthToken.trim().isNotEmpty)
          'Authorization': 'Bearer ${AppConstants.backendAuthToken}',
      };

  Future<Map<String, dynamic>> fetchOperationsDashboard() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/gov/operations'),
      headers: _headers,
    );

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body['detail'] ?? 'Operations dashboard request failed';
      throw GovApiException(response.statusCode, detail.toString());
    }

    return body;
  }
}

class GovApiException implements Exception {
  GovApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'GovApiException($statusCode): $message';
}