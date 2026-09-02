import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Orders_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/auth_session.dart';
import '../../utils/payment_config.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import '../Registrations/login.dart';
import 'Cart_provider.dart';
import 'Complete_orders.dart';
import 'cart_models.dart';
import 'ssl_payment_page.dart';

enum PaymentMethod { bkash, nagad, rocket, upay, cashOnDelivery }

class SubmitOrderPage extends StatefulWidget {
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;

  const SubmitOrderPage({
    super.key,
    required this.totalAmount,
    this.couponCode,
    this.couponDiscount = 0.0,
  });

  @override
  State<SubmitOrderPage> createState() => _SubmitOrderPageState();
}

class _SubmitOrderPageState extends State<SubmitOrderPage> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  PaymentConfig _config = const PaymentConfig();
  bool _loadingCfg = true;
  bool _addressValid = false;
  bool _agreedToTerms = false;

  // Coupon state
  bool _isCouponApplied = false;
  double _couponRate = 0;
  String? _couponMessage;

  // Delivery charge state
  double _insideDhakaCharge = 60;
  double _outsideDhakaCharge = 120;
  bool _isInsideDhaka = false; // default: Outside Dhaka (120 TK like website)

  double get _deliveryCharge =>
      _isInsideDhaka ? _insideDhakaCharge : _outsideDhakaCharge;
  double get _couponDiscount {
    if (widget.couponDiscount > 0) return widget.couponDiscount;
    if (!_isCouponApplied || _couponRate <= 0) return 0;
    try {
      final cart = context.read<CartProvider>();
      return cart.getCartTotal() * _couponRate;
    } catch (_) {
      return widget.totalAmount * _couponRate;
    }
  }

  // Always use live cart total so QTY changes on this page are reflected
  double get _grandTotal {
    try {
      final cart = context.read<CartProvider>();
      return cart.getCartTotal() - _couponDiscount + _deliveryCharge;
    } catch (_) {
      return widget.totalAmount - _couponDiscount + _deliveryCharge;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadUserAddress();
    _addressController.addListener(() {
      final valid = _addressController.text.trim().length >= 5;
      if (valid != _addressValid) setState(() => _addressValid = valid);
    });
  }

  Future<void> _loadUserAddress() async {
    try {
      final userData = await AuthSession.getUserData();
      if (userData != null) {
        setState(() {
          if (userData.address.isNotEmpty) {
            _addressController.text = userData.address;
            _addressValid = userData.address.trim().length >= 5;
          }
          // Pre-fill name from user data if available
          final name = userData.fullName.trim();
          if (name.isNotEmpty) _nameController.text = name;
          // Pre-fill mobile from user data if available
          if (userData.phone.isNotEmpty)
            _mobileController.text = userData.phone;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user address: $e');
    }
  }

  Future<void> _loadConfig() async {
    PaymentConfig localCfg = const PaymentConfig();

    try {
      // First load local config as fallback.
      localCfg = await PaymentConfigStore.load();
    } catch (_) {
      // Web hosting can temporarily lose access to storage; keep defaults.
    }

    if (!mounted) return;
    setState(() {
      _config = localCfg;
      _loadingCfg = false;
      if (localCfg.bkashEnabled) {
        _selectedMethod = PaymentMethod.bkash;
      } else if (localCfg.nagadEnabled) {
        _selectedMethod = PaymentMethod.nagad;
      } else if (localCfg.rocketEnabled) {
        _selectedMethod = PaymentMethod.rocket;
      } else if (localCfg.upayEnabled) {
        _selectedMethod = PaymentMethod.upay;
      } else {
        _selectedMethod = PaymentMethod.cashOnDelivery;
      }
    });

    // Then fetch live numbers from the API (admin-managed)
    try {
      final response = await ApiService.get(
        '/payment_methods',
        withAuth: false,
      ).timeout(const Duration(seconds: 8));
      final methods = response is List
          ? response
          : (response['payment_methods'] as List? ??
                response['data'] as List? ??
                []);

      String bkashNumber = localCfg.bkashNumber;
      String nagadNumber = localCfg.nagadNumber;
      String rocketNumber = localCfg.rocketNumber;
      String upayNumber = localCfg.upayNumber;
      bool bkashEnabled = false;
      bool nagadEnabled = false;
      bool rocketEnabled = false;
      bool upayEnabled = false;

      for (final m in methods) {
        final map = Map<String, dynamic>.from(m as Map);
        final name = (map['method_name'] ?? '').toString().toLowerCase();
        final enabled = _parseBool(map['is_enabled']);
        final number = (map['account_number'] ?? '').toString().trim();

        if (name.contains('bkash')) {
          bkashEnabled = enabled;
          if (number.isNotEmpty) bkashNumber = number;
        } else if (name.contains('nagad')) {
          nagadEnabled = enabled;
          if (number.isNotEmpty) nagadNumber = number;
        } else if (name.contains('rocket')) {
          rocketEnabled = enabled;
          if (number.isNotEmpty) rocketNumber = number;
        } else if (name.contains('upay')) {
          upayEnabled = enabled;
          if (number.isNotEmpty) upayNumber = number;
        }
      }

      // If no mobile banking method found, fall back to local
      if (!bkashEnabled && !nagadEnabled && !rocketEnabled && !upayEnabled) {
        bkashEnabled = localCfg.bkashEnabled;
        nagadEnabled = localCfg.nagadEnabled;
        rocketEnabled = localCfg.rocketEnabled;
        upayEnabled = localCfg.upayEnabled;
      }

      final cfg = PaymentConfig(
        bkashEnabled: bkashEnabled,
        nagadEnabled: nagadEnabled,
        rocketEnabled: rocketEnabled,
        upayEnabled: upayEnabled,
        bkashNumber: bkashNumber,
        nagadNumber: nagadNumber,
        rocketNumber: rocketNumber,
        upayNumber: upayNumber,
      );

      // Persist so offline fallback stays fresh
      await PaymentConfigStore.save(cfg);

      // Load delivery charges from site_settings
      try {
        final inside = await ApiService.getSiteSetting(
          'delivery_charge_inside_dhaka',
        );
        final outside = await ApiService.getSiteSetting(
          'delivery_charge_outside_dhaka',
        );
        final insideVal =
            double.tryParse(inside['setting_value']?.toString() ?? '') ?? 60;
        final outsideVal =
            double.tryParse(outside['setting_value']?.toString() ?? '') ?? 120;
        if (mounted) {
          setState(() {
            _insideDhakaCharge = insideVal;
            _outsideDhakaCharge = outsideVal;
          });
        }
      } catch (_) {
        // keep defaults
      }

      if (!mounted) return;
      setState(() {
        _config = cfg;
        if (cfg.bkashEnabled) {
          _selectedMethod = PaymentMethod.bkash;
        } else if (cfg.nagadEnabled) {
          _selectedMethod = PaymentMethod.nagad;
        } else if (cfg.rocketEnabled) {
          _selectedMethod = PaymentMethod.rocket;
        } else if (cfg.upayEnabled) {
          _selectedMethod = PaymentMethod.upay;
        } else {
          _selectedMethod = PaymentMethod.cashOnDelivery;
        }
      });
    } catch (e) {
      // API failed — local config already shown, nothing more to do
    }
  }

  bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  Future<void> _applyCoupon() async {
    final input = _couponController.text.trim().toUpperCase();
    if (input.isEmpty) {
      setState(() {
        _couponMessage = 'Please enter a coupon code';
      });
      return;
    }
    try {
      final data = await ApiService.getActiveCoupon();
      final code = (data?['code'] as String?)?.toUpperCase();
      final percent = (data?['percent'] as num?)?.toDouble() ?? 0.0;
      if (code != null && code == input && percent > 0) {
        setState(() {
          _isCouponApplied = true;
          _couponRate = percent / 100.0;
          _couponMessage = 'Coupon applied: ${percent.toStringAsFixed(0)}% OFF';
        });
      } else {
        setState(() {
          _isCouponApplied = false;
          _couponRate = 0;
          _couponMessage = 'Invalid coupon code';
        });
      }
    } catch (_) {
      setState(() {
        _isCouponApplied = false;
        _couponRate = 0;
        _couponMessage = 'Coupon check failed';
      });
    }
  }

  void _resetCoupon() {
    setState(() {
      _isCouponApplied = false;
      _couponRate = 0;
      _couponMessage = null;
      _couponController.clear();
    });
  }

  Future<void> _launchPolicyUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _processBKashPayment() async {
    final phone = _phoneController.text.trim();
    final valid = RegExp(r'^01[0-9]{9}$').hasMatch(phone);
    if (!valid) {
      _showError(
        'Please enter a valid 11-digit bKash phone number (e.g., 01712345678)',
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final tx = 'BKASH-${DateTime.now().millisecondsSinceEpoch}';
      _completePayment(PaymentMethod.bkash, tx);
    } catch (e) {
      if (mounted) _showError('Payment processing error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // TEMP OFF: Nagad gateway disabled (simulated success)
  Future<void> _processNagadPayment() async {
    final phone = _phoneController.text.trim();
    final valid = RegExp(r'^01[0-9]{9}$').hasMatch(phone);
    if (!valid) {
      _showError(
        'Please enter a valid 11-digit Nagad phone number (e.g., 01712345678)',
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final tx = 'NAGAD-${DateTime.now().millisecondsSinceEpoch}';
      _completePayment(PaymentMethod.nagad, tx);
    } catch (e) {
      if (mounted) _showError('Error processing Nagad payment: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _completePayment(PaymentMethod method, String transactionId) async {
    // Prevent double submission
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _doCompletePayment(method, transactionId);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _doCompletePayment(
    PaymentMethod method,
    String transactionId,
  ) async {
    final cartProvider = context.read<CartProvider>();

    // Removed frontend stock validation - backend will handle it authoritatively
    // This prevents race conditions and ensures accurate stock checks

    // Continue with payment if stock is available
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 5));
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final estimatedDelivery =
        '${deliveryDate.day} ${months[deliveryDate.month - 1]} ${deliveryDate.year}';

    final ordersProvider = context.read<OrdersProvider>();
    final total = _grandTotal;
    final methodName = method == PaymentMethod.bkash
        ? 'bKash'
        : method == PaymentMethod.nagad
        ? 'Nagad'
        : method == PaymentMethod.rocket
        ? 'Rocket'
        : method == PaymentMethod.upay
        ? 'Upay'
        : 'Cash on Delivery';

    String? orderId;
    List<CartItem> capturedItems = [];
    double capturedTotal = 0.0;
    try {
      final token = await ApiService.getToken();

      // If token exists but is expired/invalid, the API will return 401.
      // Guest users (no token) are now supported — order proceeds without auth.
      // If a logged-in user's token expired, show re-login prompt.
      final isLoggedIn = await AuthSession.isLoggedIn();
      if (isLoggedIn && (token == null || token.isEmpty)) {
        // Token was cleared (expired) but user thinks they're logged in
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Session Expired'),
            content: const Text(
              'Your session has expired. Please log in again to place your order.\n\n'
              'Your cart has been preserved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        );
        return;
      }

      // Validate name
      final customerName = _nameController.text.trim();
      if (customerName.isEmpty) {
        if (!context.mounted) return;
        _showError('Please enter your full name.');
        return;
      }

      // Validate mobile
      final customerMobile = _mobileController.text.trim();
      if (customerMobile.isEmpty) {
        if (!context.mounted) return;
        _showError('Please enter your mobile number.');
        return;
      }
      if (!RegExp(r'^01[0-9]{9}$').hasMatch(customerMobile)) {
        if (!context.mounted) return;
        _showError(
          'Please enter a valid 11-digit mobile number (e.g., 01712345678).',
        );
        return;
      }

      // Validate delivery address
      String deliveryAddress = _addressController.text.trim();
      if (deliveryAddress.isEmpty) {
        final userData = await AuthSession.getUserData();
        deliveryAddress = userData?.address ?? '';
      }

      // Add city and postal code if provided
      final city = _cityController.text.trim();
      final postalCode = _postalCodeController.text.trim();
      if (city.isNotEmpty) {
        deliveryAddress += ', $city';
      }
      if (postalCode.isNotEmpty) {
        deliveryAddress += ' - $postalCode';
      }

      // Frontend validation
      if (deliveryAddress.isEmpty) {
        if (!context.mounted) return;
        _showError('Please enter your delivery address.');
        return;
      }

      if (deliveryAddress.length < 10) {
        if (!context.mounted) return;
        _showError(
          'Delivery address is too short (minimum 10 characters required).',
        );
        return;
      }

      if (deliveryAddress.length > 500) {
        if (!context.mounted) return;
        _showError(
          'Delivery address is too long (maximum 500 characters allowed).',
        );
        return;
      }

      final body = {
        'total_amount': total,
        'payment_method': methodName,
        'delivery_address': deliveryAddress,
        'customer_name': customerName,
        'customer_phone': customerMobile,
        'transaction_id': transactionId,
        'estimated_delivery': estimatedDelivery,
        'delivery_charge': _deliveryCharge,
        'delivery_zone': _isInsideDhaka ? 'inside_dhaka' : 'outside_dhaka',
        if (_couponDiscount > 0) 'coupon_discount': _couponDiscount,
        if (widget.couponCode != null && widget.couponCode!.isNotEmpty)
          'coupon_code': widget.couponCode,
        'items': cartProvider.items.map((item) {
          // Extract numeric product_id — strip any prefix like "trend_db_", "deal_db_" etc.
          final rawId = item.productId.replaceAll(RegExp(r'[^0-9]'), '');
          final pid = rawId.isNotEmpty ? int.tryParse(rawId) : null;
          return {
            'product_id': pid,
            'product_name': item.name,
            'quantity': item.quantity,
            'price': item.price,
            'image_url': item.imageUrl,
            'color': '',
          };
        }).toList(),
      };

      final result = await ApiService.placeOrder(body);
      // Prefer formatted order_code if provided; else numeric id
      final code = (result['order_code'] ?? result['orderCode'])?.toString();
      final idStr = (result['order_id'] ?? result['orderId'])?.toString();
      orderId =
          code ??
          (idStr != null
              ? 'EC-${DateTime.now().toUtc().toString().substring(0, 10).replaceAll(RegExp(r'[^0-9]'), '')}-$idStr'
              : 'EC-${DateTime.now().millisecondsSinceEpoch}');

      // Capture cart items before clearing (for invoice)
      capturedItems = List<CartItem>.from(cartProvider.items);
      capturedTotal = _grandTotal;

      // Only clear cart after successful order creation
      await cartProvider.clearCart();
      // Only refresh orders from API if user is logged in (guests have no order history endpoint)
      final isLoggedInNow = await AuthSession.isLoggedIn();
      if (isLoggedInNow) {
        await ordersProvider.refreshFromApi();
      }
      // Invalidate product cache so stock counts refresh on next page visit
      ApiService.invalidateCache('/products');
      if (!context.mounted) return;
    } on ApiException catch (e) {
      // Handle API errors properly - don't clear cart or show success
      if (!context.mounted) return;

      // Check if it's a stock error
      if (e.message.toLowerCase().contains('insufficient stock') ||
          e.message.toLowerCase().contains('out of stock')) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ Stock Unavailable'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to cart
                },
                child: const Text('Update Cart'),
              ),
            ],
          ),
        );
        return;
      }

      // Other API errors
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Order Failed'),
          content: Text(
            'Unable to place order: ${e.message}\n\n'
            'Your cart has been preserved. Please try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    } catch (e) {
      // Network or unexpected errors
      if (!context.mounted) return;
      final errMsg = e.toString();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Order Failed'),
          content: Text(
            errMsg.contains('TimeoutException') || errMsg.contains('timeout')
                ? 'Request timed out. Please check your connection and try again.\n\nYour cart has been preserved.'
                : 'Unable to place order: $errMsg\n\nYour cart has been preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('✓ Payment Successful'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Method: ${method == PaymentMethod.bkash
                    ? "bKash"
                    : method == PaymentMethod.nagad
                    ? "Nagad"
                    : method == PaymentMethod.rocket
                    ? "Rocket"
                    : method == PaymentMethod.upay
                    ? "Upay"
                    : "Cash on Delivery"}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // Order Summary Breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 13)),
                        Text(
                          '৳${(capturedTotal - _couponDiscount - _deliveryCharge).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Delivery Charge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Charge:', style: TextStyle(fontSize: 13)),
                        Text(
                          '৳${_deliveryCharge.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, color: Colors.orange),
                        ),
                      ],
                    ),
                    // Coupon Discount (if applied)
                    if (_couponDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(fontSize: 13)),
                          Text(
                            '-৳${_couponDiscount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(thickness: 1),
                    const SizedBox(height: 8),
                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '৳${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Order ID: ${orderId ?? 'EC-${DateTime.now().millisecondsSinceEpoch}'}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 4),
              SelectableText(
                'Txn ID: $transactionId',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              Text(
                'Delivery: $_isInsideDhaka ? "Inside Dhaka" : "Outside Dhaka"',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                '✓ Payment verified and processing your order...',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => OrderCompletedPage(
                    orderId: orderId ?? '',
                    paymentMethod: method == PaymentMethod.bkash
                        ? 'bKash'
                        : method == PaymentMethod.nagad
                        ? 'Nagad'
                        : method == PaymentMethod.rocket
                        ? 'Rocket'
                        : method == PaymentMethod.upay
                        ? 'Upay'
                        : 'Cash on Delivery',
                    transactionId: transactionId,
                    estimatedDelivery: estimatedDelivery,
                    orderItems: capturedItems,
                    totalAmount: capturedTotal,
                  ),
                ),
                (route) => route.isFirst,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(PaymentMethod method) {
    _phoneController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPaymentSheet(method),
    );
  }

  Widget _buildPaymentSheet(PaymentMethod method) {
    final methodName = method == PaymentMethod.bkash
        ? 'bKash'
        : method == PaymentMethod.nagad
        ? 'Nagad'
        : method == PaymentMethod.rocket
        ? 'Rocket'
        : 'Upay';
    final methodColor = method == PaymentMethod.bkash
        ? const Color(0xFFE2136E)
        : method == PaymentMethod.nagad
        ? const Color(0xFFFF6300)
        : method == PaymentMethod.rocket
        ? const Color(0xFF8B1A8B)
        : const Color(0xFF00A651);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              method == PaymentMethod.bkash
                  ? Icons.mobile_screen_share
                  : Icons.payment,
              color: methodColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pay with $methodName',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: ৳${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            enabled: !_isProcessing,
            decoration: InputDecoration(
              labelText: '$methodName Phone Number',
              hintText: '01X-XXXXXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (method == PaymentMethod.bkash) {
                        _processBKashPayment();
                      } else {
                        _processNagadPayment();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: methodColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Proceed to Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInstruction(PaymentMethod method) {
    if (method == PaymentMethod.cashOnDelivery) {
      _completePayment(method, 'COD-${DateTime.now().millisecondsSinceEpoch}');
      return;
    }
    // Show payment method picker bottom sheet
    _showOnlinePaymentSheet();
  }

  void _showOnlinePaymentSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SslPaymentPage(
          config: _config,
          grandTotal: _grandTotal,
          onMethodSelected: (method) {
            Navigator.pop(context); // close SslPaymentPage
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _PaymentInstructionPage(
                  method: method,
                  amount: _grandTotal,
                  onVerify: (txn) {
                    if (txn.isEmpty) {
                      _showError('Please enter the Transaction ID');
                      return;
                    }
                    _completePayment(method, txn);
                  },
                  config: _config,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required String title,
    required String assetLogo,
    required Color accentColor,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(assetLogo, height: 28, width: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? accentColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodCard() {
    final isSelected = _selectedMethod == PaymentMethod.cashOnDelivery;

    return InkWell(
      onTap: () =>
          setState(() => _selectedMethod = PaymentMethod.cashOnDelivery),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF2E7D32),
              size: 26,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cash on Delivery',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCfg) {
      return const Scaffold(
        appBar: Header(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Guard: if cart is empty, show empty state instead of order form
    final cartItems = context.watch<CartProvider>().items;
    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: const Header(),
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add some products to your cart first.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Continue Shopping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final r = AppResponsive.of(context);
    final isNarrow = r.isSmallMobile || r.isMobile || r.isTablet;

    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top title ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.white,
              child: const Text(
                'SUBMIT ORDER FORM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Divider(height: 1),

            // ── Two-column layout ──
            Padding(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: isNarrow
                  ? Column(
                      children: [
                        _buildAddressCard(),
                        const SizedBox(height: 20),
                        _buildContinueButton(),
                        const SizedBox(height: 20),
                        _buildOrderSummaryCard(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Order form + buttons
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildAddressCard(),
                              const SizedBox(height: 20),
                              _buildContinueButton(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: Cart items + order summary
                        Expanded(flex: 5, child: _buildOrderSummaryCard()),
                      ],
                    ),
            ),

            // ── Bottom trust bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 32,
                runSpacing: 10,
                children: [
                  _trustItem(Icons.shield_outlined, 'Secure Payment'),
                  _trustItem(Icons.local_shipping_outlined, 'Fast Delivery'),
                  _trustItem(Icons.headset_mic_outlined, '24/7 Support'),
                  _trustItem(Icons.replay_outlined, 'Easy Returns'),
                ],
              ),
            ),

            // ── Full footer ──
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildAddressCard() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1a1a1a), width: 1.5),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          RichText(
            text: const TextSpan(
              text: 'Full Name ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              filled: true,
              fillColor: Colors.grey[50],
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mobile Number
          RichText(
            text: const TextSpan(
              text: 'Mobile Number ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '01XXXXXXXXX',
              filled: true,
              fillColor: Colors.grey[50],
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Address
          RichText(
            text: const TextSpan(
              text: 'Delivery Address ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'House/Flat no, Road, Area',
              filled: true,
              fillColor: Colors.grey[50],
              border: inputBorder,
              enabledBorder: inputBorder,
              focusedBorder: focusedBorder,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delivery Area — radio buttons like the website
          const Text(
            'Delivery Area',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildDeliveryRadio(
            label:
                'Outside Dhaka - ৳${_outsideDhakaCharge.toStringAsFixed(0)}TK',
            value: false,
          ),
          const SizedBox(height: 6),
          _buildDeliveryRadio(
            label: 'Inside Dhaka - ৳${_insideDhakaCharge.toStringAsFixed(0)}TK',
            value: true,
          ),
          const SizedBox(height: 16),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  activeColor: const Color(0xFF1a1a1a),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    const Text(
                      'I agree with the ',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _launchPolicyUrl(AppConstants.termsOfService),
                      child: const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ', ',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => _launchPolicyUrl(AppConstants.returnPolicy),
                      child: const Text(
                        'Return Policy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ', and ',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    GestureDetector(
                      onTap: () => _launchPolicyUrl(AppConstants.privacyPolicy),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryRadio({required String label, required bool value}) {
    final isSelected = _isInsideDhaka == value;
    return GestureDetector(
      onTap: () => setState(() => _isInsideDhaka = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black87 : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Right panel: coupon + cart items table + totals
  Widget _buildOrderSummaryCard() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.getCartTotal();
        final discount = _couponDiscount;
        final payable = subtotal - discount + _deliveryCharge;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coupon row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        enabled: !_isCouponApplied,
                        decoration: InputDecoration(
                          hintText: 'Coupon Code',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: Colors.black87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isCouponApplied ? _resetCoupon : _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(_isCouponApplied ? 'Remove' : 'Apply'),
                    ),
                  ],
                ),
              ),
              if (_couponMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Text(
                    _couponMessage!,
                    style: TextStyle(
                      fontSize: 11,
                      color: _isCouponApplied
                          ? Colors.green[700]
                          : Colors.red[600],
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Table header ──
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 56,
                      child: Text(
                        'Image',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('', style: TextStyle(fontSize: 11)),
                    ), // name (no header)
                    const SizedBox(
                      width: 60,
                      child: Text(
                        'QTY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 60,
                      child: Text(
                        'Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Cart items ──
              if (cart.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = cart.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image + name below
                          SizedBox(
                            width: 56,
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: _buildItemImage(item.imageUrl),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Category as "color" placeholder
                          Expanded(
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // QTY controls
                          SizedBox(
                            width: 60,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _qtyBtn(
                                  icon: Icons.remove,
                                  onTap: () =>
                                      cart.decrementQuantity(item.productId),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                _qtyBtn(
                                  icon: Icons.add,
                                  onTap: () =>
                                      cart.incrementQuantity(item.productId),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Tk ${item.itemTotal.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Delete
                          SizedBox(
                            width: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () =>
                                  cart.removeFromCart(item.productId),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const Divider(height: 1),

              // ── Totals ──
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  children: [
                    _totalRow('Subtotal', 'Tk ${subtotal.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    _totalRow(
                      'Shipping Charge',
                      'Tk ${_deliveryCharge.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _totalRow(
                      'Total',
                      'Tk ${(subtotal + _deliveryCharge).toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _totalRow(
                      'Discount',
                      'Tk ${discount.toStringAsFixed(0)}',
                      valueColor: discount > 0 ? Colors.green[700] : null,
                    ),
                    const Divider(height: 16),
                    _totalRow(
                      'Payable Amount',
                      'Tk ${payable.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, size: 12, color: Colors.black87),
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style.copyWith(
            color: Colors.black54,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: style.copyWith(
            color: valueColor ?? (bold ? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 20,
        ),
      );
    }
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
            size: 20,
          ),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.broken_image_outlined,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payment_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you want to pay',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const Divider(height: 28),

          // Payment options
          _buildPaymentMethodCard(
            method: PaymentMethod.nagad,
            title: 'Nagad',
            assetLogo: 'assets/payments/nagad.png',
            accentColor: const Color(0xFFFF7A00),
          ),
          const SizedBox(height: 10),
          _buildPaymentMethodCard(
            method: PaymentMethod.bkash,
            title: 'bKash',
            assetLogo: 'assets/payments/baksh.png',
            accentColor: const Color(0xFFE2136E),
          ),
          const SizedBox(height: 10),
          // Cash on Delivery — always visible
          _buildCodCard(),

          const SizedBox(height: 16),
          // Order summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      '৳${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (_couponDiscount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Discount',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '-৳${_couponDiscount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      '৳${_deliveryCharge.toStringAsFixed(0)} (${_isInsideDhaka ? 'Inside Dhaka' : 'Outside Dhaka'})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '৳${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    final canProceed = !_isProcessing && _addressValid && _agreedToTerms;
    final isCod = _selectedMethod == PaymentMethod.cashOnDelivery;
    final hasOnlineMethod =
        _config.bkashEnabled ||
        _config.nagadEnabled ||
        _config.rocketEnabled ||
        _config.upayEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // COD button — black like the website
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canProceed
                ? () {
                    setState(
                      () => _selectedMethod = PaymentMethod.cashOnDelivery,
                    );
                    _openInstruction(PaymentMethod.cashOnDelivery);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            icon: _isProcessing && isCod
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text(
              'ক্যাশ অন ডেলিভারিতে অর্ডার করুন',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Confirmation hint text (green, like the website)
        if (_agreedToTerms)
          const Text(
            'উপরের বাটনে ক্লিক করলে আপনার অর্ডারটি সাথে সাথে কনফার্ম হয়ে যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
          ),
        const SizedBox(height: 10),
        // Pay Online button — red like the website
        if (hasOnlineMethod)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canProceed
                  ? () {
                      // Pick the first available online method
                      final method = _config.bkashEnabled
                          ? PaymentMethod.bkash
                          : _config.nagadEnabled
                          ? PaymentMethod.nagad
                          : _config.rocketEnabled
                          ? PaymentMethod.rocket
                          : PaymentMethod.upay;
                      setState(() => _selectedMethod = method);
                      _openInstruction(method);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              icon: _isProcessing && !isCod
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.credit_card_outlined, size: 18),
              label: Text(
                'Pay Online (${[if (_config.bkashEnabled) 'bKash', if (_config.nagadEnabled) 'Nagad', if (_config.rocketEnabled) 'Rocket', if (_config.upayEnabled) 'Upay'].join(', ')}, Internet Banking)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (!_agreedToTerms) ...[
          const SizedBox(height: 8),
          const Text(
            'Please agree to the Terms & Conditions to proceed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.red),
          ),
        ],
        // Amount info box — like the website
        if (hasOnlineMethod) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Amount Required: ${_grandTotal.toStringAsFixed(0)} BDT',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This amount will be charged at the time of online payment.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet that shows available online payment methods (bKash, Nagad)
/// matching the SSLCommerz-style picker UI.
/// Full-screen SSLCommerz-style payment page
class _OnlinePaymentSheet extends StatefulWidget {
  final PaymentConfig config;
  final double grandTotal;
  final void Function(PaymentMethod method) onMethodSelected;

  const _OnlinePaymentSheet({
    required this.config,
    required this.grandTotal,
    required this.onMethodSelected,
  });

  @override
  State<_OnlinePaymentSheet> createState() => _OnlinePaymentSheetState();
}

class _OnlinePaymentSheetState extends State<_OnlinePaymentSheet> {
  int _tabIndex = 1; // 0=Card, 1=Mobile Banking, 2=Net Banking, 3=More
  PaymentMethod? _selected;

  // Mobile banking options — only show enabled ones first, rest as visual tiles
  static const _mobileMethods = [
    {
      'id': 'bkash',
      'label': 'bKash',
      'logo': 'assets/payments/baksh.png',
      'color': 0xFFE2136E,
    },
    {
      'id': 'nagad',
      'label': 'Nagad',
      'logo': 'assets/payments/nagad.png',
      'color': 0xFFFF6300,
    },
    {
      'id': 'rocket',
      'label': 'Rocket',
      'logo': 'assets/payments/rocket.png',
      'color': 0xFF8B1A8B,
    },
    {
      'id': 'upay',
      'label': 'Upay',
      'logo': 'assets/payments/upay.png',
      'color': 0xFF00A651,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.config.bkashEnabled) {
      _selected = PaymentMethod.bkash;
    } else if (widget.config.nagadEnabled) {
      _selected = PaymentMethod.nagad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'SSL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ElectroZoneBD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              'Trx ID: EC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel
        SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildLeftPanel(),
          ),
        ),
        const VerticalDivider(width: 1),
        // Right panel
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildRightPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLeftPanel(),
          const SizedBox(height: 16),
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "You are paying" box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are paying',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳${widget.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Pay with',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.qr_code, size: 18, color: Color(0xFF0066CC)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _leftRow('Payable Amount', '৳${widget.grandTotal.toStringAsFixed(2)}'),
        const Divider(height: 20),
        _leftRow('Convenience Charge', '৳0.00'),
        const Divider(height: 20),
        _leftRow(
          'Total amount',
          '৳${widget.grandTotal.toStringAsFixed(2)}',
          bold: true,
        ),
        const SizedBox(height: 24),
        const Text(
          'Special Offers and Savings',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Automatically Applied with Eligible Payments',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const Divider(height: 20),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 48,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                'No offers available for this transaction',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leftRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome + Login row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LogIn()));
              },
              icon: const Icon(
                Icons.person_outline,
                size: 16,
                color: Color(0xFF0066CC),
              ),
              label: const Text(
                'Login',
                style: TextStyle(color: Color(0xFF0066CC), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tab bar
        Row(
          children: [
            _tab(0, Icons.credit_card_outlined, 'Card'),
            const SizedBox(width: 8),
            _tab(1, Icons.phone_android_outlined, 'Mobile Ban...'),
            const SizedBox(width: 8),
            _tab(2, Icons.account_balance_outlined, 'Net Banking'),
            const SizedBox(width: 8),
            _tab(3, Icons.grid_view_outlined, 'More'),
          ],
        ),
        const SizedBox(height: 16),

        // Tab content
        if (_tabIndex == 1) ...[
          const Text(
            'Pay with Mobile Banking',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildMobileGrid(),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                _tabIndex == 0
                    ? 'Card payment coming soon'
                    : _tabIndex == 2
                    ? 'Net Banking coming soon'
                    : 'More options coming soon',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Pay button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected == null
                ? null
                : () => widget.onMethodSelected(_selected!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Pay ৳${widget.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              const Text(
                'By clicking the "Pay" button you agree to our ',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(AppConstants.termsOfService);
                  if (await canLaunchUrl(uri))
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 11, color: Color(0xFF0066CC)),
                ),
              ),
              const Text(
                ' which is limited to facilitating your payment to ElectroZoneBD.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'SSL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'COMMERZ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Secured by ',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'PCI DSS',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066CC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF0066CC) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.white : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileGrid() {
    final methods = <Map<String, dynamic>>[];
    if (widget.config.bkashEnabled)
      methods.add({
        'id': 'bkash',
        'label': 'bKash',
        'logo': 'assets/payments/baksh.png',
        'method': PaymentMethod.bkash,
      });
    if (widget.config.nagadEnabled)
      methods.add({
        'id': 'nagad',
        'label': 'Nagad',
        'logo': 'assets/payments/nagad.png',
        'method': PaymentMethod.nagad,
      });

    if (methods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No mobile banking methods available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: methods.length,
      itemBuilder: (_, i) {
        final m = methods[i];
        final isSelected = _selected == m['method'];
        return GestureDetector(
          onTap: () => setState(() => _selected = m['method'] as PaymentMethod),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0066CC)
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      m['logo'] as String,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Text(
                        m['label'] as String,
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066CC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentInstructionPage extends StatefulWidget {
  final PaymentMethod method;
  final double amount;
  final void Function(String txnId) onVerify;
  final PaymentConfig config;

  const _PaymentInstructionPage({
    required this.method,
    required this.amount,
    required this.onVerify,
    required this.config,
  });

  @override
  State<_PaymentInstructionPage> createState() =>
      _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<_PaymentInstructionPage> {
  final TextEditingController _txnController = TextEditingController();
  late String _receiverNumber;

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNagad = widget.method == PaymentMethod.nagad;
    final isRocket = widget.method == PaymentMethod.rocket;
    final isUpay = widget.method == PaymentMethod.upay;

    final brandColor = isNagad
        ? const Color(0xFFFF6300)
        : isRocket
        ? const Color(0xFF8B1A8B)
        : isUpay
        ? const Color(0xFF00A651)
        : const Color(0xFFE2136E);

    final methodName = isNagad
        ? 'Nagad'
        : isRocket
        ? 'Rocket'
        : isUpay
        ? 'Upay'
        : 'bKash';

    final logoAsset = isNagad
        ? 'assets/payments/nagad.png'
        : isRocket
        ? 'assets/payments/rocket.png'
        : isUpay
        ? 'assets/payments/upay.png'
        : 'assets/payments/baksh.png';

    _receiverNumber = isNagad
        ? widget.config.nagadNumber
        : isRocket
        ? widget.config.rocketNumber
        : isUpay
        ? widget.config.upayNumber
        : widget.config.bkashNumber;
    final r = AppResponsive.of(context);
    final maxWidth = r.value(
      smallMobile: 360.0,
      mobile: 420.0,
      tablet: 640.0,
      smallDesktop: 760.0,
      desktop: 860.0,
    );
    final pad = EdgeInsets.symmetric(
      horizontal: AppDimensions.padding(context),
      vertical: AppDimensions.padding(context) * 0.8,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/electrozonebd_logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.electric_bolt, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 8),
            const Text('ElectroZoneBD', style: TextStyle(color: Colors.black)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: pad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    logoAsset,
                    height: 46,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.payment, color: brandColor, size: 46),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 31, 16, 31),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bullet('Go to your $methodName Mobile App.'),
                      _bullet('Choose: Send Money'),
                      if (_receiverNumber.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: _boldLine(
                                'Enter the Number: $_receiverNumber',
                              ),
                            ),
                            const SizedBox(width: 6),
                            _copyBtn(
                              () => Clipboard.setData(
                                ClipboardData(text: _receiverNumber),
                              ),
                            ),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Payment number not configured. Please contact support.',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _boldLine(
                              'Enter the Amount: ৳${widget.amount.toStringAsFixed(0)}',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _copyBtn(
                            () => Clipboard.setData(
                              ClipboardData(
                                text: widget.amount.toStringAsFixed(0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      _bullet('Confirm with your $methodName PIN.'),
                      const SizedBox(height: 12),
                      const Text(
                        'Transaction ID',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _txnController,
                        decoration: InputDecoration(
                          hintText: 'Enter Transaction ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ⚠️ Warning about Transaction ID
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          border: Border.all(color: const Color(0xFFFFD966)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '⚠️ Be careful! If your transaction ID doesn\'t match your bank transfer, your order will be cancelled by the shop owner.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        widget.onVerify(_txnController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1769E0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('VERIFY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _copyBtn(VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1769E0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Copy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _boldLine(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}

// ─────────────────────────────────────────────
// Data models — used by My_order.dart, Profile.dart, Orders_provider.dart
// ─────────────────────────────────────────────

double _parsePrice(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

class OrderItem {
  final String name;
  final String color;
  final int qty;
  final double price;
  final String? imagePath;

  OrderItem({
    required this.name,
    required this.color,
    required this.qty,
    required this.price,
    this.imagePath,
  });

  factory OrderItem.fromApiMap(Map<String, dynamic> m) {
    final price = _parsePrice(m['price_at_purchase'] ?? m['price']);
    return OrderItem(
      name: (m['product_name'] ?? m['name'] ?? '').toString(),
      color: (m['color'] ?? '').toString(),
      qty: (m['quantity'] is int)
          ? m['quantity'] as int
          : int.tryParse(m['quantity']?.toString() ?? '1') ?? 1,
      price: price,
      imagePath:
          (m['image_url'] ?? m['product_image'] ?? m['imageUrl'] ?? '')
              .toString()
              .isEmpty
          ? null
          : (m['image_url'] ?? m['product_image'] ?? m['imageUrl']).toString(),
    );
  }
}

class OrderModel {
  final String id;
  final String total;
  final String paymentMethod;
  final String date;
  final String status;
  final bool isDelivered;
  final List<OrderItem> items;
  final String? transactionId;
  final String? deliveryAddress;
  final String? paymentStatus;
  final String? estimatedDelivery;

  OrderModel({
    required this.id,
    required this.total,
    required this.paymentMethod,
    required this.date,
    required this.status,
    this.isDelivered = false,
    required this.items,
    this.transactionId,
    this.deliveryAddress,
    this.paymentStatus,
    this.estimatedDelivery,
  });

  factory OrderModel.fromApiMap(Map<String, dynamic> o) {
    final itemsRaw = o['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => OrderItem.fromApiMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final orderDate = o['order_date'] ?? o['orderDate'] ?? '';
    String dateStr = orderDate.toString();
    if (orderDate != null && orderDate.toString().isNotEmpty) {
      try {
        final d = DateTime.parse(orderDate.toString());
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final h = d.hour;
        dateStr =
            '${d.day} ${months[d.month - 1]} ${d.year}, '
            '${h > 12 ? h - 12 : (h == 0 ? 12 : h)}:'
            '${d.minute.toString().padLeft(2, '0')} '
            '${h >= 12 ? 'PM' : 'AM'}';
      } catch (_) {}
    }

    final status = (o['order_status'] ?? o['status'] ?? 'pending').toString();
    final s = status.toLowerCase();
    final isDelivered = s == 'delivered' || s == 'completed' || s == 'complete';

    final totalAmount = o['total_amount'] ?? o['total'];
    final totalStr = totalAmount != null
        ? '৳${_parsePrice(totalAmount).toStringAsFixed(0)}'
        : '৳0';

    return OrderModel(
      id: (o['order_id'] ?? o['orderId'] ?? '').toString(),
      total: totalStr,
      paymentMethod:
          (o['payment_method'] ?? o['paymentMethod'] ?? 'Cash on Delivery')
              .toString(),
      date: dateStr,
      status: status,
      isDelivered: isDelivered,
      items: items,
      transactionId: (o['transaction_id'] ?? o['transactionId'])?.toString(),
      deliveryAddress: (o['delivery_address'] ?? o['deliveryAddress'])
          ?.toString(),
      paymentStatus: (o['payment_status'] ?? o['paymentStatus'])?.toString(),
      estimatedDelivery: (o['estimated_delivery'] ?? o['estimatedDelivery'])
          ?.toString(),
    );
  }
}
