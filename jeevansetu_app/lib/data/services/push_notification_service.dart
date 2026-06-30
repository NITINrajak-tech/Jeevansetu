import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

class PushNotificationService {
  static Future<void> initialize() async {
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final messageType = data['type']?.toString();
    if (messageType != 'accident_alert') {
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.title ?? 'Accident alert received'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            context.goNamed(AppRoutes.accidentAlert);
          },
        ),
      ),
    );
  }
}