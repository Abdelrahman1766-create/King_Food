import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/admin_router.dart';
import '../../app/admin_navigation.dart';
import '../../core/admin_constants.dart';
import '../../core/admin_utils.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/driver.dart';
import '../viewmodels/orders_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/admin_drawer.dart';
import '../../../utils/i18n.dart';
import '../../app/admin_providers.dart';

/// شاشة الطلبات الجديدة (النشطة) لمسؤول المطعم.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ordersViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isAdminMode = ref.watch(adminModeProvider);
    final restaurantIdForRead = authState.restaurantId ?? 'demo_restaurant';

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Current Orders', 'Текущие заказы')),
        actions: [
          IconButton(
            tooltip: t(context, 'Back to User Mode', 'Вернуться в режим пользователя'),
            onPressed: () => switchToUserMode(context, ref),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: t(context, 'Sign out', 'Выйти'),
            onPressed: () => ref.read(authViewModelProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (authState.restaurantId == null && !isAdminMode)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ordersState.errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '${t(context, 'Error', 'Ошибка')}: ${ordersState.errorMessage}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(ordersViewModelProvider.notifier)
                              .initialize(restaurantIdForRead);
                        },
                        child: Text(t(context, 'Retry', 'Повторить')),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (ordersState.isLoadingActive)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ordersState.activeOrders.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t(
                    context,
                    'No new orders at the moment.',
                    'Новых заказов сейчас нет.',
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(ordersViewModelProvider.notifier)
                      .initialize(restaurantIdForRead);
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

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(ordersViewModelProvider).isLoadingActive;
    final colorScheme = Theme.of(context).colorScheme;

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
                  child: Text(order.orderNumber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${t(context, 'Phone', 'Телефон')}: ${order.customerPhone}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  AdminUtils.toTitleCase(order.paymentMethod),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${t(context, 'Address', 'Адрес')}: ${order.customerAddress}',
            ),
            const SizedBox(height: 8),
            if (order.driverName != null) ...[
              Text(
                '${t(context, 'Driver', 'Курьер')}: ${order.driverName}',
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '${t(context, 'Total', 'Итого')}: ${order.totalPrice.toStringAsFixed(2)} RUB',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: order.items
                  .map(
                    (item) =>
                        Chip(label: Text('${item.name} × ${item.quantity}')),
                  )
                  .toList(),
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${t(context, 'Notes', 'Примечания')}: ${order.notes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;

                final statusField = DropdownButtonFormField<String>(
                  initialValue: order.status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t(context, 'Order Status', 'Статус заказа'),
                    border: const OutlineInputBorder(),
                  ),
                  items: AdminConstants.orderStatuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(statusLabel(context, status)),
                        ),
                      )
                      .toList(),
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          if (value == null || value == order.status) return;
                          ref
                              .read(ordersViewModelProvider.notifier)
                              .updateOrderStatus(
                                orderId: order.id,
                                status: value,
                              );
                        },
                );

                final driverField = DropdownButtonFormField<String>(
                  initialValue: order.driverId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t(context, 'Delivery Driver', 'Курьер'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        t(context, 'Not assigned', 'Не назначен'),
                      ),
                    ),
                    ...demoDrivers
                        .where((driver) => driver.isAvailable)
                        .map(
                          (driver) => DropdownMenuItem<String>(
                            value: driver.id,
                            child: Text('${driver.name} (${driver.phone})'),
                          ),
                        ),
                  ],
                  onChanged: isUpdating
                      ? null
                      : (value) {
                          if (value == order.driverId) return;
                          final selectedDriver = demoDrivers.firstWhere(
                            (d) => d.id == value,
                            orElse: () => Driver(id: '', name: '', phone: ''),
                          );
                          ref
                              .read(ordersViewModelProvider.notifier)
                              .updateOrderDriver(
                                orderId: order.id,
                                driverId: value,
                                driverName: selectedDriver.name,
                              );
                        },
                );

                final detailsButton = OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AdminRoutes.orderDetails, extra: order.id),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(t(context, 'View Details', 'Подробнее')),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      statusField,
                      const SizedBox(height: 12),
                      driverField,
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: detailsButton,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 2, child: statusField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: driverField),
                    const SizedBox(width: 12),
                    detailsButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
