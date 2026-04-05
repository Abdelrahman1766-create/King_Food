import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../restaurant_admin/core/admin_constants.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key, this.welcomeName});

  final String? welcomeName;

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  String _t(BuildContext context, String enText, String ruText) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ru' ? ruText : enText;
  }

  @override
  void initState() {
    super.initState();
    if (widget.welcomeName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final name = widget.welcomeName!;
        final message = _t(
          context,
          'Welcome, $name!',
          'Добро пожаловать, $name!',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream(User user) {
    const restaurantId = 'demo_restaurant';
    return FirebaseFirestore.instance
        .collection(AdminConstants.restaurantsCollection)
        .doc(restaurantId)
        .collection(AdminConstants.ordersCollection)
        .where('customerId', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final title = _t(context, 'My Orders', 'Мои заказы');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authSnapshot.data;
          if (user == null) {
            return _buildSignInPrompt(context);
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ordersStream(user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    _t(
                      context,
                      'Failed to load orders.',
                      'Не удалось загрузить заказы.',
                    ),
                  ),
                );
              }

              final items = snapshot.data?.docs.map(_mapDocToItem).toList() ??
                  <_OrderListItem>[];
              items.sort(
                (a, b) => b.createdAtMillis.compareTo(a.createdAtMillis),
              );

              return _buildOrdersList(context, items);
            },
          );
        },
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _t(
            context,
            'Please sign in or register to view your orders.',
            'Пожалуйста, войдите или зарегистрируйтесь, чтобы увидеть заказы.',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<_OrderListItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          _t(
            context,
            'No orders yet.',
            'Пока нет заказов.',
          ),
        ),
      );
    }

    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final dateText = item.createdAtMillis == 0
            ? ''
            : dateFormat.format(
                DateTime.fromMillisecondsSinceEpoch(item.createdAtMillis),
              );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              _t(
                context,
                'Order #${item.orderNumber}',
                'Заказ №${item.orderNumber}',
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateText.isNotEmpty) Text(dateText),
                Text(
                  _t(
                    context,
                    'Items: ${item.itemsCount}',
                    'Товары: ${item.itemsCount}',
                  ),
                ),
                Text(
                  _t(
                    context,
                    'Status: ${item.status}',
                    'Статус: ${item.status}',
                  ),
                ),
                Text(
                  _t(
                    context,
                    'Payment: ${item.paymentMethod}',
                    'Оплата: ${item.paymentMethod}',
                  ),
                ),
              ],
            ),
            trailing: Text(item.total.toStringAsFixed(2)),
          ),
        );
      },
    );
  }

  _OrderListItem _mapDocToItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final items = (data['items'] as List?) ?? const [];
    final itemsCount = items.fold<int>(0, (sum, item) {
      final quantity = (item as Map?)?['quantity'];
      return sum + (quantity is num ? quantity.toInt() : 0);
    });
    final createdAt = data['createdAt'] as Timestamp?;

    return _OrderListItem(
      id: doc.id,
      orderNumber: data['orderNumber']?.toString() ?? doc.id,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: data['status']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? '',
      createdAtMillis: createdAt?.millisecondsSinceEpoch ?? 0,
      itemsCount: itemsCount,
    );
  }
}

class _OrderListItem {
  const _OrderListItem({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAtMillis,
    required this.itemsCount,
  });

  final String id;
  final String orderNumber;
  final double total;
  final String status;
  final String paymentMethod;
  final int createdAtMillis;
  final int itemsCount;
}
