import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order.dart' as domain;

/// Ù†Ù…ÙˆØ°Ø¬ Ù„ØªØ­ÙˆÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø·Ù„Ø¨ Ø¨ÙŠÙ† Firestore ÙˆÙƒÙŠØ§Ù† Ø§Ù„Ø¯ÙˆÙ…ÙŠÙ†.
class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.customerId,
    this.customerFcmToken,
    required this.items,
    required this.paymentMethod,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.deliveredAt,
    this.notes,
    this.driverId,
    this.driverName,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? customerId;
  final String? customerFcmToken;
  final List<OrderItemModel> items;
  final String paymentMethod;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? driverId;
  final String? driverName;

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      customerAddress: data['customerAddress'] as String? ?? '',
      deliveryLat: (data['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (data['deliveryLng'] as num?)?.toDouble(),
      customerId: data['customerId'] as String?,
      customerFcmToken: data['customerFcmToken'] as String?,
      items: items,
      paymentMethod: data['paymentMethod'] as String? ?? 'ØºÙŠØ± Ù…Ø­Ø¯Ø¯',
      status: data['status'] as String? ?? 'Ù‚ÙŠØ¯ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©',
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ??
          (data['total'] as num?)?.toDouble() ??
          0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
    );
  }

  domain.Order toEntity() {
    return domain.Order(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      customerId: customerId,
      customerFcmToken: customerFcmToken,
      items: items.map((e) => e.toEntity()).toList(),
      paymentMethod: paymentMethod,
      status: status,
      totalPrice: totalPrice,
      createdAt: createdAt,
      deliveredAt: deliveredAt,
      notes: notes,
      driverId: driverId,
      driverName: driverName,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      if (deliveryLat != null) 'deliveryLat': deliveryLat,
      if (deliveryLng != null) 'deliveryLng': deliveryLng,
      if (customerId != null) 'customerId': customerId,
      if (customerFcmToken != null) 'customerFcmToken': customerFcmToken,
      'items': items.map((e) => e.toMap()).toList(),
      'paymentMethod': paymentMethod,
      'status': status,
      'totalPrice': totalPrice,
      'total': totalPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (notes != null) 'notes': notes,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
    };
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double price;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      itemId: map['itemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  domain.OrderItem toEntity() {
    return domain.OrderItem(
      itemId: itemId,
      name: name,
      quantity: quantity,
      price: price,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

