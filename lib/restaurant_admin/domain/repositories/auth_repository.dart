/// واجهة لمستودع المصادقة والصلاحيات.
abstract class AuthRepository {
  /// تسجيل الدخول باستخدام البريد وكلمة المرور.
  Future<void> signIn({required String email, required String password});

  /// تسجيل الخروج من حساب المطعم.
  Future<void> signOut();

  /// التأكد من أن المستخدم الحالي لديه دور مسؤول مطعم.
  Future<bool> hasRestaurantRole();

  /// الحصول على معرف المطعم المرتبط بالمستخدم الحالي.
  Future<String> getRestaurantId();

  /// الحصول على اسم مسؤول المطعم لعرضه في الواجهة.
  Future<String?> getAdminDisplayName();

  /// الحصول على رمز FCM الحالي لحساب المطعم.
  Future<String?> getAdminFcmToken();

  /// تحديث رمز FCM الحالي في قاعدة البيانات.
  Future<void> updateAdminFcmToken(String token);
}
