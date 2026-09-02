import 'package:flutter/material.dart';

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
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        Text(
                          'Home / Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: Colors.grey.shade600,
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
                      color: Colors.grey.shade700,
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        TextFormField(
                          controller: _orderIdController,
                          decoration: InputDecoration(
                            hintText: 'Enter Your Order ID',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: AppDimensions.bodyFont(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter Email Address',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: AppDimensions.bodyFont(context),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadius(context),
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeature(
                          context,
                          icon: Icons.local_shipping_outlined,
                          title: 'Free Shipping',
                          subtitle: 'Free shipping for order above ৳5000',
                        ),
                      ),
                      SizedBox(width: AppDimensions.padding(context) * 0.75),
                      Expanded(
                        child: _buildFeature(
                          context,
                          icon: Icons.credit_card,
                          title: 'Flexible Payment',
                          subtitle: 'Multiple secure payment options',
                        ),
                      ),
                      SizedBox(width: AppDimensions.padding(context) * 0.75),
                      Expanded(
                        child: _buildFeature(
                          context,
                          icon: Icons.support_agent,
                          title: '24x7 Support',
                          subtitle: 'We support online all days.',
                        ),
                      ),
                    ],
                  ),
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

Widget _buildFeature(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: EdgeInsets.all(AppDimensions.padding(context) * 0.75),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius(context)),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1B7340),
          size: AppDimensions.iconSize(context),
        ),
        SizedBox(height: AppResponsive.of(context).hp(1)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimensions.smallFont(context),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppResponsive.of(context).hp(0.5)),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimensions.smallFont(context) - 2,
            color: Colors.grey.shade600,
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
    // No extra payment fee — the order total already includes all charges
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
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
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
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: r.hp(1)),
                        Text(
                          'Home / Track Your Order',
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: Colors.grey.shade600,
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
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: r.hp(1)),
                    Text(
                      'Order ID : #${order!['order_id']}',
                      style: TextStyle(
                        fontSize: AppDimensions.smallFont(context),
                        color: Colors.grey.shade600,
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
                        color: Colors.black87,
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
                        color: Colors.black87,
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeature(
                            context,
                            icon: Icons.local_shipping_outlined,
                            title: 'Free Shipping',
                            subtitle: 'Free shipping for order above ৳5000',
                          ),
                        ),
                        SizedBox(width: AppDimensions.padding(context) * 0.75),
                        Expanded(
                          child: _buildFeature(
                            context,
                            icon: Icons.credit_card,
                            title: 'Flexible Payment',
                            subtitle: 'Multiple secure payment options',
                          ),
                        ),
                        SizedBox(width: AppDimensions.padding(context) * 0.75),
                        Expanded(
                          child: _buildFeature(
                            context,
                            icon: Icons.support_agent,
                            title: '24x7 Support',
                            subtitle: 'We support online all days.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final r = AppResponsive.of(context);
    final s = _statusLabel();
    final placed = true;
    final accepted = s != 'pending' ? true : false;
    final inProgress = s == 'processing' || s == 'shipped' || s == 'delivered';
    final onTheWay = s == 'shipped' || s == 'delivered';
    final delivered = s == 'delivered';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatusItem(
            context: context,
            icon: Icons.shopping_bag,
            label: 'Order Placed',
            date: (order?['order_date'] ?? '').toString().split('T').first,
            time: '',
            isCompleted: placed,
            isActive: placed,
          ),
          _buildStatusConnector(context, true),
          _buildStatusItem(
            context: context,
            icon: Icons.done_all,
            label: 'Accepted',
            date: '',
            time: '',
            isCompleted: accepted,
            isActive: accepted && !inProgress,
          ),
          _buildStatusConnector(context, false),
          _buildStatusItem(
            context: context,
            icon: Icons.local_shipping,
            label: 'In Progress',
            date: '',
            time: '',
            isCompleted: inProgress,
            isActive: inProgress && !onTheWay,
          ),
          _buildStatusConnector(context, false),
          _buildStatusItem(
            context: context,
            icon: Icons.directions_car,
            label: 'On the Way',
            date: '',
            time: '',
            isCompleted: onTheWay,
            isActive: onTheWay && !delivered,
          ),
          _buildStatusConnector(context, false),
          _buildStatusItem(
            context: context,
            icon: Icons.home,
            label: 'Delivered',
            date: '',
            time: '',
            isCompleted: delivered,
            isActive: delivered,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String date,
    required String time,
    required bool isCompleted,
    required bool isActive,
  }) {
    final r = AppResponsive.of(context);

    return SizedBox(
      width: r.wp(15),
      child: Column(
        children: [
          Container(
            width: AppDimensions.iconSize(context) * 2,
            height: AppDimensions.iconSize(context) * 2,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF1B7340)
                  : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey.shade500,
              size: AppDimensions.iconSize(context),
            ),
          ),
          SizedBox(height: r.hp(1)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context),
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.black87 : Colors.grey.shade500,
            ),
          ),
          SizedBox(height: r.hp(0.5)),
          Text(
            date,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context) - 2,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context) - 2,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          v,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusConnector(BuildContext context, bool isCompleted) {
    final r = AppResponsive.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: r.hp(2.5)),
      child: Container(
        width: r.wp(3),
        height: AppDimensions.borderRadius(context) * 0.5,
        color: isCompleted ? const Color(0xFF1B7340) : Colors.grey.shade300,
      ),
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
    final r = AppResponsive.of(context);
    final lineTotal = unitPrice * quantity;

    return Container(
      padding: EdgeInsets.all(AppDimensions.padding(context) * 0.75),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppDimensions.borderRadius(context),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadius(context),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    ImageResolver.resolveUrl(imageUrl),
                    width: AppDimensions.imageSize(context) * 0.4,
                    height: AppDimensions.imageSize(context) * 0.4,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: AppDimensions.imageSize(context) * 0.4,
                      height: AppDimensions.imageSize(context) * 0.4,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  )
                : Container(
                    width: AppDimensions.imageSize(context) * 0.4,
                    height: AppDimensions.imageSize(context) * 0.4,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image, color: Colors.grey.shade400),
                  ),
          ),
          SizedBox(width: AppDimensions.padding(context) * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (brandName != null && brandName.isNotEmpty)
                      '$brandName ·',
                    productName,
                  ].join(' '),
                  style: TextStyle(
                    fontSize: AppDimensions.bodyFont(context),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: r.hp(0.5)),
                Text(
                  [
                    if (color.isNotEmpty) 'Color: $color',
                    'Qty: $quantity',
                    'Unit: ৳${unitPrice.toStringAsFixed(0)}',
                  ].join('  |  '),
                  style: TextStyle(
                    fontSize: AppDimensions.smallFont(context),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '৳${lineTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: AppDimensions.bodyFont(context),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
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
              color: Colors.black87,
            ),
          ),
          SizedBox(height: r.hp(0.5)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.smallFont(context) - 2,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

