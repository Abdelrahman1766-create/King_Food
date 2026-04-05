import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/admin_router.dart';
import '../../app/admin_navigation.dart';
import '../../../utils/i18n.dart';

/// قائمة تنقل جانبية موحدة لشاشات لوحة المسؤول.
class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.restaurant,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'King Food Admin',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _DrawerTile(
            title: t(context, 'New Orders', 'Новые заказы'),
            icon: Icons.receipt_long_outlined,
            selected: currentRoute.startsWith(AdminRoutes.orders),
            onTap: () => context.go(AdminRoutes.orders),
          ),
          _DrawerTile(
            title: t(context, 'Order History', 'История заказов'),
            icon: Icons.history,
            selected: currentRoute.startsWith(AdminRoutes.orderHistory),
            onTap: () => context.go(AdminRoutes.orderHistory),
          ),
          _DrawerTile(
            title: t(context, 'Manage Menu', 'Управление меню'),
            icon: Icons.restaurant_menu,
            selected: currentRoute.startsWith(AdminRoutes.menu),
            onTap: () => context.go(AdminRoutes.menu),
          ),
          const Divider(),
          _DrawerTile(
            title: t(context, 'Back to User Mode', 'Вернуться в режим пользователя'),
            icon: Icons.person,
            onTap: () async {
              await switchToUserMode(context, ref);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© ${DateTime.now().year} King Food',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
