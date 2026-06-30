import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class AmbulanceApi {
  AmbulanceApi({
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

  Future<Map<String, dynamic>> getEta(String accidentId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ambulances/eta/$accidentId'),
      headers: _headers,
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> dispatch({
    required String ambulanceId,
    required String accidentId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/ambulances/dispatch'),
      headers: _headers,
      body: jsonEncode({
        'ambulance_id': ambulanceId,
        'accident_id': accidentId,
      }),
    );

    return _decode(response);
  }

  /// Returns a list of all registered ambulances.
  Future<List<Map<String, dynamic>>> listAmbulances() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/ambulances'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return []; // Return empty list on error — non-critical.
    }
    final body = response.body.isEmpty
        ? <dynamic>[]
        : jsonDecode(response.body) as List<dynamic>;
    return body.whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body['detail'] ?? 'Ambulance request failed';
      throw AmbulanceApiException(response.statusCode, detail.toString());
    }

    return body;
  }
}


class AmbulanceApiException implements Exception {
  AmbulanceApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'AmbulanceApiException($statusCode): $message';
}