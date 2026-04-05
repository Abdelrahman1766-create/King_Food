import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;
import 'dart:async' show TimeoutException;

import 'app/admin_app.dart';
import '../utils/i18n.dart';

/// نقطة الدخول الرئيسية للوحة مسؤول المطعم.
/// يتم تهيئة Firebase ثم تشغيل التطبيق داخل ProviderScope من Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تفعيل وضع عدم الاتصال للاختبار في روسيا
  const bool offlineMode = false; // غير هذا إلى false لاستخدام Firebase

  if (offlineMode) {
    print('🔄 تشغيل التطبيق في وضع عدم الاتصال (للاختبار في روسيا)');
    final offlineTitle = tNoContext('Offline mode', 'Офлайн режим');
    final offlineBody = tNoContext(
      'The app is running without Firebase for testing.\n\nFor full functionality:\n1. Use VPN\n2. Or set offlineMode = false in main_admin.dart',
      'Приложение запущено без Firebase для тестирования.\n\nДля полного режима:\n1. Используйте VPN\n2. Или установите offlineMode = false в main_admin.dart',
    );
    runApp(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      offlineTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      offlineBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  try {
    print('🔄 Initializing Firebase...');

    // Initialize Firebase with platform-specific configuration
    if (Platform.isAndroid) {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Firebase initialization timeout',
          const Duration(seconds: 30),
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBDhw-vlzGaPNxKQaKGh0z-M-qDTYfppL4',
          appId: '1:671616230836:android:25eb62bfc416dc8fbc7ee1',
          messagingSenderId: '671616230836',
          projectId: 'king-food-f579c',
          storageBucket: 'king-food-f579c.firebasestorage.app',
          authDomain: 'king-food-f579c.firebaseapp.com',
          databaseURL: 'https://king-food-f579c-default-rtdb.firebaseio.com',
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException(
          'Firebase initialization timeout',
          const Duration(seconds: 30),
        ),
      );
    }

    // Initialize Firebase Cloud Messaging for admin
    try {
      await FirebaseMessaging.instance.requestPermission();
      // ignore: avoid_print
      print('✅ Admin FCM initialized successfully');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Admin FCM initialization failed: ${e.toString()}');
    }

    // ignore: avoid_print
    print('✅ Admin Firebase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Admin Firebase initialization failed: ${e.toString()}');
    // For admin app, Firebase is critical - show error and exit
    runApp(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tNoContext(
                        'Firebase Initialization Error',
                        'Ошибка инициализации Firebase',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tNoContext(
                        'Admin app cannot work without Firebase\n\nError Details:\n${e.toString()}',
                        'Приложение администратора не может работать без Firebase\n\nДетали ошибки:\n${e.toString()}',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tNoContext(
                        'Please verify:\n• Internet connection\n• Firebase configuration\n• google-services.json file\n• Network/VPN settings if in restricted region',
                        'Проверьте:\n• Интернет соединение\n• Конфигурацию Firebase\n• Файл google-services.json\n• Настройки сети/VPN в ограниченном регионе',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: AdminApp()));
}
