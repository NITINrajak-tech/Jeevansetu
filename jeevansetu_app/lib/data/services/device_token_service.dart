import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class DeviceTokenService {
  DeviceTokenService({
    FirebaseMessaging? messaging,
    http.Client? client,
    String? backendBaseUrl,
    String? backendAuthToken,
  })  : _messaging = messaging,
        _client = client ?? http.Client(),
        _backendBaseUrl = backendBaseUrl ?? AppConstants.backendBaseUrl,
        _backendAuthToken = backendAuthToken ?? AppConstants.backendAuthToken {
    _messaging ??= _resolveMessagingInstance();
  }

  FirebaseMessaging? _resolveMessagingInstance() {
    if (kIsWeb) {
      return null;
    }

    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseMessaging? _messaging;
  final http.Client _client;
  final String _backendBaseUrl;
  final String _backendAuthToken;

  bool get hasBackendToken => _backendAuthToken.trim().isNotEmpty;

  bool get isMessagingAvailable => _messaging != null;

  Future<bool> requestNotificationPermission() async {
    if (_messaging == null) {
      return false;
    }

    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      // If Firebase Messaging is not fully configured on web, allow the app to continue.
      return false;
    }
  }

  Future<String?> getToken() async {
    if (_messaging == null) {
      return null;
    }
    try {
      final token = await _messaging!.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<String?> refreshAndFetchToken() async {
    if (_messaging == null) {
      return null;
    }
    await _messaging!.requestPermission();
    return getToken();
  }

  Future<void> syncTokenToBackend({String? token}) async {
    if (!hasBackendToken || _messaging == null) {
      return;
    }

    final resolvedToken = token ?? await getToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      return;
    }

    final response = await _client.post(
      Uri.parse('$_backendBaseUrl/auth/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_backendAuthToken',
      },
      body: jsonEncode({'fcm_token': resolvedToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DeviceTokenSyncException(response.statusCode, response.body);
    }
  }
}

class DeviceTokenSyncException implements Exception {
  DeviceTokenSyncException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'DeviceTokenSyncException($statusCode): $body';
}