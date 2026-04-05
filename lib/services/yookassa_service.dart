import 'package:http/http.dart' as http;
import 'dart:convert';

/// خدمة YooKassa للدفع الآمن في روسيا
/// YooKassa Payment Service for Russia
class YooKassaService {
  // ⚠️ استبدل هذه بمفاتيحك الفعلية من YooKassa
  // Replace with your actual keys from YooKassa dashboard
  static const String shopId = 'YOUR_SHOP_ID'; // معرف المتجر
  static const String secretKey = 'YOUR_SECRET_KEY'; // المفتاح السري

  static const String baseUrl = 'https://payment.yookassa.ru/api/v3';

  /// إنشاء دفعة جديدة
  /// Create a new payment
  static Future<PaymentResult> createPayment({
    required double amount, // المبلغ بالروبل
    required String orderId, // معرف الطلب
    required String customerEmail, // بريد المشتري
    required String customerPhone, // هاتف المشتري
    required String description, // وصف الطلب
  }) async {
    try {
      final auth = base64Encode(utf8.encode('$shopId:$secretKey'));

      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/json',
          'Idempotency-Key': orderId, // منع الطلبات المكررة
        },
        body: jsonEncode({
          'amount': {
            'value': amount.toStringAsFixed(2),
            'currency': 'RUB', // الروبل الروسي
          },
          'payment_method_data': {'type': 'bank_card'},
          'confirmation': {
            'type': 'redirect',
            'return_url': 'https://yourapp.com/payment/success',
          },
          'description': description,
          'metadata': {
            'order_id': orderId,
            'customer_email': customerEmail,
            'customer_phone': customerPhone,
          },
          'capture': true, // التقاط الأموال مباشرة
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentResult.success(
          paymentId: data['id'],
          confirmationUrl: data['confirmation']['confirmation_url'],
          amount: amount,
          status: data['status'],
        );
      } else {
        return PaymentResult.error(
          'Failed to create payment: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PaymentResult.error('Error: $e');
    }
  }

  /// التحقق من حالة الدفعة
  /// Check payment status
  static Future<PaymentStatusResult> getPaymentStatus(String paymentId) async {
    try {
      final auth = base64Encode(utf8.encode('$shopId:$secretKey'));

      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {'Authorization': 'Basic $auth'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ترجمة الحالات
        final status = _translateStatus(data['status']);

        return PaymentStatusResult.success(
          paymentId: data['id'],
          status: status,
          amount: double.parse(data['amount']['value'].toString()),
          currency: data['amount']['currency'],
          createdAt: data['created_at'],
          description: data['description'] ?? '',
        );
      } else {
        return PaymentStatusResult.error('Payment not found');
      }
    } catch (e) {
      return PaymentStatusResult.error('Error: $e');
    }
  }

  /// استرجاع الأموال (Refund)
  /// Refund payment
  static Future<RefundResult> refund(String paymentId, double amount) async {
    try {
      final auth = base64Encode(utf8.encode('$shopId:$secretKey'));

      final response = await http.post(
        Uri.parse('$baseUrl/payments/$paymentId/refunds'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/json',
          'Idempotency-Key': 'refund_${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'amount': {'value': amount.toStringAsFixed(2), 'currency': 'RUB'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RefundResult.success(
          refundId: data['id'],
          amount: amount,
          status: data['status'],
        );
      } else {
        return RefundResult.error('Refund failed');
      }
    } catch (e) {
      return RefundResult.error('Error: $e');
    }
  }

  /// ترجمة حالات الدفع
  static String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'waiting_for_capture':
        return 'في انتظار الالتقاط';
      case 'succeeded':
        return 'نجح';
      case 'canceled':
        return 'تم الإلغاء';
      default:
        return status;
    }
  }
}

/// نتيجة إنشاء الدفعة
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? confirmationUrl;
  final double? amount;
  final String? status;
  final String? error;

  PaymentResult({
    required this.success,
    this.paymentId,
    this.confirmationUrl,
    this.amount,
    this.status,
    this.error,
  });

  factory PaymentResult.success({
    required String paymentId,
    required String confirmationUrl,
    required double amount,
    required String status,
  }) {
    return PaymentResult(
      success: true,
      paymentId: paymentId,
      confirmationUrl: confirmationUrl,
      amount: amount,
      status: status,
    );
  }

  factory PaymentResult.error(String error) {
    return PaymentResult(success: false, error: error);
  }
}

/// نتيجة الاستعلام عن حالة الدفعة
class PaymentStatusResult {
  final bool success;
  final String paymentId;
  final String status;
  final double amount;
  final String currency;
  final String createdAt;
  final String description;
  final String? error;

  PaymentStatusResult({
    required this.success,
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.description,
    this.error,
  });

  factory PaymentStatusResult.success({
    required String paymentId,
    required String status,
    required double amount,
    required String currency,
    required String createdAt,
    required String description,
  }) {
    return PaymentStatusResult(
      success: true,
      paymentId: paymentId,
      status: status,
      amount: amount,
      currency: currency,
      createdAt: createdAt,
      description: description,
    );
  }

  factory PaymentStatusResult.error(String error) {
    return PaymentStatusResult(
      success: false,
      paymentId: '',
      status: 'error',
      amount: 0,
      currency: 'RUB',
      createdAt: '',
      description: '',
      error: error,
    );
  }
}

/// نتيجة استرجاع الأموال
class RefundResult {
  final bool success;
  final String? refundId;
  final double? amount;
  final String? status;
  final String? error;

  RefundResult({
    required this.success,
    this.refundId,
    this.amount,
    this.status,
    this.error,
  });

  factory RefundResult.success({
    required String refundId,
    required double amount,
    required String status,
  }) {
    return RefundResult(
      success: true,
      refundId: refundId,
      amount: amount,
      status: status,
    );
  }

  factory RefundResult.error(String error) {
    return RefundResult(success: false, error: error);
  }
}

/// بطاقات الاختبار (Test Cards)
class TestCards {
  // بطاقات ناجحة
  static const String visaSuccess = '4111111111111111';
  static const String mastercardSuccess = '5555555555554444';
  static const String amexSuccess = '378282246310005';

  // بطاقات مرفوضة (للاختبار)
  static const String visaDeclined = '4000000000000002';
  static const String visaError = '4000000000000069';

  // CVC/CVV للاختبار
  static const String testCvc = '123';
  static const String testExpiry = '12/25';
}
