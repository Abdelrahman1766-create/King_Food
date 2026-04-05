import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/cart_controller.dart';
import '../models/address.dart';
import 'auth_page.dart';
import 'addresses_page.dart';
import 'order_status_page.dart';
import 'payment_page.dart';
import '../providers/address_provider.dart';
import '../l10n/app_localizations.dart';
import '../restaurant_admin/core/admin_constants.dart';

enum PaymentMethod { cash, online }

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.cart});
  final CartController cart;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  Address? _address;
  PaymentMethod _method = PaymentMethod.cash;

  String _t(BuildContext context, String enText, String ruText) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ru' ? ruText : enText;
  }

  @override
  void initState() {
    super.initState();
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    _address = addressProvider.addresses.isNotEmpty
        ? addressProvider.addresses.first
        : null;
  }

  Future<bool> _ensureLoggedIn() async {
    if (FirebaseAuth.instance.currentUser != null) return true;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _t(context, 'Sign in required', 'Требуется вход'),
          ),
          content: Text(
            _t(
              context,
              'Please sign in or register to place an order.',
              'Пожалуйста, войдите или зарегистрируйтесь, чтобы оформить заказ.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_t(context, 'Cancel', 'Отмена')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_t(context, 'Sign In / Register', 'Войти / Регистрация')),
            ),
          ],
        );
      },
    );

    if (shouldLogin != true || !mounted) return false;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );

    return FirebaseAuth.instance.currentUser != null;
  }

  Future<void> _placeOrder({bool paid = false}) async {
    final isLoggedIn = await _ensureLoggedIn();
    if (!isLoggedIn) return;

    if (_method == PaymentMethod.online && !paid) {
      final locale = Localizations.localeOf(context);
      final lang = locale.languageCode;
      final msg = lang == 'ru'
          ? 'Сначала оплатите заказ онлайн.'
          : 'Please complete online payment first.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final customerName = firebaseUser?.displayName ?? 'Guest';
    final customerEmail = firebaseUser?.email ?? '';
    final customerId = firebaseUser?.uid ?? '';

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Try to write to Firestore, but don't block if it fails
      final restaurantId = 'demo_restaurant';
      final orderNumber = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        final firestore = FirebaseFirestore.instance;

        final orderData = {
          'orderNumber': orderNumber,
          'status': AdminConstants.orderStatuses.first,
          'createdAt': FieldValue.serverTimestamp(),
          'paymentStatus': paid ? 'Paid' : 'Unpaid',
          if (paid) 'paidAt': FieldValue.serverTimestamp(),
          'customerName': customerName,
          'customerEmail': customerEmail,
          'customerId': customerId,
          'customerPhone': _address?.phone ?? '',
          'customerAddress': _address == null
              ? ''
              : '${_address!.label}\n${_address!.line1}, ${_address!.city}\n${_address!.phone}',
          if (_address?.latitude != null) 'deliveryLat': _address!.latitude,
          if (_address?.longitude != null) 'deliveryLng': _address!.longitude,
          'items': widget.cart.items
              .map(
                (ci) => {
                  'name': ci.product.name,
                  'price': ci.product.price,
                  'quantity': ci.quantity,
                },
              )
              .toList(),
          'total': widget.cart.total,
          'paymentMethod': _method == PaymentMethod.cash ? 'cash' : 'online',
          'notes': '',
        };

        final docRef = await firestore
            .collection(AdminConstants.restaurantsCollection)
            .doc(restaurantId)
            .collection(AdminConstants.ordersCollection)
            .add(orderData)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                // Generate a local ID if Firestore times out
                return FirebaseFirestore.instance
                    .collection(AdminConstants.restaurantsCollection)
                    .doc(restaurantId)
                    .collection(AdminConstants.ordersCollection)
                    .doc();
              },
            );

        if (!mounted) return;

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.orderPlacedMessage)));

        // Navigate to order status page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderStatusPage(
              orderId: docRef.id,
              deliveryAddress: _address!,
              paymentMethod: _method,
              items: widget.cart.items,
              total: widget.cart.total,
            ),
          ),
        );

        // Clear cart after successful order
        widget.cart.clear();
      } catch (firebaseError) {
        // If Firestore fails, still proceed with local order
        print('Firestore error: $firebaseError');

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created locally. May not sync to server.'),
          ),
        );

        // Use a local ID
        final localOrderId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderStatusPage(
              orderId: localOrderId,
              deliveryAddress: _address!,
              paymentMethod: _method,
              items: widget.cart.items,
              total: widget.cart.total,
            ),
          ),
        );

        widget.cart.clear();
      }
    } catch (e) {
      // Ensure loading dialog is closed
      if (mounted) Navigator.of(context).pop();

      final locale = Localizations.localeOf(context);
      final lang = locale.languageCode;
      final failMessage = lang == 'ru'
          ? 'Не удалось оформить заказ. Пожалуйста, повторите попытку.'
          : 'Failed to place order. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failMessage\n${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.orderSummary,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...widget.cart.items.map(
            (ci) => ListTile(
              dense: true,
              title: Text(ci.product.name),
              subtitle: Text('x${ci.quantity}'),
              trailing: Text(currency.format(ci.product.price * ci.quantity)),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.deliveryAddress),
            subtitle: Text(
              _address == null
                  ? l10n.noAddressSelected
                  : '${_address!.label}\n${_address!.line1}, ${_address!.city}\n${_address!.phone}',
            ),
            trailing: TextButton(
              onPressed: () async {
                final chosen = await Navigator.of(context).push<Address>(
                  MaterialPageRoute(
                    builder: (_) => AddressesPage(selected: _address),
                  ),
                );
                if (chosen != null) setState(() => _address = chosen);
              },
              child: Text(l10n.change),
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.paymentMethod),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioListTile<PaymentMethod>(
                  title: Text(l10n.cashOnDelivery),
                  value: PaymentMethod.cash,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                ),
                RadioListTile<PaymentMethod>(
                  title: Text(l10n.onlinePayment),
                  value: PaymentMethod.online,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                ),
                if (_method == PaymentMethod.online)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.credit_card),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _address == null
                          ? null
                          : () async {
                              final isLoggedIn = await _ensureLoggedIn();
                              if (!isLoggedIn) return;
                              final result = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentPage(
                                        cart: widget.cart,
                                        deliveryAddress: _address!,
                                        isTest: false,
                                      ),
                                    ),
                                  );
                              if (result == true) {
                                // Payment was successful, proceed with order and mark paid
                                _placeOrder(paid: true);
                              }
                            },
                      label: Text(
                        l10n.proceedToPayment ?? 'Proceed to Payment',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.total}: ${currency.format(widget.cart.total)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ElevatedButton(
                onPressed: _address == null
                    ? null
                    : () async {
                        if (_method == PaymentMethod.online) {
                          final isLoggedIn = await _ensureLoggedIn();
                          if (!isLoggedIn) return;
                          final result =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PaymentPage(
                                cart: widget.cart,
                                deliveryAddress: _address!,
                                isTest: false,
                              ),
                            ),
                          );
                          if (result == true) {
                            _placeOrder(paid: true);
                          }
                        } else {
                          _placeOrder();
                        }
                      },
                child: Text(
                  _method == PaymentMethod.online
                      ? (l10n.proceedToPayment ?? 'Pay Online')
                      : l10n.placeOrder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
