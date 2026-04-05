import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/admin_navigation.dart';
import '../../domain/entities/order.dart';
import '../viewmodels/orders_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/admin_drawer.dart';
import '../../../utils/i18n.dart';

/// شاشة عرض الطلبات السابقة مع البحث والفلترة.
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _orderNumberController = TextEditingController();
  final _customerNameController = TextEditingController();

  @override
  void dispose() {
    _orderNumberController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final initialRange = ref.read(ordersViewModelProvider).dateFilter;
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      ref.read(ordersViewModelProvider.notifier).applyDateFilter(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrdersState>(ordersViewModelProvider, (_, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
      }
    });

    final ordersState = ref.watch(ordersViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Order History', 'История заказов')),
        actions: [
          IconButton(
            tooltip: t(context, 'Back to User Mode', 'Вернуться в режим пользователя'),
            onPressed: () => switchToUserMode(context, ref),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: t(context, 'Filter by date', 'Фильтр по дате'),
            onPressed: _selectDateRange,
            icon: const Icon(Icons.date_range_outlined),
          ),
          IconButton(
            tooltip: t(context, 'Reset', 'Сброс'),
            onPressed: () {
              _orderNumberController.clear();
              _customerNameController.clear();
              ref.read(ordersViewModelProvider.notifier).applyDateFilter(null);
              ref
                  .read(ordersViewModelProvider.notifier)
                  .initialize(ref.read(authViewModelProvider).restaurantId ?? '');
            },
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _orderNumberController,
                    decoration: InputDecoration(
                      labelText: t(context, 'Order #', 'Заказ №'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _customerNameController,
                    decoration: InputDecoration(
                      labelText: t(context, 'Customer name', 'Имя клиента'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(ordersViewModelProvider.notifier).searchOrders(
                          orderNumber: _orderNumberController.text.isEmpty
                              ? null
                              : _orderNumberController.text.trim(),
                          customerName: _customerNameController.text.isEmpty
                              ? null
                              : _customerNameController.text.trim(),
                        );
                  },
                  icon: const Icon(Icons.search),
                  label: Text(t(context, 'Search', 'Поиск')),
                ),
              ],
            ),
          ),
          if (ordersState.isLoadingCompleted)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ordersState.completedOrders.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  t(
                    context,
                    'No orders in history.',
                    'Нет заказов в истории.',
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ordersState.completedOrders.length,
                itemBuilder: (context, index) {
                  final order = ordersState.completedOrders[index];
                  return _OrderHistoryTile(order: order);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  const _OrderHistoryTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Text(order.orderNumber),
        ),
        title: Text(order.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t(context, 'Phone', 'Телефон')}: ${order.customerPhone}'),
            Text(
              '${t(context, 'Total', 'Итого')}: ${order.totalPrice.toStringAsFixed(2)} RUB',
            ),
            if (order.deliveredAt != null)
              Text(
                '${t(context, 'Delivered at', 'Доставлен')}: ${order.deliveredAt}',
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(context, 'Order Details', 'Детали заказа'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${t(context, 'Payment method', 'Способ оплаты')}: ${order.paymentMethod}',
                  ),
                  Text(
                    '${t(context, 'Address', 'Адрес')}: ${order.customerAddress}',
                  ),
                  const SizedBox(height: 8),
                  Text(t(context, 'Items', 'Товары') + ':'),
                  const SizedBox(height: 4),
                  ...order.items.map(
                    (item) => Text('- ${item.name} × ${item.quantity}'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
