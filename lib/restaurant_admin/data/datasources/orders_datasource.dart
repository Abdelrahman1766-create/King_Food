import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/admin_constants.dart';
import '../models/order_model.dart';

/// Ù…ØµØ¯Ø± Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø®Ø§Øµ Ø¨Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ù…Ù† Firestore.
class OrdersRemoteDataSource {
  OrdersRemoteDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ordersCollection(
    String restaurantId,
  ) {
    return _firestore
        .collection(AdminConstants.restaurantsCollection)
        .doc(restaurantId)
        .collection(AdminConstants.ordersCollection);
  }

  Stream<List<OrderModel>> watchActiveOrders({required String restaurantId}) {
    print('ðŸ“¡ watchActiveOrders called for restaurantId: $restaurantId');
    // Get all orders (avoid status filters here to prevent mismatches)
    return _ordersCollection(
      restaurantId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      print(
        'ðŸ“¦ Firestore snapshot received with ${snapshot.docs.length} docs',
      );
      final allOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      print('âœ”ï¸ Returning ${allOrders.length} orders');
      return allOrders;
    });
  }

  Stream<List<OrderModel>> watchCompletedOrders({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _ordersCollection(
      restaurantId,
    ).where('status', isEqualTo: 'تم التوصيل');

    if (startDate != null) {
      query = query.where('deliveredAt', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('deliveredAt', isLessThanOrEqualTo: endDate);
    }

    return query
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<OrderModel>> watchOrdersByDriver({
    required String restaurantId,
    required String driverId,
  }) {
    return _ordersCollection(restaurantId)
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
          final orders =
              snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }

  Future<OrderModel?> getOrderById({
    required String restaurantId,
    required String orderId,
  }) async {
    final doc = await _ordersCollection(restaurantId).doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  Future<void> updateOrderStatus({
    required String restaurantId,
    required String orderId,
    required String status,
  }) {
    return _ordersCollection(restaurantId).doc(orderId).update({
      'status': status,
      if (status == 'ØªÙ… Ø§Ù„ØªÙˆØµÙŠÙ„')
        'deliveredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateOrderDriver({
    required String restaurantId,
    required String orderId,
    String? driverId,
    String? driverName,
  }) {
    return _ordersCollection(
      restaurantId,
    ).doc(orderId).update({'driverId': driverId, 'driverName': driverName});
  }

  Future<List<OrderModel>> searchOrders({
    required String restaurantId,
    String? orderNumber,
    String? customerName,
  }) async {
    Query<Map<String, dynamic>> query = _ordersCollection(restaurantId);

    if (orderNumber != null && orderNumber.isNotEmpty) {
      query = query.where('orderNumber', isEqualTo: orderNumber);
    }

    if (customerName != null && customerName.isNotEmpty) {
      query = query.where('customerName', isGreaterThanOrEqualTo: customerName);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }

  Future<List<OrderModel>> getOrdersByDriver({
    required String restaurantId,
    required String driverId,
  }) async {
    final snapshot = await _ordersCollection(restaurantId)
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
  }

  Future<void> logOrderStatusChange({
    required String restaurantId,
    required String orderId,
    required String status,
    required DateTime changedAt,
  }) {
    return _ordersCollection(restaurantId)
        .doc(orderId)
        .collection('status_logs')
        .add({'status': status, 'changedAt': Timestamp.fromDate(changedAt)});
  }
}
