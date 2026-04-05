import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/admin_router.dart';
import '../../app/admin_navigation.dart';
import '../viewmodels/menu_viewmodel.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/menu_item_card.dart';
import '../../../utils/i18n.dart';

/// شاشة إدارة أصناف المطعم.
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  Future<void> _createItem(BuildContext context) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    if (mounted) {
      context.push(AdminRoutes.menuItemEdit, extra: newId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MenuState>(menuViewModelProvider, (_, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    });

    final menuState = ref.watch(menuViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Manage Menu', 'Управление меню')),
        actions: [
          IconButton(
            tooltip: t(context, 'Back to User Mode', 'Вернуться в режим пользователя'),
            onPressed: () => switchToUserMode(context, ref),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: t(context, 'Add Item', 'Добавить товар'),
            onPressed: () => _createItem(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: menuState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : menuState.items.isEmpty
          ? Center(
              child: Text(
                t(context, 'No items available.', 'Нет доступных товаров.'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: menuState.items.length,
              itemBuilder: (context, index) {
                final item = menuState.items[index];
                return MenuItemCard(item: item);
              },
            ),
    );
  }
}
