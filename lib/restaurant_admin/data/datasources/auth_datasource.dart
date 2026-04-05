import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/admin_constants.dart';

/// Ù…ØµØ¯Ø± Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„ Ø¹Ù† Ø¹Ù…Ù„ÙŠØ§Øª Ø§Ù„Ù…ØµØ§Ø¯Ù‚Ø© ÙˆØ§Ù„ØµÙ„Ø§Ø­ÙŠØ§Øª Ù„Ù…Ø³Ø¤ÙˆÙ„ Ø§Ù„Ù…Ø·Ø¹Ù….
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _messaging = messaging;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDoc(String uid) {
    return _firestore
        .collection(AdminConstants.usersCollection)
        .doc(uid)
        .get();
  }

  Future<bool> hasRestaurantRole() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    final doc = await _getUserDoc(user.uid);
    final data = doc.data();
    if (data == null) return false;

    final role = data['role'] as String?;
    return role == AdminConstants.adminRole;
  }

  Future<String> getRestaurantId() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Current user not found.',
      );
    }

    final doc = await _getUserDoc(user.uid);
    final data = doc.data();
    if (data == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-user-data',
        message: 'User data is missing.',
      );
    }

    final restaurantId = data['restaurantId'] as String?;
    if (restaurantId == null || restaurantId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'missing-restaurant-id',
        message: 'Restaurant ID is not set for this user.',
      );
    }

    return restaurantId;
  }

  Future<String?> getAdminDisplayName() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _getUserDoc(user.uid);
    final data = doc.data();
    return data?['displayName'] as String? ?? user.displayName;
  }

  Future<String?> getAdminFcmToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _getUserDoc(user.uid);
    final data = doc.data();
    return data?['fcmToken'] as String?;
  }

  Future<void> updateAdminFcmToken(String token) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await _firestore
        .collection(AdminConstants.usersCollection)
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  Future<String?> getCurrentDeviceToken() async {
    return _messaging.getToken();
  }
}
