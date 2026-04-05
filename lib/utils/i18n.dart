import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

String t(BuildContext context, String enText, String ruText) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ru' ? ruText : enText;
}

String tNoContext(String enText, String ruText) {
  final locale = ui.PlatformDispatcher.instance.locale;
  return locale.languageCode == 'ru' ? ruText : enText;
}

String statusLabel(BuildContext context, String status) {
  const en = {
    'pending': 'Pending',
    'accepted': 'Accepted',
    'preparing': 'Preparing',
    'on_the_way': 'On the way',
    'delivered': 'Delivered',
    // Legacy Arabic values (support for existing data)
    'قيد المراجعة': 'Under Review',
    'تم القبول': 'Accepted',
    'جاري التجهيز': 'Preparing',
    'في الطريق': 'On the way',
    'تم التوصيل': 'Delivered',
    // Legacy Russian values
    'на проверке': 'Under Review',
    'принят': 'Accepted',
    'готовится': 'Preparing',
    'в пути': 'On the way',
    'доставлено': 'Delivered',
  };
  const ru = {
    'pending': 'В ожидании',
    'accepted': 'Принят',
    'preparing': 'Готовится',
    'on_the_way': 'В пути',
    'delivered': 'Доставлено',
    // Legacy Arabic values
    'قيد المراجعة': 'На проверке',
    'تم القبول': 'Принят',
    'جاري التجهيز': 'Готовится',
    'في الطريق': 'В пути',
    'تم التوصيل': 'Доставлено',
    // Legacy Russian values
    'на проверке': 'На проверке',
    'принят': 'Принят',
    'готовится': 'Готовится',
    'в пути': 'В пути',
    'доставлено': 'Доставлено',
  };

  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'ru') {
    return ru[status.toLowerCase()] ?? en[status.toLowerCase()] ?? status;
  }
  return en[status.toLowerCase()] ?? status;
}
