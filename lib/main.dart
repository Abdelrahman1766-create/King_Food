import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'ui/user_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use surface-based platform view rendering for newer Android devices to avoid indefinite map spinner.
  // This is more reliable on modern Samsung/Android versions.
  AndroidYandexMap.useAndroidViewSurface = true;

  try {
    // Initialize Firebase with default configuration from google-services.json
    await Firebase.initializeApp();

    // Initialize Firebase Cloud Messaging
    await FirebaseMessaging.instance.requestPermission();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: ${e.toString()}');
    // For main app, continue without Firebase for basic functionality
  }

  runApp(const ProviderScope(child: UserApp()));
}
