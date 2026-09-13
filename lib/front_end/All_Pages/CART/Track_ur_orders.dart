import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';

import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';

class TrackOrderFormPage extends StatefulWidget {
  const TrackOrderFormPage({super.key});

  @override
  State<TrackOrderFormPage> createState() => _TrackOrderFormPageState();
}

class _TrackOrderFormPageState extends State<TrackOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _orderIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleTrackOrder() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TrackOrderPage(orderId: _orderIdController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(AppDimensions.padding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(
                          AppDimensions.padding(context) * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1A000000),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFF0F172A),
                          size: AppDimensions.iconSize(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.hp(3)),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.titleFont(context),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        Text(
                          'Home / Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Form Container
            Padding(
              padding: EdgeInsets.all(AppDimensions.padding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To track your order please enter your Order ID in the box below and press the "Track Order" button. This was given to you on your receipt and in the confirmation email you should have received.',
                    style: TextStyle(
                      fontSize: AppDimensions.bodyFont(context),
                      color: const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: r.hp(4)),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID Field
                        Text(
                          'Order ID',
                          style: TextStyle(
                            fontSize: AppDimensions.bodyFont(context),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        TextFormField(
                          controller: _orderIdController,
                          decoration: InputDecoration(
                            hintText: 'Enter Your Order ID',
                            hintStyle: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: AppDimensions.bodyFont(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFF1B7340), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.padding(context),
                              vertical: AppDimensions.padding(context) * 0.875,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          style: TextStyle(
                            fontSize: AppDimensions.bodyFont(context),
                            color: const Color(0xFF0F172A),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Order ID';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: r.hp(3)),
                        // Billing Email Field
                        Text(
                          'Billing Email',
                          style: TextStyle(
                            fontSize: AppDimensions.bodyFont(context),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter Email Address',
                            hintStyle: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: AppDimensions.bodyFont(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: const BorderSide(color: Color(0xFF1B7340), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.padding(context),
                              vertical: AppDimensions.padding(context) * 0.875,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          style: TextStyle(
                            fontSize: AppDimensions.bodyFont(context),
                            color: const Color(0xFF0F172A),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: r.hp(4)),
                        // Track Order Button
                        SizedBox(
                          width: double.infinity,
                          height: AppDimensions.buttonHeight(context),
                          child: ElevatedButton(
                            onPressed: _handleTrackOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B7340),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Track Order',
                              style: TextStyle(
                                fontSize: AppDimensions.bodyFont(context),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: r.hp(6)),
                  // Features Section
                  _buildFeaturesSection(context, r),
                ],
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

Widget _buildFeaturesSection(BuildContext context, AppResponsive r) {
  final isMobile = r.isMobile;
  final items = [
    _buildFeature(
      context,
      icon: Icons.local_shipping_outlined,
      title: 'Free Shipping',
      subtitle: 'Free shipping for orders above ৳5000',
    ),
    _buildFeature(
      context,
      icon: Icons.credit_card,
      title: 'Flexible Payment',
      subtitle: 'Multiple secure payment options',
    ),
    _buildFeature(
      context,
      icon: Icons.support_agent,
      title: '24x7 Support',
      subtitle: 'We support online all days.',
    ),
  ];

  if (isMobile) {
    return Column(
      children: items
          .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(width: double.infinity, child: w),
              ))
          .toList(),
    );
  }

  return Row(
    children: items
        .map((w) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: w,
              ),
            ))
        .toList(),
  );
}

Widget _buildFeature(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF1B7340),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    ),
  );
}

class TrackOrderPage extends StatefulWidget {
  final String orderId;
  const TrackOrderPage({super.key, required this.orderId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  Map<String, dynamic>? order;
  bool loading = true;
  String? error;

  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    final data = await ApiService.getOrderDetail(id);
    return data;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final id =
          int.tryParse(widget.orderId) ??
          int.tryParse(
            RegExp(r'(\d+)$').firstMatch(widget.orderId)?.group(1) ?? '',
          );
      if (id == null) {
        setState(() {
          loading = false;
          error = 'Invalid order ID';
        });
        return;
      }
      final data = await getOrderDetail(id);
      setState(() {
        order = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _statusLabel() {
    final s = (order?['order_status'] ?? '').toString().toLowerCase();
    if (s.isEmpty) return 'pending';
    return s;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _itemsSubtotal() {
    final items = order?['items'];
    if (items is! List) return 0;

    return items.fold<double>(0, (sum, item) {
      if (item is! Map) return sum;
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = _number(item['price_at_purchase'] ?? item['price']);
      return sum + (price * qty);
    });
  }

  double _orderTotal() {
    return _number(order?['total_amount'] ?? order?['total']);
  }

  double _couponDiscount() {
    return _number(order?['coupon_discount']);
  }

  bool _hasSavedDeliveryCharge() {
    return order?.containsKey('delivery_charge') == true &&
        order?['delivery_charge'] != null &&
        _number(order?['delivery_charge']) > 0;
  }

  String _deliveryLabel() {
    if (!_hasSavedDeliveryCharge()) return 'Delivery';

    final zone = (order?['delivery_zone'] ?? '').toString().toLowerCase();
    if (zone.contains('inside')) return 'Delivery (Inside Dhaka)';
    if (zone.contains('outside')) return 'Delivery (Outside Dhaka)';
    return 'Delivery';
  }

  double _subtotal() {
    final savedSubtotal = _number(
      order?['subtotal_amount'] ?? order?['subtotal'],
    );
    if (savedSubtotal > 0) return savedSubtotal;

    final itemsSubtotal = _itemsSubtotal();
    if (itemsSubtotal > 0) return itemsSubtotal;

    final total = _orderTotal();
    final delivery = _number(order?['delivery_charge']);
    final discount = _couponDiscount();
    return (total - delivery + discount).clamp(0, double.infinity).toDouble();
  }

  double _deliveryCharge() {
    final savedCharge = _number(order?['delivery_charge']);
    if (savedCharge > 0) return savedCharge;

    final inferred = _orderTotal() - _subtotal() + _couponDiscount();
    if (inferred > 0) return inferred;

    return 0;
  }

  double _paymentFee() {
    // No extra payment fee ? the order total already includes all charges
    return 0;
  }

  String _formatBDT(double v) {
    return '৳${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return Scaffold(
      appBar: const Header(),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Back Button
            Padding(
              padding: EdgeInsets.all(AppDimensions.padding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeArea(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(
                          AppDimensions.padding(context) * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.borderRadius(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1A000000),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: const Color(0xFF0F172A),
                          size: AppDimensions.iconSize(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: r.hp(3)),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.titleFont(context),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        Text(
                          'Home / Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              Padding(
                padding: const EdgeInsets.all(24),
                child: const CircularProgressIndicator(),
              ),
            if (!loading && error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(error!, style: TextStyle(color: Colors.red[700])),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (!loading && error == null && order != null)
              Padding(
                padding: EdgeInsets.all(AppDimensions.padding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: AppDimensions.titleFont(context) * 0.7,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: r.hp(1)),
                    Text(
                      'Order ID : #${order!['order_id']}',
                      style: TextStyle(
                        fontSize: AppDimensions.smallFont(context),
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: r.hp(3)),
                    Container(
                      padding: EdgeInsets.all(AppDimensions.padding(context)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius(context),
                        ),
                      ),
                      child: _buildTimeline(context),
                    ),
                    SizedBox(height: r.hp(4)),
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: AppDimensions.titleFont(context) * 0.7,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: r.hp(2)),
                    ...List<Widget>.from(
                      ((order!['items'] as List<dynamic>? ?? [])).map((e) {
                        final qty =
                            int.tryParse(e['quantity']?.toString() ?? '1') ?? 1;
                        final priceRaw = (e['price_at_purchase'] ?? e['price']);
                        final unit = priceRaw is num
                            ? priceRaw.toDouble()
                            : (double.tryParse(priceRaw?.toString() ?? '') ??
                                  0.0);
                        final img = (e['image_url'] ?? e['product_image'] ?? '')
                            .toString();
                        final brand = (e['brand_name'] ?? '').toString();
                        final currentPriceRaw = e['current_price'];
                        final currentPrice = currentPriceRaw is num
                            ? currentPriceRaw.toDouble()
                            : (double.tryParse(
                                    currentPriceRaw?.toString() ?? '',
                                  ) ??
                                  0.0);
                        return _buildProductItem(
                          context: context,
                          productName: (e['product_name'] ?? e['name'] ?? '')
                              .toString(),
                          color: (e['color'] ?? '').toString(),
                          quantity: qty,
                          unitPrice: unit,
                          imageUrl: img,
                          brandName: brand,
                          currentPrice: currentPrice,
                        );
                      }),
                    ),
                    SizedBox(height: r.hp(4)),
                    Text(
                      'Charges (BD)',
                      style: TextStyle(
                        fontSize: AppDimensions.titleFont(context) * 0.7,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(AppDimensions.padding(context)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.borderRadius(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          _chargeRow('Subtotal', _formatBDT(_subtotal())),
                          const SizedBox(height: 8),
                          _chargeRow(
                            _deliveryLabel(),
                            _formatBDT(_deliveryCharge()),
                          ),
                          if (_couponDiscount() > 0) ...[
                            const SizedBox(height: 8),
                            _chargeRow(
                              'Discount',
                              '-${_formatBDT(_couponDiscount())}',
                            ),
                          ],
                          const SizedBox(height: 8),
                          _chargeRow('Payment Fee', _formatBDT(_paymentFee())),
                          const Divider(height: 20),
                          _chargeRow(
                            'Total Payable',
                            _formatBDT(_orderTotal() + _paymentFee()),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.hp(4)),
                    _buildFeaturesSection(context, r),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final s = _statusLabel();
    final placed = true;
    final accepted = s != 'pending';
    final inProgress = s == 'processing' || s == 'shipped' || s == 'delivered';
    final onTheWay = s == 'shipped' || s == 'delivered';
    final delivered = s == 'delivered';

    final steps = [
      {
        'icon': Icons.shopping_bag,
        'label': 'Order Placed',
        'isCompleted': placed,
        'date': (order?['order_date'] ?? '').toString().split('T').first,
      },
      {
        'icon': Icons.done_all,
        'label': 'Accepted',
        'isCompleted': accepted,
        'date': '',
      },
      {
        'icon': Icons.local_shipping,
        'label': 'In Progress',
        'isCompleted': inProgress,
        'date': '',
      },
      {
        'icon': Icons.directions_car,
        'label': 'On the Way',
        'isCompleted': onTheWay,
        'date': '',
      },
      {
        'icon': Icons.home,
        'label': 'Delivered',
        'isCompleted': delivered,
        'date': '',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 420),
        child: IntrinsicWidth(
          child: Column(
            children: [
              // Row 1: Circles and Connecting Lines strictly on horizontal center
              Row(
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (steps[i]['isCompleted'] as bool)
                            ? const Color(0xFF1B7340)
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        steps[i]['icon'] as IconData,
                        color: (steps[i]['isCompleted'] as bool)
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 3.5,
                          color: (steps[i + 1]['isCompleted'] as bool)
                              ? const Color(0xFF1B7340)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Labels aligned under circles
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            steps[i]['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: (steps[i]['isCompleted'] as bool)
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: (steps[i]['isCompleted'] as bool)
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if ((steps[i]['date'] as String).isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              steps[i]['date'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (i < steps.length - 1) const Spacer(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chargeRow(String k, String v, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            fontSize: bold ? 14 : 13,
            color: bold ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 15 : 13,
            color: bold ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem({
    required BuildContext context,
    required String productName,
    required String color,
    required int quantity,
    required double unitPrice,
    required String imageUrl,
    String? brandName,
    double? currentPrice,
  }) {
    final lineTotal = unitPrice * quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFF1F5F9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      ImageResolver.resolveUrl(imageUrl),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.orange,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.orange,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (brandName != null && brandName.isNotEmpty)
                      '$brandName •',
                    productName,
                  ].join(' '),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    if (color.isNotEmpty) 'Color: $color',
                    'Qty: $quantity',
                    'Unit: ৳${unitPrice.toStringAsFixed(0)}',
                  ].join('  |  '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '৳${lineTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final r = AppResponsive.of(context);

    return Container(
      padding: EdgeInsets.all(AppDimensions.padding(context) * 0.75),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppDimensions.borderRadius(context),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1B7340),
            size: AppDimensions.iconSize(context),
          ),
          SizedBox(height: r.hp(1)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context),
              fontWeight: FontWeight.w600,
              color: AppColors.grey300,
            ),
          ),
          SizedBox(height: r.hp(0.5)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context) - 2,
              color: AppColors.grey300,
            ),
          ),
        ],
      ),
    );
  }
}






