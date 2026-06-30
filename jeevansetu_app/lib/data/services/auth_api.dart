import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class AuthApi {
  AuthApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConstants.backendBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'user',
        'fcm_token': fcmToken,
      }),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    String? fcmToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email_or_phone': emailOrPhone,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> updateFcmToken({
    required String fcmToken,
    required String authToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body['detail'] ?? 'Authentication failed';
      throw AuthApiException(response.statusCode, detail.toString());
    }
    return body;
  }
}

class AuthApiException implements Exception {
  AuthApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}
