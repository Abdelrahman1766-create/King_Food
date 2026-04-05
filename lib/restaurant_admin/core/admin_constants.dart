/// ملف يحتوي على الثوابت العامة للوحة مسؤول المطعم.
class AdminConstants {
  // مسارات التجميع في Firestore
  static const usersCollection = 'users';
  static const restaurantsCollection = 'restaurants';
  static const ordersCollection = 'orders';
  static const menuItemsCollection = 'menu_items';
  static const priceLogsCollection = 'price_logs';

  // عنوان المطعم (نقطة استلام الطلبات للسعاة)
  static const restaurantAddress = 'Академика Кирпичникова, 11';

  // حالات الطلب المعتمدة
  static const orderStatuses = <String>[
    'pending',
    'accepted',
    'preparing',
    'on_the_way',
    'delivered',
  ];

  // المدة الزمنية لتحديث الطلبات في حال استخدام Interval Refresh (بالثواني)
  static const ordersRefreshInterval = Duration(seconds: 30);

  // أسماء الأدوار
  static const adminRole = 'restaurant_admin';
}
