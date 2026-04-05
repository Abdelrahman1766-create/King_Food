import '../entities/menu_item.dart';
import '../entities/price_log.dart';

/// واجهة لمستودع إدارة الأصناف والأسعار.
abstract class MenuRepository {
  /// بث لجميع الأصناف الحالية للمطعم.
  Stream<List<MenuItemEntity>> watchMenuItems({required String restaurantId});

  /// إضافة صنف جديد.
  Future<void> addMenuItem({
    required String restaurantId,
    required MenuItemEntity item,
  });

  /// تحديث صنف موجود.
  Future<void> updateMenuItem({
    required String restaurantId,
    required MenuItemEntity item,
  });

  /// حذف صنف.
  Future<void> deleteMenuItem({
    required String restaurantId,
    required String itemId,
  });

  /// رفع صورة صنف إلى التخزين وإرجاع الرابط المباشر.
  Future<String> uploadItemImage({
    required String restaurantId,
    required String filePath,
  });

  /// تسجيل سجل تغيير السعر.
  Future<void> logPriceChange({
    required String restaurantId,
    required PriceLog log,
  });

  /// جلب سجلات تغيير السعر لصنف معين.
  Future<List<PriceLog>> getPriceLogs({
    required String restaurantId,
    required String itemId,
  });
}
