import 'package:flutter/material.dart';

/// أدوات مساعدة عامة.
class AdminUtils {
  /// عرض SnackBar موحد للرسائل السريعة.
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  /// تحويل النص إلى حالة Title Case لاستخدامها في الواجهات.
  static String toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
