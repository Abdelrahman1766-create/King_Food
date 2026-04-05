import 'package:firebase_auth/firebase_auth.dart';

import '../../core/admin_failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

/// تنفيذ مستودع المصادقة باستخدام Firebase.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource, {
    bool requireAdminRole = true,
  }) : _requireAdminRole = requireAdminRole;

  final AuthRemoteDataSource _remoteDataSource;
  final bool _requireAdminRole;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _remoteDataSource.signIn(email: email, password: password);

      if (_requireAdminRole) {
        final isAdmin = await hasRestaurantRole();
        if (!isAdmin) {
          await _remoteDataSource.signOut();
          throw const AuthFailure(
            'Account is not authorized to access the admin panel.',
          );
        }
        final token = await _remoteDataSource.getCurrentDeviceToken();
        if (token != null) {
          await updateAdminFcmToken(token);
        }
      }
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure('Sign-in error: ${e.code}');
    } on Exception catch (e) {
      throw AuthFailure('Sign-in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } on Exception catch (e) {
      throw AuthFailure('Sign-out failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> hasRestaurantRole() async {
    try {
      return _remoteDataSource.hasRestaurantRole();
    } on Exception catch (e) {
      throw AuthFailure('Permission check failed: ${e.toString()}');
    }
  }

  @override
  Future<String> getRestaurantId() async {
    try {
      return _remoteDataSource.getRestaurantId();
    } on Exception catch (e) {
      throw AuthFailure('Failed to get restaurant ID: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAdminDisplayName() async {
    try {
      return _remoteDataSource.getAdminDisplayName();
    } on Exception catch (e) {
      throw AuthFailure('Failed to get admin name: ${e.toString()}');
    }
  }

  @override
  Future<String?> getAdminFcmToken() async {
    try {
      return _remoteDataSource.getAdminFcmToken();
    } on Exception catch (e) {
      throw AuthFailure('Failed to get notification token: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAdminFcmToken(String token) async {
    try {
      await _remoteDataSource.updateAdminFcmToken(token);
    } on Exception catch (e) {
      throw AuthFailure('Failed to update notification token: ${e.toString()}');
    }
  }
}

