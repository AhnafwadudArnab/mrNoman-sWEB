import 'dart:async';
import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';

import '../../All_Pages/CART/Orders.dart';
import '../../All_Pages/CART/Track_ur_orders.dart';
import '../../All_Pages/Registrations/login.dart' show LogIn;
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  bool _isLoggedIn = true;
  String? _error;
  String _selectedFilter = 'All';
  Timer? _pollingTimer;
  DateTime? _lastRefreshed;

  static const int _itemsPerPage = 10;
  int _currentPage = 1;
  static const Color _brandOrange = Color(0xFFFFA500);

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-sync order status every 10 seconds while user is viewing their orders
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _isLoggedIn) {
        _loadOrders(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        if (mounted)
          setState(() {
            _isLoggedIn = false;
            _loading = false;
            _orders = [];
          });
        return;
      }
      _isLoggedIn = true;
      final list = await ApiService.getOrders() as List<dynamic>;
      final parsed = list
          .map(
            (o) => OrderModel.fromApiMap(Map<String, dynamic>.from(o as Map)),
          )
          .toList();
      final seen = <String>{};
      final unique = parsed.where((o) => seen.add(o.id)).toList();
      if (mounted) {
        setState(() {
          _orders = unique;
          _loading = false;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
          _error = e
              .toString()
              .replaceFirst('ApiException(', '')
              .replaceFirst(')', '');
        });
      }
    }
  }

  List<OrderModel> get _filtered {
    if (_selectedFilter == 'Delivered')
      return _orders.where((o) => o.isDelivered).toList();
    if (_selectedFilter == 'Processing')
      return _orders.where((o) => !o.isDelivered).toList();
    return _orders;
  }

  List<OrderModel> get _paginatedOrders {
    final filtered = _filtered;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filtered.isEmpty)
      ? 1
      : ((_filtered.length + _itemsPerPage - 1) ~/ _itemsPerPage);

  void _setFilter(String filter) => setState(() {
    _selectedFilter = filter;
    _currentPage = 1;
  });

  @override
  Widget build(BuildContext context) {
    if (_loading && _orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _brandOrange),
              const SizedBox(height: 16),
              const Text(
                'Loading orders...',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: _brandOrange),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: Colors.black26,
              ),
              const SizedBox(height: 20),
              const Text(
                'No orders yet',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'When you place orders, they will show up here.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleOrders = _paginatedOrders;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(),
          const SizedBox(height: 16),
          _buildFilterCardsGrid(),
          const SizedBox(height: 16),
          if (_loading)
            const LinearProgressIndicator(color: _brandOrange)
          else
            const SizedBox.shrink(),
          const SizedBox(height: 12),
          if (!_isLoggedIn)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Color(0xFFFFA500),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Sign In to View Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please log in to your account to view your live orders and delivery tracking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LogIn()),
                        ).then((_) => _loadOrders());
                      },
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text('Log In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Colors.black38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No $_selectedFilter orders',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleOrders.length,
                  itemBuilder: (context, i) =>
                      _buildOrderCard(context, visibleOrders[i]),
                ),
                const SizedBox(height: 20),
                if (_totalPages > 1) _buildPaginationControls(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final timeStr = _lastRefreshed != null
        ? '${_lastRefreshed!.hour.toString().padLeft(2, '0')}:${_lastRefreshed!.minute.toString().padLeft(2, '0')}:${_lastRefreshed!.second.toString().padLeft(2, '0')}'
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandOrange, Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _brandOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80), // Live green
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live Sync',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr != null
                      ? 'Track and manage your orders • Synced at $timeStr'
                      : 'Track and manage your orders',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _loadOrders(silent: false),
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
            tooltip: 'Refresh Orders Now',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCardsGrid() {
    final filters = [
      {
        'label': 'All',
        'icon': Icons.shopping_bag_outlined,
        'count': _orders.length,
        'color': _brandOrange,
      },
      {
        'label': 'Processing',
        'icon': Icons.hourglass_top,
        'count': _orders.where((o) => !o.isDelivered).length,
        'color': const Color(0xFFFF9800),
      },
      {
        'label': 'Delivered',
        'icon': Icons.check_circle,
        'count': _orders.where((o) => o.isDelivered).length,
        'color': const Color(0xFF4CAF50),
      },
    ];

    return Row(
      children: filters.map((filter) {
        final isActive = _selectedFilter == filter['label'];
        final count = filter['count'] as int;
        final label = filter['label'] as String;
        final icon = filter['icon'] as IconData;
        final cardColor = filter['color'] as Color;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _setFilter(label),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? cardColor : Colors.grey.shade300,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: cardColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: cardColor, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.black87 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(isActive ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildPaginationControls() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0D000000),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      color: _currentPage > 1 ? _brandOrange : Colors.black26,
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Prev',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentPage > 1 ? _brandOrange : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: _brandOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _brandOrange.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _brandOrange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentPage < _totalPages
                            ? _brandOrange
                            : Colors.black26,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: _currentPage < _totalPages
                          ? _brandOrange
                          : Colors.black26,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey300, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: AppColors.grey300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.date,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _statusChip(order.status, order.isDelivered),
                const SizedBox(width: 12),
                Text(
                  order.total,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Payment', order.paymentMethod),
                if (order.transactionId != null &&
                    order.transactionId!.isNotEmpty)
                  _detailRow('Transaction ID', order.transactionId!),
                if (order.paymentStatus != null &&
                    order.paymentStatus!.isNotEmpty)
                  _detailRow('Payment Status', order.paymentStatus!),
                if (order.estimatedDelivery != null &&
                    order.estimatedDelivery!.isNotEmpty)
                  _detailRow('Est. Delivery', order.estimatedDelivery!),
                if (order.deliveryAddress != null &&
                    order.deliveryAddress!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Delivery Address',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.deliveryAddress!,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey300),
          ...order.items.map((item) => _buildProductRow(context, item)),
          const Divider(height: 1, color: AppColors.grey300),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrackOrderFormPage(),
                    ),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: Text(
                    order.isDelivered ? 'View Details' : 'Track Order',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _brandOrange,
                    side: const BorderSide(color: _brandOrange, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, bool delivered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: delivered ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: delivered ? Colors.green : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: delivered ? Colors.green.shade800 : Colors.orange.shade800,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 70,
              height: 70,
              color: const Color(0xFFF1F5F9),
              child: item.imagePath != null && item.imagePath!.isNotEmpty
                  ? ImageResolver.image(
                      imageUrl: item.imagePath!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
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
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Qty: ${item.qty} × ৳${item.price.toStringAsFixed(0)} = ৳${(item.qty * item.price).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.color.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Color: ${item.color}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

