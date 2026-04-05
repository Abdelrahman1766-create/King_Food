import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/driver_router.dart';
import '../../app/driver_app.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../utils/i18n.dart';
import '../../../restaurant_admin/core/admin_constants.dart';

/// شاشة الطلبات للسائق.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _didInit = false;

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    // تهيئة OrdersViewModel عند تغير السائق
    ref.listen<AuthState>(authViewModelProvider, (
      AuthState? previous,
      AuthState next,
    ) {
      if (next.restaurantId != null &&
          (previous?.restaurantId != next.restaurantId ||
              previous?.driverId != next.driverId)) {
        _didInit = true;
        ref
            .read(ordersViewModelProvider.notifier)
            .initialize(next.restaurantId!);
      }
      if (next.restaurantId == null || next.driverId == null) {
        _didInit = false;
        ref.read(ordersViewModelProvider.notifier).reset();
      }
    });

    if (!_didInit &&
        authState.restaurantId != null &&
        authState.driverId != null) {
      _didInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(ordersViewModelProvider.notifier)
            .initialize(authState.restaurantId!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'My Orders', 'Мои заказы')),
        actions: [
          IconButton(
            tooltip: t(context, 'Sign out', 'Выйти'),
            onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.restaurantId == null || authState.driverId == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ordersState.isLoadingActive)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ordersState.error != null)
            Expanded(
              child: Center(
                child: Text(ordersState.error!, textAlign: TextAlign.center),
              ),
            )
          else if (ordersState.activeOrders.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t(
                    context,
                    'No assigned orders yet.',
                    'Назначенных заказов пока нет.',
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final restaurantId = authState.restaurantId;
                  if (restaurantId != null) {
                    ref
                        .read(ordersViewModelProvider.notifier)
                        .initialize(restaurantId);
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordersState.activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = ordersState.activeOrders[index];
                    return _OrderCard(order: order);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final dynamic order; // استخدام نفس Order من restaurant_admin

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(ordersViewModelProvider).isLoadingActive;
    final colorScheme = Theme.of(context).colorScheme;
    final statusText = statusLabel(context, order.status ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Text(order.orderNumber ?? '#'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName ?? t(context, 'Customer', 'Клиент'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${t(context, 'Phone', 'Телефон')}: ${order.customerPhone ?? ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  statusText.isNotEmpty
                      ? statusText
                      : t(context, 'Unknown', 'Неизвестно'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${t(context, 'Address', 'Адрес')}: ${order.customerAddress ?? ''}',
            ),
            const SizedBox(height: 6),
            Text(
              '${t(context, 'Pickup', 'Точка выдачи')}: ${AdminConstants.restaurantAddress}',
            ),
            const SizedBox(height: 8),
            Text(
              '${t(context, 'Total', 'Итого')}: ${order.totalPrice?.toStringAsFixed(2) ?? '0.00'} RUB',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (order.items ?? [])
                  .map<Widget>(
                    (item) => Chip(
                      label: Text('${item.name ?? ''} × ${item.quantity ?? 0}'),
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: (() {
                      final currentStatus = order.status as String?;
                      const driverStatuses = ['في الطريق', 'تم التوصيل'];
                      final values = <String>[...driverStatuses];
                      if (currentStatus != null &&
                          !values.contains(currentStatus)) {
                        values.insert(0, currentStatus);
                      }
                      final uniqueValues = values.toSet().toList();
                      return uniqueValues.contains(currentStatus)
                          ? currentStatus
                          : null;
                    })(),
                    decoration: InputDecoration(
                      labelText: t(context, 'Update status', 'Обновить статус'),
                      border: const OutlineInputBorder(),
                    ),
                    items: () {
                      final currentStatus = order.status as String?;
                      const driverStatuses = ['في الطريق', 'تم التوصيل'];
                      final values = <String>[...driverStatuses];
                      if (currentStatus != null &&
                          !values.contains(currentStatus)) {
                        values.insert(0, currentStatus);
                      }
                      final uniqueValues = values.toSet().toList();
                      return uniqueValues
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(statusLabel(context, value)),
                            ),
                          )
                          .toList();
                    }(),
                    onChanged: isUpdating
                        ? null
                        : (value) {
                            if (value == null || value == order.status) return;
                            const driverStatuses = ['في الطريق', 'تم التوصيل'];
                            if (!driverStatuses.contains(value)) return;
                            ref
                                .read(ordersViewModelProvider.notifier)
                                .updateOrderStatus(
                                  orderId: order.id,
                                  status: value,
                                );
                          },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(DriverRoutes.orderDetails, extra: order.id),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(t(context, 'View details', 'Подробнее')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
