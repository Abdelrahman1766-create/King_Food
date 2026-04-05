import 'package:equatable/equatable.dart';

/// عنصر ضمن الطلب يمثل منتجاً واحداً مع كميته.
class OrderItem extends Equatable {
  const OrderItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double price;

  double get total => quantity * price;

  @override
  List<Object?> get props => [itemId, name, quantity, price];
}

/// كيان الطلب يمثل البيانات الأساسية للطلب.
class Order extends Equatable {
  const Order({
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
  final List<OrderItem> items;
  final String paymentMethod;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? driverId;
  final String? driverName;

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? customerId,
    String? customerFcmToken,
    List<OrderItem>? items,
    String? paymentMethod,
    String? status,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? notes,
    String? driverId,
    String? driverName,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      customerId: customerId ?? this.customerId,
      customerFcmToken: customerFcmToken ?? this.customerFcmToken,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    customerPhone,
    customerAddress,
    deliveryLat,
    deliveryLng,
    customerId,
    customerFcmToken,
    items,
    paymentMethod,
    status,
    totalPrice,
    createdAt,
    deliveredAt,
    notes,
    driverId,
    driverName,
  ];
}
