enum PaymentStatus { pending, processing, success, failed, cancelled }

class PaymentService {
  // Stripe API Keys (test mode)
  static const String stripePublishableKey =
      'pk_test_51234567890abcdefghijk'; // Replace with your actual key
  static const String stripeSecretKey =
      'sk_test_1234567890abcdefghijk'; // Replace with your actual key

  static Future<Map<String, dynamic>> processOnlinePayment({
    required double amount,
    required String currency,
    required String orderId,
    required String customerEmail,
    required String customerPhone,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    try {
      // Validate card details
      if (!_validateCardNumber(cardNumber)) {
        return {
          'status': PaymentStatus.failed,
          'error': 'Invalid card number',
          'message': 'Card number validation failed',
        };
      }

      if (!_validateExpiryDate(expiryDate)) {
        return {
          'status': PaymentStatus.failed,
          'error': 'Invalid expiry date',
          'message': 'Expiry date has passed',
        };
      }

      if (!_validateCVV(cvv)) {
        return {
          'status': PaymentStatus.failed,
          'error': 'Invalid CVV',
          'message': 'CVV must be 3-4 digits',
        };
      }

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Create payment token (in real implementation, use Stripe API)
      final paymentToken = _generatePaymentToken(cardNumber, expiryDate, cvv);

      // Process payment through Stripe
      final paymentResult = await _createStripePayment(
        token: paymentToken,
        amount: (amount * 100).toInt(), // Convert to cents
        currency: currency,
        orderId: orderId,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        cardHolderName: cardHolderName,
      );

      return paymentResult;
    } catch (e) {
      return {
        'status': PaymentStatus.failed,
        'error': e.toString(),
        'message': 'Payment processing failed',
      };
    }
  }

  static bool _validateCardNumber(String cardNumber) {
    // Remove spaces and dashes
    final sanitized = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (sanitized.length < 13 || sanitized.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    int isEven = 0;
    for (int i = sanitized.length - 1; i >= 0; i--) {
      int digit = int.parse(sanitized[i]);

      if (isEven == 1) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = 1 - isEven;
    }

    return sum % 10 == 0;
  }

  static bool _validateExpiryDate(String expiryDate) {
    // Format: MM/YY
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiryDate)) {
      return false;
    }

    final parts = expiryDate.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);

    if (month < 1 || month > 12) {
      return false;
    }

    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;

    if (year < currentYear) {
      return false;
    }

    if (year == currentYear && month < currentMonth) {
      return false;
    }

    return true;
  }

  static bool _validateCVV(String cvv) {
    return RegExp(r'^\d{3,4}$').hasMatch(cvv);
  }

  static String _generatePaymentToken(
    String cardNumber,
    String expiryDate,
    String cvv,
  ) {
    // In real implementation, use Stripe.js to create token
    // This is a mock token for testing
    return 'tok_visa_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<Map<String, dynamic>> _createStripePayment({
    required String token,
    required int amount,
    required String currency,
    required String orderId,
    required String customerEmail,
    required String customerPhone,
    required String cardHolderName,
  }) async {
    try {
      // In real implementation, make HTTP request to Stripe API
      // Here we simulate a successful payment with stages

      // Stage 1: Validating card information
      await Future.delayed(const Duration(milliseconds: 500));

      // Stage 2: Encrypting payment data
      await Future.delayed(const Duration(milliseconds: 800));

      // Stage 3: Sending to payment gateway
      await Future.delayed(const Duration(milliseconds: 700));

      // Simulate successful payment
      final transactionId = 'pi_${DateTime.now().millisecondsSinceEpoch}';
      return {
        'status': PaymentStatus.success,
        'transactionId': transactionId,
        'chargeId': 'ch_${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'currency': currency,
        'orderId': orderId,
        'timestamp': DateTime.now().toIso8601String(),
        'paymentMethod': 'card',
        'cardHolderName': cardHolderName,
        'customerEmail': customerEmail,
        'receiptUrl': 'https://receipts.stripe.com/receipt/$transactionId',
        'message': 'Payment processed successfully',
      };
    } catch (e) {
      return {
        'status': PaymentStatus.failed,
        'error': e.toString(),
        'message': 'Failed to create Stripe payment',
      };
    }
  }

  static Future<bool> refundPayment(String transactionId) async {
    try {
      // Simulate refund processing
      await Future.delayed(const Duration(seconds: 2));

      // In real implementation, call Stripe refund API
      // POST /v1/charges/{chargeId}/refunds
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus(
    String transactionId,
  ) async {
    try {
      // Simulate status check
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'status': PaymentStatus.success,
        'transactionId': transactionId,
        'message': 'Payment completed successfully',
      };
    } catch (e) {
      return {
        'status': PaymentStatus.failed,
        'error': e.toString(),
        'message': 'Unable to retrieve payment status',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getPaymentHistory(
    String customerId,
  ) async {
    try {
      // Simulate fetching payment history
      await Future.delayed(const Duration(milliseconds: 500));

      return [
        {
          'transactionId': 'pi_test_001',
          'amount': 1500,
          'currency': 'RUB',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'status': PaymentStatus.success,
        },
      ];
    } catch (e) {
      return [];
    }
  }
}

class PaymentGateway {
  static const String baseUrl =
      'https://api.stripe.com/v1'; // Stripe API endpoint

  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    try {
      // In real implementation, make HTTP POST request
      // POST /v1/payment_intents
      return {
        'id': 'pi_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'status': 'requires_payment_method',
        'clientSecret':
            'pi_test_secret_${DateTime.now().millisecondsSinceEpoch}',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'message': 'Failed to create payment intent',
      };
    }
  }
}

class PaymentValidator {
  static String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final sanitized = value.replaceAll(RegExp(r'\D'), '');

    if (sanitized.length < 13) {
      return 'Card number must be at least 13 digits';
    }

    if (!PaymentService._validateCardNumber(value)) {
      return 'Invalid card number';
    }

    return null;
  }

  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    if (!PaymentService._validateExpiryDate(value)) {
      return 'Invalid expiry date (use MM/YY)';
    }

    return null;
  }

  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (!PaymentService._validateCVV(value)) {
      return 'CVV must be 3-4 digits';
    }

    return null;
  }

  static String? validateCardHolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card holder name is required';
    }

    if (value.length < 2) {
      return 'Invalid name';
    }

    return null;
  }
}
