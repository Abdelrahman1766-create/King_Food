import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/driver_app.dart';

/// نقطة الدخول الرئيسية لتطبيق السائق.
/// يتم تهيئة Firebase ثم تشغيل التطبيق داخل ProviderScope من Riverpod.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: DriverApp()));
}
