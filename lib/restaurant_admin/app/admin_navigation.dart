import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/user_app.dart';
import 'admin_providers.dart';

Future<void> switchToUserMode(BuildContext context, WidgetRef ref) async {
  await ref.read(adminModeProvider.notifier).setAdminMode(false);
  if (!context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);

  if (navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const UserApp()),
    (route) => false,
  );
}
