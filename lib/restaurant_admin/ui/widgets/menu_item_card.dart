import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/menu_item.dart';
import '../viewmodels/menu_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../app/admin_router.dart';
import 'price_log_dialog.dart';
import '../../../utils/i18n.dart';

/// بطاقة لعرض بيانات صنف مع أدوات إدارة سريعة.
class MenuItemCard extends ConsumerWidget {
  const MenuItemCard({super.key, required this.item});

  final MenuItemEntity item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final menuNotifier = ref.read(menuViewModelProvider.notifier);

    void toggleAvailability(bool value) {
      final updatedItem = item.copyWith(
        isAvailable: value,
        updatedAt: DateTime.now(),
      );
      menuNotifier.updateMenuItem(updatedItem, oldPrice: item.price);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              color: colorScheme.errorContainer,
                              child: Icon(
                                Icons.broken_image,
                                color: colorScheme.error,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 72,
                              height: 72,
                              alignment: Alignment.center,
                              color: colorScheme.surfaceContainerHighest,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          color: colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(item.description),
                      const SizedBox(height: 4),
                      Text(
                        '${t(context, 'Price', 'Цена')}: ${item.price.toStringAsFixed(2)} RUB',
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: item.isAvailable,
                  onChanged: toggleAvailability,
                  activeThumbColor: colorScheme.primary,
                  inactiveThumbColor: colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AdminRoutes.menuItemEdit, extra: item.id),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(t(context, 'Edit', 'Редактировать')),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(t(context, 'Delete item', 'Удалить товар')),
                        content: Text(
                          t(
                            context,
                            'Are you sure you want to delete "${item.name}"?',
                            'Вы уверены, что хотите удалить "${item.name}"?',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(t(context, 'Cancel', 'Отмена')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(t(context, 'Delete', 'Удалить')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await menuNotifier.deleteMenuItem(item.id);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t(context, 'Delete', 'Удалить')),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final authState = ref.read(authViewModelProvider);
                    final restaurantId = authState.restaurantId;
                    if (restaurantId == null) return;

                    await menuNotifier.loadPriceLogs(item.id);
                    final state = ref.read(menuViewModelProvider);
                    if (context.mounted) {
                      await showDialog<void>(
                        context: context,
                        builder: (context) => PriceLogDialog(
                          logs: state.priceLogs,
                          itemName: item.name,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.price_change_outlined),
                  label: Text(t(context, 'Price Log', 'История цен')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
