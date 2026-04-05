import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'driver_router.dart';
import '../../restaurant_admin/data/datasources/auth_datasource.dart';
import '../../restaurant_admin/data/datasources/orders_datasource.dart';
import '../../restaurant_admin/data/repositories/auth_repository_impl.dart';
import '../../restaurant_admin/data/repositories/orders_repository_impl.dart';
import '../../restaurant_admin/domain/repositories/auth_repository.dart';
import '../../restaurant_admin/domain/repositories/orders_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/orders_viewmodel.dart';

/// مزود FirebaseAuth للوصول الموحد إلى المصادقة.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// مزود Firestore للوصول الموحد إلى قاعدة البيانات.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// مزود FirebaseMessaging للإشعارات.
final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// مزود FirebaseFunctions للدوال السحابية.
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

/// مزود مصدر بيانات المصادقة.
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    messaging: ref.watch(firebaseMessagingProvider),
  );
});

/// مزود مصدر بيانات الطلبات.
final ordersDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

/// مزود مستودع المصادقة.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(authDataSourceProvider),
    requireAdminRole: false,
  );
});

/// مزود مستودع الطلبات.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersDataSourceProvider),
    functions: ref.watch(firebaseFunctionsProvider),
  );
});

/// مزود حالة المصادقة.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// مزود AuthViewModel.
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final authRepository = ref.watch(authRepositoryProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthViewModel(authRepository, firebaseAuth);
});

/// مزود OrdersViewModel.
final ordersViewModelProvider =
    StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
      final ordersRepository = ref.watch(ordersRepositoryProvider);
      final authViewModel = ref.watch(authViewModelProvider.notifier);
      return OrdersViewModel(ordersRepository, authViewModel);
    });

/// تطبيق السائق.
/// يعتمد على [GoRouter] للتنقل وعلى [Riverpod] لإدارة الحالة.
class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(driverRouterProvider);

    return MaterialApp.router(
      title: 'King Food - Driver',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
