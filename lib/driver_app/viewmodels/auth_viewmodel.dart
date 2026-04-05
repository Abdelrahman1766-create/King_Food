import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../restaurant_admin/domain/repositories/auth_repository.dart';
import '../../utils/i18n.dart';

/// حالة المصادقة للسائق.
class AuthState {
  final bool isLoading;
  final String? restaurantId;
  final String? driverId;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.restaurantId,
    this.driverId,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    String? restaurantId,
    String? driverId,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      restaurantId: restaurantId ?? this.restaurantId,
      driverId: driverId ?? this.driverId,
      error: error ?? this.error,
    );
  }
}

/// ViewModel للمصادقة للسائقين.
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final FirebaseAuth _firebaseAuth;

  AuthViewModel(this._authRepository, this._firebaseAuth)
    : super(const AuthState()) {
    _initialize();
  }

  static const _demoRestaurantId = 'demo_restaurant';

  /// تهيئة ViewModel والتحقق من حالة تسجيل الدخول.
  Future<void> _initialize() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      state = state.copyWith(
        restaurantId: _demoRestaurantId,
        driverId: user.uid,
      );
    }
  }

  /// تسجيل دخول السائق.
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_firebaseAuth.currentUser != null) {
        await _authRepository.signOut();
      }
      await _authRepository.signIn(email: email, password: password);
      final user = _firebaseAuth.currentUser;
      // Ensure fresh token after sign-in to avoid permission-denied on first query.
      await user?.getIdToken(true);
      state = state.copyWith(
        isLoading: false,
        restaurantId: _demoRestaurantId,
        driverId: user?.uid,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: tNoContext('Sign-in failed: $e', 'Ошибка входа: $e'),
      );
    }
  }

  /// تسجيل خروج السائق.
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        error: tNoContext('Sign-out failed: $e', 'Ошибка выхода: $e'),
      );
    }
  }

  /// التحقق من وجود سائق مسجل دخول.
  bool get isSignedIn => state.driverId != null;
}
