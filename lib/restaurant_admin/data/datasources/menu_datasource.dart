import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/admin_constants.dart';
import '../models/menu_item_model.dart';
import '../models/price_log_model.dart';

/// مصدر البيانات الخاص بالأصناف وأسعارها.
class MenuRemoteDataSource {
  MenuRemoteDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _menuCollection(
    String restaurantId,
  ) {
    return _firestore
        .collection(AdminConstants.restaurantsCollection)
        .doc(restaurantId)
        .collection(AdminConstants.menuItemsCollection);
  }

  Stream<List<MenuItemModel>> watchMenuItems({required String restaurantId}) {
    return _menuCollection(restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addMenuItem({
    required String restaurantId,
    required MenuItemModel item,
  }) {
    return _menuCollection(restaurantId).doc(item.id).set(item.toFirestore());
  }

  Future<void> updateMenuItem({
    required String restaurantId,
    required MenuItemModel item,
  }) {
    return _menuCollection(restaurantId)
        .doc(item.id)
        .update(item.toFirestore());
  }

  Future<void> deleteMenuItem({
    required String restaurantId,
    required String itemId,
  }) {
    return _menuCollection(restaurantId).doc(itemId).delete();
  }

  Future<String> uploadItemImage({
    required String restaurantId,
    required String filePath,
  }) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.last;
    final ref = _storage.ref().child(
          'restaurants/$restaurantId/menu_images/$fileName',
        );
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  CollectionReference<Map<String, dynamic>> _priceLogsCollection(
    String restaurantId,
    String itemId,
  ) {
    return _menuCollection(restaurantId)
        .doc(itemId)
        .collection(AdminConstants.priceLogsCollection);
  }

  Future<void> logPriceChange({
    required String restaurantId,
    required PriceLogModel log,
  }) {
    return _priceLogsCollection(restaurantId, log.itemId).add(log.toFirestore());
  }

  Future<List<PriceLogModel>> getPriceLogs({
    required String restaurantId,
    required String itemId,
  }) async {
    final snapshot = await _priceLogsCollection(restaurantId, itemId)
        .orderBy('changedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PriceLogModel.fromFirestore(doc))
        .toList();
  }
}
