import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapper {
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (_) {
      // The app can still run in demo mode when Firebase native config is absent.
    }
  }
}