import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../controllers/cart_controller.dart';
import '../models/address.dart';
import '../services/payment_service.dart';
import '../utils/responsive_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/i18n.dart';

class PaymentPage extends StatefulWidget {
  final CartController cart;
  final Address deliveryAddress;
  final bool isTest;

  const PaymentPage({
    super.key,
    required this.cart,
    required this.deliveryAddress,
    this.isTest = false,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  bool _isProcessing = false;
  bool _saveCard = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    // If this is a test/fake online payment, simulate success.
    if (widget.isTest) {
      setState(() => _isProcessing = true);
      // Simulate loading for 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Show success dialog and auto-close after 1.5s
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                t(context, 'Payment successful', 'Платеж успешен'),
              ),
            ],
          ),
          content: const SizedBox.shrink(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      // Close dialog
      if (mounted) Navigator.of(context).pop();

      // Return success to caller (CheckoutPage)
      if (mounted) Navigator.of(context).pop(true);

      setState(() => _isProcessing = false);
      return;
    }

    // Default (real) payment flow
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Show processing status dialog
      _showProcessingDialog();

      final result = await PaymentService.processOnlinePayment(
        amount: widget.cart.total,
        currency: 'RUB', // Russian Ruble
        orderId: 'order_${DateTime.now().millisecondsSinceEpoch}',
        customerEmail: 'customer@example.com', // Get from user profile
        customerPhone: widget.deliveryAddress.phone,
        cardNumber: _cardNumberController.text,
        expiryDate: _expiryController.text,
        cvv: _cvvController.text,
        cardHolderName: _cardHolderController.text,
      );

      // Close processing dialog
      if (mounted) Navigator.of(context).pop();

      if (result['status'] == PaymentStatus.success) {
        _showSuccessDialog(result);
      } else {
        _showErrorDialog(result['message'] ?? 'Payment failed');
      }
    } catch (e) {
      // Close processing dialog if still open
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Payment processing error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showProcessingDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),
                Text(
                  l10n.processingPayment,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobileSize: 16,
                      tabletSize: 18,
                      desktopSize: 20,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                ),
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔒 ${l10n.paymentProcessingStages}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobileSize: 11,
                            tabletSize: 12,
                            desktopSize: 13,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.isMobile(context) ? 6 : 8,
                      ),
                      _buildProcessingStep(l10n.verifyCardData, true, context),
                      _buildProcessingStep(l10n.encryptData, true, context),
                      _buildProcessingStep(l10n.sendToGateway, true, context),
                      _buildProcessingStep(l10n.confirmPayment, false, context),
                    ],
                  ),
                ),
                SizedBox(
                  height: ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                ),
                Text(
                  l10n.securelySending,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobileSize: 10,
                      tabletSize: 11,
                      desktopSize: 12,
                    ),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingStep(
    String text,
    bool isActive,
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.isMobile(context) ? 3 : 4,
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            size: ResponsiveHelper.getSmallIconSize(context),
            color: isActive ? Colors.green : Colors.grey,
          ),
          SizedBox(width: ResponsiveHelper.isMobile(context) ? 6 : 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobileSize: 10,
                  tabletSize: 11,
                  desktopSize: 12,
                ),
                color: isActive ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('✅ Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction ID:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(result['transactionId'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  Text(
                    'Amount:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${(result['amount'] / 100).toStringAsFixed(2)} ${result['currency']}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Card Holder:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(result['cardHolderName'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  Text('Time:', style: Theme.of(context).textTheme.titleSmall),
                  Text(result['timestamp'] ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop(true); // Return success
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('❌ Payment Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '💡 Test Card Numbers:\n• 4111 1111 1111 1111\n• 5555 5555 5555 4444\n• 3782 822463 10005',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _processPayment(); // Retry payment
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(
      locale: 'ru_RU',
      decimalDigits: 0,
    );
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '💳 ${l10n.onlinePayment}',
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobileSize: 18,
              tabletSize: 20,
              desktopSize: 22,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary
              Container(
                padding: EdgeInsets.all(
                  ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📦 Order Summary',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobileSize: 16,
                          tabletSize: 18,
                          desktopSize: 20,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobileSize: 14,
                              tabletSize: 15,
                              desktopSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          currency.format(widget.cart.total),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobileSize: 16,
                              tabletSize: 18,
                              desktopSize: 20,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveHelper.isMobile(context) ? 6 : 8,
                    ),
                    Text(
                      '📍 ${widget.deliveryAddress.label}, ${widget.deliveryAddress.city}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobileSize: 12,
                          tabletSize: 13,
                          desktopSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.isMobile(context) ? 16 : 20),

              // Payment Form
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💳 Card Information',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobileSize: 16,
                                tabletSize: 18,
                                desktopSize: 20,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.isMobile(context)
                                ? 12
                                : 16,
                          ),

                          // Card Number
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              prefixIcon: const Icon(Icons.credit_card),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: '1234 5678 9012 3456',
                              contentPadding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.isMobile(context)
                                    ? 12
                                    : 16,
                                horizontal: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 19,
                            validator: PaymentValidator.validateCardNumber,
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobileSize: 14,
                                tabletSize: 15,
                                desktopSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.isMobile(context)
                                ? 12
                                : 16,
                          ),

                          // Card Holder Name
                          TextFormField(
                            controller: _cardHolderController,
                            decoration: InputDecoration(
                              labelText: 'Card Holder Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.isMobile(context)
                                    ? 12
                                    : 16,
                                horizontal: 12,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobileSize: 14,
                                tabletSize: 15,
                                desktopSize: 16,
                              ),
                            ),
                            validator: PaymentValidator.validateCardHolderName,
                          ),
                          SizedBox(
                            height: ResponsiveHelper.isMobile(context)
                                ? 12
                                : 16,
                          ),

                          // Expiry and CVV
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryController,
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: 'MM/YY',
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical:
                                          ResponsiveHelper.isMobile(context)
                                          ? 12
                                          : 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _ExpiryDateInputFormatter(),
                                  ],
                                  maxLength: 5,
                                  validator:
                                      PaymentValidator.validateExpiryDate,
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobileSize: 14,
                                          tabletSize: 15,
                                          desktopSize: 16,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveHelper.isMobile(context)
                                    ? 12
                                    : 16,
                              ),
                              SizedBox(
                                width: ResponsiveHelper.isMobile(context)
                                    ? 90
                                    : 110,
                                child: TextFormField(
                                  controller: _cvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    prefixIcon: const Icon(Icons.security),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical:
                                          ResponsiveHelper.isMobile(context)
                                          ? 12
                                          : 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: true,
                                  validator: PaymentValidator.validateCVV,
                                  style: TextStyle(
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobileSize: 14,
                                          tabletSize: 15,
                                          desktopSize: 16,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ResponsiveHelper.isMobile(context)
                                ? 12
                                : 16,
                          ),

                          // Save Card Checkbox
                          CheckboxListTile(
                            title: Text(
                              'Save card for future payments',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      mobileSize: 12,
                                      tabletSize: 13,
                                      desktopSize: 14,
                                    ),
                              ),
                            ),
                            value: _saveCard,
                            onChanged: (value) =>
                                setState(() => _saveCard = value ?? false),
                            contentPadding: EdgeInsets.zero,
                          ),

                          // Security Note
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveHelper.isMobile(context)
                                  ? 10
                                  : 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  size: ResponsiveHelper.getSmallIconSize(
                                    context,
                                  ),
                                  color: Colors.grey[600],
                                ),
                                SizedBox(
                                  width: ResponsiveHelper.isMobile(context)
                                      ? 6
                                      : 8,
                                ),
                                Expanded(
                                  child: Text(
                                    'Your payment information is encrypted and secure',
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveHelper.getResponsiveFontSize(
                                            context,
                                            mobileSize: 11,
                                            tabletSize: 12,
                                            desktopSize: 13,
                                          ),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.isMobile(context) ? 12.0 : 16.0,
              ),

              // Pay Button
              SizedBox(
                width: double.infinity,
                height: ResponsiveHelper.getButtonHeight(context),
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width:
                                  ResponsiveHelper.getSmallIconSize(context) +
                                  4,
                              height:
                                  ResponsiveHelper.getSmallIconSize(context) +
                                  4,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveHelper.isMobile(context)
                                  ? 8
                                  : 12,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.processingPayment,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize:
                                          ResponsiveHelper.getResponsiveFontSize(
                                            context,
                                            mobileSize: 13,
                                            tabletSize: 14,
                                            desktopSize: 15,
                                          ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    l10n.securelySending,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize:
                                          ResponsiveHelper.getResponsiveFontSize(
                                            context,
                                            mobileSize: 10,
                                            tabletSize: 11,
                                            desktopSize: 12,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '💳 Pay ${currency.format(widget.cart.total)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              mobileSize: 14,
                              tabletSize: 16,
                              desktopSize: 18,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // Test Cards Info
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.isMobile(context) ? 10.0 : 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🧪 ${l10n.testCards}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobileSize: 11,
                            tabletSize: 12,
                            desktopSize: 13,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.isMobile(context) ? 4 : 6,
                      ),
                      Text(
                        l10n.testCardsInfo,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobileSize: 10,
                            tabletSize: 11,
                            desktopSize: 12,
                          ),
                          color: Colors.orange[700],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
