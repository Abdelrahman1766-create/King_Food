import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_failures.dart';
import '../../app/admin_providers.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/check_admin_role_usecase.dart';
import '../../domain/usecases/get_restaurant_id_usecase.dart';
import '../../../utils/i18n.dart';

/// الحالة الخاصة بالتحكم في عملية تسجيل الدخول وإدارة معلومات المطعم.
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.restaurantId,
    this.isAdmin = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? restaurantId;
  final bool isAdmin;

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? restaurantId,
    bool? isAdmin,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      restaurantId: restaurantId ?? this.restaurantId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// التحكم في حالة المصادقة لمسؤول المطعم.
class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(
    this._signInUseCase,
    this._signOutUseCase,
    this._checkAdminRoleUseCase,
    this._getRestaurantIdUseCase,
  ) : super(const AuthState()) {
    _initialize();
  }

  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final CheckAdminRoleUseCase _checkAdminRoleUseCase;
  final GetRestaurantIdUseCase _getRestaurantIdUseCase;

  Future<void> _initialize() async {
    try {
      final isAdmin = await _checkAdminRoleUseCase();
      if (!isAdmin) return;
      final restaurantId = await _getRestaurantIdUseCase();
      state = state.copyWith(isAdmin: true, restaurantId: restaurantId);
    } catch (_) {
      // Ignore initialization errors; explicit sign-in will surface messages.
    }
  }

  /// محاولة تسجيل الدخول بواسطة البريد وكلمة المرور.
  Future<void> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        errorMessage: tNoContext(
          'Please enter email and password.',
          'Пожалуйста, введите email и пароль.',
        ),
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _signInUseCase(email: email, password: password);
      final isAdmin = await _checkAdminRoleUseCase();
      if (!isAdmin) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: tNoContext(
            'This account does not have admin privileges.',
            'У этого аккаунта нет прав администратора.',
          ),
          isAdmin: false,
        );
        return;
      }

      final restaurantId = await _getRestaurantIdUseCase();
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        restaurantId: restaurantId,
        isAdmin: true,
      );
    } on Failure catch (failure) {
      await _signOutUseCase();
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      await _signOutUseCase();
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Unexpected error: $error',
          'Неожиданная ошибка: $error',
        ),
      );
    }
  }

  /// تسجيل خروج للمسؤول.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _signOutUseCase();
      state = const AuthState();
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: tNoContext(
          'Failed to sign out: $error',
          'Не удалось выйти: $error',
        ),
      );
    }
  }
}

/// مزود `StateNotifier` الخاص بالمصادقة.
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(
    ref.watch(signInUseCaseProvider),
    ref.watch(signOutUseCaseProvider),
    ref.watch(checkAdminRoleUseCaseProvider),
    ref.watch(getRestaurantIdUseCaseProvider),
  );
});
