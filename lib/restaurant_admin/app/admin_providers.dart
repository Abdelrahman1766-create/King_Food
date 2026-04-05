import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../data/datasources/auth_datasource.dart';
import '../data/datasources/menu_datasource.dart';
import '../data/datasources/orders_datasource.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/menu_repository_impl.dart';
import '../data/repositories/orders_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/menu_repository.dart';
import '../domain/repositories/orders_repository.dart';
import '../domain/usecases/add_menu_item_usecase.dart';
import '../domain/usecases/check_admin_role_usecase.dart';
import '../domain/usecases/delete_menu_item_usecase.dart';
import '../domain/usecases/get_order_by_id_usecase.dart';
import '../domain/usecases/get_price_logs_usecase.dart';
import '../domain/usecases/log_price_change_usecase.dart';
import '../domain/usecases/search_orders_usecase.dart';
import '../domain/usecases/sign_in_usecase.dart';
import '../domain/usecases/sign_out_usecase.dart';
import '../domain/usecases/update_menu_item_usecase.dart';
import '../domain/usecases/update_order_driver_usecase.dart';
import '../domain/usecases/update_order_status_usecase.dart';
//import '../domain/usecases/update_order_status_usecase.dart';
import '../domain/usecases/upload_item_image_usecase.dart';
import '../domain/usecases/watch_active_orders_usecase.dart';
import '../domain/usecases/watch_completed_orders_usecase.dart';
import '../domain/usecases/watch_menu_items_usecase.dart';
import '../domain/usecases/get_restaurant_id_usecase.dart';

/// مزود FirebaseAuth للوصول الموحد إلى المصادقة.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// مزود Cloud Firestore للتعامل مع بيانات الطلبات والأصناف.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// مزود Firebase Storage للتعامل مع رفع صور الأصناف.
final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// مزود Firebase Messaging لإرسال الإشعارات.
final messagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

/// مزود Firebase Functions لاستدعاء الدوال السحابية (إرسال الإشعارات).
final functionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'us-central1');
});

/// مزود Stream لحالة المستخدم الحالي.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// مزود مصدر بيانات المصادقة.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    messaging: ref.watch(messagingProvider),
  );
});

/// مزود مصدر بيانات الطلبات.
final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>((ref) {
  return OrdersRemoteDataSource(firestore: ref.watch(firestoreProvider));
});

/// مزود مصدر بيانات الأصناف.
final menuRemoteDataSourceProvider = Provider<MenuRemoteDataSource>((ref) {
  return MenuRemoteDataSource(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(storageProvider),
  );
});

/// مزود مستودع المصادقة.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

/// مزود مستودع الطلبات.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    functions: ref.watch(functionsProvider),
  );
});

/// مزود مستودع الأصناف.
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(ref.watch(menuRemoteDataSourceProvider));
});

/// مزود UseCase لتسجيل الدخول.
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

/// مزود UseCase لتسجيل الخروج.
final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

/// مزود UseCase للتحقق من صلاحية المسؤول.
final checkAdminRoleUseCaseProvider = Provider<CheckAdminRoleUseCase>((ref) {
  return CheckAdminRoleUseCase(ref.watch(authRepositoryProvider));
});

/// مزود UseCase لمراقبة الطلبات النشطة.
final watchActiveOrdersUseCaseProvider = Provider<WatchActiveOrdersUseCase>((
  ref,
) {
  return WatchActiveOrdersUseCase(ref.watch(ordersRepositoryProvider));
});

/// مزود UseCase لمراقبة الطلبات المكتملة.
final watchCompletedOrdersUseCaseProvider =
    Provider<WatchCompletedOrdersUseCase>((ref) {
      return WatchCompletedOrdersUseCase(ref.watch(ordersRepositoryProvider));
    });

/// مزود UseCase لجلب طلب محدد.
final getOrderByIdUseCaseProvider = Provider<GetOrderByIdUseCase>((ref) {
  return GetOrderByIdUseCase(ref.watch(ordersRepositoryProvider));
});

/// مزود UseCase لتحديث حالة الطلب.
final updateOrderStatusUseCaseProvider = Provider<UpdateOrderStatusUseCase>((
  ref,
) {
  return UpdateOrderStatusUseCase(ref.watch(ordersRepositoryProvider));
});

/// مزود UseCase لتحديث سائق الطلب.
final updateOrderDriverUseCaseProvider = Provider<UpdateOrderDriverUseCase>((
  ref,
) {
  return UpdateOrderDriverUseCase(ref.watch(ordersRepositoryProvider));
});

/// مزود UseCase للبحث عن الطلبات.
final searchOrdersUseCaseProvider = Provider<SearchOrdersUseCase>((ref) {
  return SearchOrdersUseCase(ref.watch(ordersRepositoryProvider));
});

/// مزود UseCase لمراقبة الأصناف.
final watchMenuItemsUseCaseProvider = Provider<WatchMenuItemsUseCase>((ref) {
  return WatchMenuItemsUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لإضافة صنف جديد.
final addMenuItemUseCaseProvider = Provider<AddMenuItemUseCase>((ref) {
  return AddMenuItemUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لتحديث صنف.
final updateMenuItemUseCaseProvider = Provider<UpdateMenuItemUseCase>((ref) {
  return UpdateMenuItemUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لحذف صنف.
final deleteMenuItemUseCaseProvider = Provider<DeleteMenuItemUseCase>((ref) {
  return DeleteMenuItemUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لرفع صورة صنف.
final uploadItemImageUseCaseProvider = Provider<UploadItemImageUseCase>((ref) {
  return UploadItemImageUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لتسجيل تغيير السعر.
final logPriceChangeUseCaseProvider = Provider<LogPriceChangeUseCase>((ref) {
  return LogPriceChangeUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لجلب سجل تغييرات الأسعار.
final getPriceLogsUseCaseProvider = Provider<GetPriceLogsUseCase>((ref) {
  return GetPriceLogsUseCase(ref.watch(menuRepositoryProvider));
});

/// مزود UseCase لجلب معرف المطعم الحالي.
final getRestaurantIdUseCaseProvider = Provider<GetRestaurantIdUseCase>((ref) {
  return GetRestaurantIdUseCase(ref.watch(authRepositoryProvider));
});

/// StateNotifier to hold admin mode and persist to SharedPreferences.
class AdminModeNotifier extends StateNotifier<bool> {
  AdminModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool('is_admin_mode') ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> setAdminMode(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin_mode', value);
    } catch (_) {}
  }
}

final adminModeProvider = StateNotifierProvider<AdminModeNotifier, bool>((ref) {
  return AdminModeNotifier();
});
