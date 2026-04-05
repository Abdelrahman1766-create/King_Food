import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_utils.dart';
import '../../domain/entities/order.dart';
import '../viewmodels/orders_viewmodel.dart';
import '../../../utils/i18n.dart';

/// صفحة عرض تفاصيل طلب محدد.
class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ordersViewModelProvider.notifier).loadOrderDetails(widget.orderId);
    });
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
    final order = ordersState.selectedOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Order Details', 'Детали заказа')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ordersState.isLoadingActive
            ? const Center(child: CircularProgressIndicator())
            : order == null
                ? Center(
                    child: Text(
                      t(
                        context,
                        'Order data not found.',
                        'Данные заказа не найдены.',
                      ),
                    ),
                  )
                : _OrderDetailsContent(order: order),
      ),
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Card(
          elevation: 2,
          child: ListTile(
            title: Text(
              '${t(context, 'Order #', 'Заказ №')}: ${order.orderNumber}',
            ),
            subtitle: Text(
              '${t(context, 'Current status', 'Текущий статус')}: ${statusLabel(context, order.status)}',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'Customer Info', 'Информация о клиенте'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${t(context, 'Name', 'Имя')}: ${order.customerName}'),
                Text('${t(context, 'Phone', 'Телефон')}: ${order.customerPhone}'),
                Text('${t(context, 'Address', 'Адрес')}: ${order.customerAddress}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'Order Items', 'Состав заказа'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Text(item.quantity.toString()),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${t(context, 'Price', 'Цена')}: ${item.price.toStringAsFixed(2)} RUB - ${t(context, 'Total', 'Итого')}: ${item.total.toStringAsFixed(2)} RUB',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${t(context, 'Grand Total', 'Итоговая сумма')}: ${order.totalPrice.toStringAsFixed(2)} RUB',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t(context, 'Additional Info', 'Дополнительная информация'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${t(context, 'Payment method', 'Способ оплаты')}: ${AdminUtils.toTitleCase(order.paymentMethod)}',
                ),
                Text('${t(context, 'Created at', 'Создан')}: ${order.createdAt}'),
                if (order.deliveredAt != null)
                  Text(
                    '${t(context, 'Delivered at', 'Доставлен')}: ${order.deliveredAt}',
                  ),
                if (order.notes != null && order.notes!.isNotEmpty)
                  Text('${t(context, 'Notes', 'Примечания')}: ${order.notes}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
