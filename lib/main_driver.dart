import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'driver_app/app/driver_app.dart';

/// نقطة دخول تطبيق السائق.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AndroidYandexMap.useAndroidViewSurface = true;

  // تهيئة Firebase
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: DriverApp()));
}
