# 🚀 دليل البدء السريع - YooKassa في روسيا

## 📋 الخطوات الـ 5 للبدء:

### ✅ الخطوة 1: إنشاء حساب YooKassa

```
1. اذهب إلى: https://yookassa.ru
2. اضغط "Зарегистрироваться" (Create Account)
3. اختر نوع الحساب:
   - Для ИП/ООО (للشركات)
   - Для физических лиц (للأفراد)
4. أكمل البيانات المطلوبة
```

### ✅ الخطوة 2: التحقق من الحساب

```
1. حمّل وثائق التحقق (جواز سفر/إقامة)
2. انتظر الموافقة (عادة 1-2 يوم)
3. سيصلك بريد إلكتروني بالموافقة
```

### ✅ الخطوة 3: الحصول على المفاتيح

```
1. ادخل لوحة التحكم (Dashboard)
2. اذهب إلى: Интеграция → API ключи
3. ستجد:
   ✓ Shop ID (معرف المتجر)
   ✓ Secret Key (المفتاح السري - احفظه بأمان!)
```

### ✅ الخطوة 4: تحديث الكود

**في `lib/services/yookassa_service.dart`:**

```dart
// استبدل هذا:
static const String shopId = 'YOUR_SHOP_ID';
static const String secretKey = 'YOUR_SECRET_KEY';

// بهذا (مثال):
static const String shopId = '123456789';
static const String secretKey = 'test_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890';
```

### ✅ الخطوة 5: تثبيت المكتبات المطلوبة

```bash
# في مجلد المشروع:
flutter pub add http

# تأكد من وجود crypto (عادة مثبت بالفعل):
flutter pub add crypto
```

---

## 💳 الاستخدام الأساسي:

### إنشاء دفعة جديدة:

```dart
import 'package:king_food/services/yookassa_service.dart';

// في صفحة الدفع
final result = await YooKassaService.createPayment(
  amount: 2500.00, // المبلغ بالروبل
  orderId: 'order_12345',
  customerEmail: 'customer@example.com',
  customerPhone: '+7 999 123 45 67',
  description: 'Food Order - 5 items',
);

if (result.success) {
  print('✅ الدفعة تم إنشاؤها بنجاح!');
  print('رقم الدفعة: ${result.paymentId}');
  print('رابط الدفع: ${result.confirmationUrl}');
  
  // فتح رابط الدفع في المتصفح
  // await launchUrl(Uri.parse(result.confirmationUrl!));
} else {
  print('❌ خطأ: ${result.error}');
}
```

### التحقق من حالة الدفعة:

```dart
final status = await YooKassaService.getPaymentStatus('payment_id_here');

if (status.success) {
  print('حالة الدفعة: ${status.status}');
  // الحالات الممكنة:
  // - قيد الانتظار (pending)
  // - في انتظار الالتقاط (waiting_for_capture)
  // - نجح (succeeded)
  // - تم الإلغاء (canceled)
} else {
  print('❌ خطأ: ${status.error}');
}
```

### استرجاع الأموال:

```dart
final refund = await YooKassaService.refund(
  'payment_id_here',
  2500.00, // المبلغ المراد استرجاعه
);

if (refund.success) {
  print('✅ تم استرجاع الأموال بنجاح!');
  print('رقم الاسترجاع: ${refund.refundId}');
} else {
  print('❌ خطأ: ${refund.error}');
}
```

---

## 🧪 الاختبار مع بطاقات الاختبار:

### بطاقات نجح (للاختبار):

```
1. Visa (ناجحة):
   رقم: 4111111111111111
   CVC: 123
   الصلاحية: 12/25

2. Mastercard (ناجحة):
   رقم: 5555555555554444
   CVC: 123
   الصلاحية: 12/25

3. American Express (ناجحة):
   رقم: 378282246310005
   CVC: 123
   الصلاحية: 12/25
```

### بطاقات مرفوضة (للاختبار):

```
- رقم: 4000000000000002 (سيتم الرفض)
- رقم: 4000000000000069 (خطأ في المعالجة)
```

---

## 📊 مثال كامل في تطبيقك:

```dart
// في payment_page.dart

import 'package:king_food/services/yookassa_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPageState extends State {
  bool _isProcessing = false;

  Future<void> _processPaymentWithYooKassa() async {
    setState(() => _isProcessing = true);

    try {
      // إنشاء دفعة
      final result = await YooKassaService.createPayment(
        amount: widget.cart.total,
        orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
        customerEmail: 'customer@example.com',
        customerPhone: '+7 999 123 45 67',
        description: 'Food Order from KING_FOOD',
      );

      if (result.success) {
        // فتح صفحة الدفع
        if (result.confirmationUrl != null) {
          await launchUrl(
            Uri.parse(result.confirmationUrl!),
            mode: LaunchMode.externalApplication,
          );

          // حفظ معرف الدفعة للتحقق لاحقاً
          _paymentId = result.paymentId;

          // عرض رسالة النجاح
          _showSuccessDialog(result);
        }
      } else {
        _showErrorDialog(result.error ?? 'خطأ غير معروف');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _checkPaymentStatus(String paymentId) async {
    final status = await YooKassaService.getPaymentStatus(paymentId);
    
    if (status.success) {
      print('حالة الدفعة: ${status.status}');
      
      // إذا كانت الدفعة ناجحة
      if (status.status == 'نجح') {
        // حفظ الطلب في Firebase
        _saveOrderToFirebase();
        
        // عرض رسالة النجاح
        _showSuccessMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💳 الدفع عبر YooKassa')),
      body: Column(
        children: [
          // ملخص الطلب
          _buildOrderSummary(),
          
          // زر الدفع
          ElevatedButton(
            onPressed: _isProcessing ? null : _processPaymentWithYooKassa,
            child: _isProcessing
                ? const CircularProgressIndicator()
                : const Text('الدفع الآن'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔒 نصائح الأمان المهمة:

### ✅ يجب فعله:

```dart
✓ استخدم HTTPS فقط
✓ حفظ Secret Key في متغيرات البيئة
✓ لا تحفظ المفاتيح في الكود مباشرة
✓ استخدم Firebase Remote Config للمفاتيح
✓ قم بالتحقق من التوقيع (Signature) من YooKassa
✓ اختبر بطاقات الاختبار أولاً قبل الإنتاج
```

### ❌ لا تفعل:

```dart
❌ لا تشارك Secret Key مع أحد
❌ لا تحفظ بيانات البطاقة الكاملة
❌ لا تستخدم HTTP (بدون S)
❌ لا تسجل بيانات حساسة في الـ Logs
❌ لا تضع المفاتيح في GitHub العام
```

---

## 🚨 استكشاف الأخطاء:

### المشكلة: "Shop ID غير صحيح"

```
الحل:
1. تحقق من نسخ Shop ID بشكل صحيح
2. لا توجد مسافات إضافية
3. استخدم نفس الحساب
```

### المشكلة: "خطأ في المصادقة (401)"

```
الحل:
1. تحقق من Secret Key
2. تأكد من تشفير Base64 صحيح
3. تحقق من الوقت في الجهاز (قد يكون مختلف)
```

### المشكلة: "رفع الصفحة بطيء"

```
الحل:
1. تحقق من اتصال الإنترنت
2. جرب بطاقة اختبار مختلفة
3. تحقق من خوادم YooKassa على: https://status.yookassa.ru
```

### المشكلة: "البطاقة مرفوضة"

```
الحل:
1. جرب بطاقة اختبار أخرى
2. تأكد من صحة CVC والصلاحية
3. تحقق من حد البطاقة اليومي
```

---

## 📚 الموارد الإضافية:

### التوثيق الرسمي:
- [YooKassa Documentation](https://yookassa.ru/docs)
- [API Reference](https://yookassa.ru/docs/api)
- [SDK Examples](https://yookassa.ru/docs/sdk)

### مكتبات مفيدة:
```bash
flutter pub add url_launcher  # فتح روابط الدفع
flutter pub add dio           # بديل http
flutter pub add get_storage   # حفظ بيانات محلياً
```

---

## ✅ قائمة التحقق النهائية:

- [ ] تم إنشاء حساب YooKassa
- [ ] تم التحقق من الحساب
- [ ] حصلت على Shop ID و Secret Key
- [ ] أضفت المفاتيح في الكود
- [ ] ثبتت مكتبة http
- [ ] اختبرت مع بطاقات الاختبار
- [ ] عملت معالجة الأخطاء
- [ ] اختبرت على جهاز فعلي
- [ ] جاهزة للإطلاق! 🚀

---

**الحالة:** ✅ جاهز للاستخدام الفوري
**آخر تحديث:** 29 يناير 2026
**الدعم:** البريد: support@yookassa.ru | الهاتف: +7 (495) 660-7470
