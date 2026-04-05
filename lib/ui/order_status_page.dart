import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/cart_controller.dart';
import '../models/address.dart';
import 'checkout_page.dart';
import '../l10n/app_localizations.dart';

class OrderStatusPage extends StatefulWidget {
  final String orderId;
  final Address deliveryAddress;
  final PaymentMethod paymentMethod;
  final List<CartItem> items;
  final double total;

  const OrderStatusPage({
    super.key,
    required this.orderId,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.items,
    required this.total,
  });

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  OrderStatus _status = OrderStatus.preparing;
  bool _isDelivered = false;

  @override
  void initState() {
    super.initState();
    // Listen to real-time updates from Firestore
    _listenToOrderUpdates();
  }

  void _listenToOrderUpdates() {
    try {
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc('demo_restaurant')
          .collection('orders')
          .doc(widget.orderId)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

            if (snapshot.exists) {
              final data = snapshot.data();
              final statusString = data?['status'] as String? ?? 'قيد المراجعة';
              final normalized = _normalizeStatus(statusString);

              // Map status string to OrderStatus enum
              OrderStatus newStatus = OrderStatus.preparing;
              if (normalized == 'تم القبول') {
                newStatus = OrderStatus.preparing;
              } else if (normalized == 'جاري التجهيز') {
                newStatus = OrderStatus.preparing;
              } else if (normalized == 'في الطريق') {
                newStatus = OrderStatus.onTheWay;
              } else if (normalized == 'تم التوصيل') {
                newStatus = OrderStatus.delivered;
                setState(() => _isDelivered = true);
              }

              setState(() => _status = newStatus);
            }
          });
    } catch (e) {
      print('Error listening to order updates: $e');
      // Fall back to simulation if Firestore fails
      _simulateOrderProgress();
    }
  }

  Future<void> _simulateOrderProgress() async {
    // Simulate order preparation
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() => _status = OrderStatus.onTheWay);

    // Simulate delivery
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted) return;
    setState(() {
      _status = OrderStatus.delivered;
      _isDelivered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );

    return WillPopScope(
      onWillPop: () async {
        if (_isDelivered) {
          // Go back to the first route (home)
          Navigator.of(context).popUntil((route) => route.isFirst);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.orderStatus),
          automaticallyImplyLeading: !_isDelivered,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context, l10n),
              const SizedBox(height: 24),
              _buildOrderSummary(currency, l10n),
              const SizedBox(height: 24),
              _buildDeliveryInfo(l10n),
              const SizedBox(height: 24),
              if (_isDelivered)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(l10n.backToHome),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isDelivered ? l10n.orderDelivered : l10n.orderPlaced,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Order #${widget.orderId}\n${_getStatusMessage(l10n)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _status.progressValue,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusStep(
                  l10n.preparing,
                  _status.stepIndex <= OrderStatus.preparing.index,
                ),
                _buildStatusStep(
                  l10n.onTheWay,
                  _status.stepIndex <= OrderStatus.onTheWay.index,
                ),
                _buildStatusStep(
                  l10n.delivered,
                  _status.stepIndex <= OrderStatus.delivered.index,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isActive) {
    return Column(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(NumberFormat currency, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orderSummary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.quantity}x ${item.product.name}'),
                    Text(currency.format(item.product.price * item.quantity)),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.total,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currency.format(widget.total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deliveryInformation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(l10n.paymentMethod, _getPaymentMethodText(l10n)),
            const SizedBox(height: 8),
            _buildInfoRow(
              l10n.deliveryAddress,
              '${widget.deliveryAddress.label}\n'
              '${widget.deliveryAddress.line1}\n'
              '${widget.deliveryAddress.city}\n'
              'Phone: ${widget.deliveryAddress.phone}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusMessage(AppLocalizations l10n) {
    switch (_status) {
      case OrderStatus.preparing:
        return l10n.orderPlacedMessage;
      case OrderStatus.onTheWay:
        return l10n.orderOnWayMessage;
      case OrderStatus.delivered:
        return l10n.orderDeliveredMessage;
    }
  }

  String _getPaymentMethodText(AppLocalizations l10n) {
    return widget.paymentMethod == PaymentMethod.cash
        ? l10n.cashOnDelivery
        : l10n.onlinePayment;
  }

  String _normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'delivered' || value == 'تم التوصيل' || value == 'доставлено' || value == 'доставлен') {
      return 'تم التوصيل';
    }
    if (value == 'on the way' || value == 'في الطريق' || value == 'в пути') {
      return 'في الطريق';
    }
    if (value == 'accepted' || value == 'تم القبول' || value == 'принят') {
      return 'تم القبول';
    }
    if (value == 'preparing' || value == 'جاري التجهيز' || value == 'готовится') {
      return 'جاري التجهيز';
    }
    return raw;
  }
}

enum OrderStatus {
  preparing,
  onTheWay,
  delivered;

  double get progressValue {
    switch (this) {
      case OrderStatus.preparing:
        return 0.3;
      case OrderStatus.onTheWay:
        return 0.7;
      case OrderStatus.delivered:
        return 1.0;
    }
  }

  int get stepIndex => index;
}
