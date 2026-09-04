import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

/// Custom Exception for Orders Provider
class OrdersProviderException implements Exception {
  final String message;
  OrdersProviderException(this.message);

  @override
  String toString() => 'OrdersProviderException: $message';
}

/// Single placed order (customer checkout).
class PlacedOrder {
  final String orderId;
  final String transactionId;
  final String paymentMethod;
  final double total;
  final double subtotal;
  final double deliveryCharge;
  final double couponDiscount;
  final String? deliveryZone;
  final String? couponCode;
  final String createdAt; // formatted e.g. "22 Feb 2025, 02:30 PM"
  final int createdAtMillis; // for filtering (e.g. weekly)
  final String status;
  final String? estimatedDelivery;
  final List<Map<String, dynamic>> items;

  // User details from users table
  final String? customerName;
  final String? customerLastName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGender;
  final String? customerRole;

  // Shipping/delivery address from order
  final Map<String, dynamic>? shippingAddress;

  PlacedOrder({
    required this.orderId,
    required this.transactionId,
    required this.paymentMethod,
    required this.total,
    double? subtotal,
    this.deliveryCharge = 0,
    this.couponDiscount = 0,
    this.deliveryZone,
    this.couponCode,
    required this.createdAt,
    int? createdAtMillis,
    required this.status,
    this.estimatedDelivery,
    this.items = const [],
    this.customerName,
    this.customerLastName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    this.customerGender,
    this.customerRole,
    this.shippingAddress,
  }) : subtotal = subtotal ?? total,
       createdAtMillis =
           createdAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'transactionId': transactionId,
    'paymentMethod': paymentMethod,
    'total': total,
    'subtotal': subtotal,
    'deliveryCharge': deliveryCharge,
    'couponDiscount': couponDiscount,
    'deliveryZone': deliveryZone,
    'couponCode': couponCode,
    'createdAt': createdAt,
    'createdAtMillis': createdAtMillis,
    'status': status,
    'estimatedDelivery': estimatedDelivery,
    'items': items,
    'customerName': customerName,
    'customerLastName': customerLastName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'customerAddress': customerAddress,
    'customerGender': customerGender,
    'customerRole': customerRole,
    'shippingAddress': shippingAddress,
  };

  factory PlacedOrder.fromJson(Map<String, dynamic> json) {
    final total = _readDouble(json, ['total', 'total_amount']);
    return PlacedOrder(
      orderId: json['orderId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      total: total,
      subtotal: _readDouble(json, ['subtotal', 'subtotal_amount'], total),
      deliveryCharge: _readDouble(json, ['deliveryCharge', 'delivery_charge']),
      couponDiscount: _readDouble(json, ['couponDiscount', 'coupon_discount']),
      deliveryZone:
          json['deliveryZone']?.toString() ?? json['delivery_zone']?.toString(),
      couponCode:
          json['couponCode']?.toString() ?? json['coupon_code']?.toString(),
      createdAt: json['createdAt']?.toString() ?? _formatCurrentDate(),
      createdAtMillis: json['createdAtMillis'] is int
          ? json['createdAtMillis'] as int
          : int.tryParse(json['createdAtMillis']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
      status: json['status']?.toString() ?? 'New Order',
      estimatedDelivery: json['estimatedDelivery']?.toString(),
      items:
          (json['items'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      customerName: json['customerName']?.toString(),
      customerLastName: json['customerLastName']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
      customerGender: json['customerGender']?.toString(),
      customerRole: json['customerRole']?.toString(),
      shippingAddress: json['shippingAddress'] is Map
          ? Map<String, dynamic>.from(json['shippingAddress'] as Map)
          : null,
    );
  }

  /// For admin table row: id, store, method, slot, created, status
  Map<String, String> toAdminRow() {
    // Format order ID as order code (EC-YYYYMMDD-ID)
    String orderCode = orderId;

    // Try to format as EC-YYYYMMDD-ID if orderId is numeric
    if (int.tryParse(orderId) != null) {
      try {
        final date = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
        final dateStr =
            '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
        orderCode = 'EC-$dateStr-$orderId';
      } catch (e) {
        // If date parsing fails, use orderId as is
        orderCode = orderId;
      }
    }

    return {
      'id': orderId, // Database ID
      'orderCode': orderCode, // Formatted order code
      'store': 'ElectroZoneBD',
      'method': paymentMethod,
      'slot': estimatedDelivery ?? '?',
      'created': createdAt,
      'status': status,
      'transactionId': transactionId,
      'total': total.toStringAsFixed(2),
      'subtotal': subtotal.toStringAsFixed(2),
      'deliveryCharge': deliveryCharge.toStringAsFixed(2),
      'couponDiscount': couponDiscount.toStringAsFixed(2),
      'deliveryZone': deliveryZone ?? '',
      'couponCode': couponCode ?? '',
      'createdAtMillis': createdAtMillis.toString(),
      'customerName': customerName ?? '?',
      'customerLastName': customerLastName ?? '',
      'customerEmail': customerEmail ?? '?',
      'customerPhone': customerPhone ?? '?',
      'customerAddress': customerAddress ?? '?',
      'customerGender': customerGender ?? '?',
    };
  }

  double get itemsSubtotal {
    return items.fold<double>(0, (sum, item) {
      final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      final price = _readDouble(item, ['price_at_purchase', 'price']);
      return sum + (price * qty);
    });
  }

  double get effectiveSubtotal {
    if (subtotal > 0 && subtotal != total) return subtotal;
    if (itemsSubtotal > 0) return itemsSubtotal;
    final inferred = total - deliveryCharge + couponDiscount;
    return inferred > 0 ? inferred : total;
  }

  double get effectiveDeliveryCharge {
    if (deliveryCharge > 0) return deliveryCharge;
    final inferred = total - effectiveSubtotal + couponDiscount;
    return inferred > 0 ? inferred : 0;
  }

  String get deliveryLabel {
    final zone = (deliveryZone ?? '').toLowerCase();
    if (effectiveDeliveryCharge <= 0) return 'Delivery';
    if (zone.contains('inside')) return 'Delivery (Inside Dhaka)';
    if (zone.contains('outside')) return 'Delivery (Outside Dhaka)';
    return 'Delivery';
  }

  static double _readDouble(
    Map<String, dynamic> json,
    List<String> keys, [
    double fallback = 0,
  ]) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  /// Get status color for UI
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new order':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  /// Get status icon
  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'new order':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  static String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonth(now.month)} ${now.year}, ${_formatHour(now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String _getMonth(int month) {
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
    return months[month - 1];
  }

  static String _formatHour(int hour) {
    if (hour == 0 || hour == 12) return '12';
    return (hour > 12 ? hour - 12 : hour).toString();
  }
}

class OrdersProvider extends ChangeNotifier {
  static const String _storageKeyPrefix = 'electrocity_placed_orders';
  final List<PlacedOrder> _orders = [];
  String _currentUserId = '';

  // Loading and error states
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<PlacedOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// User-specific storage key ? prevents cross-user data leaks
  String get _storageKey {
    if (_currentUserId.isEmpty) return _storageKeyPrefix;
    final safeId = _currentUserId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${_storageKeyPrefix}_$safeId';
  }

  /// Sorted by createdAt descending (newest first).
  List<PlacedOrder> get ordersNewestFirst {
    final list = List<PlacedOrder>.from(_orders);
    list.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return list;
  }

  /// Get orders by status
  List<PlacedOrder> getOrdersByStatus(String status) {
    return _orders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Get orders statistics
  Map<String, dynamic> getOrderStats() {
    final totalOrders = _orders.length;
    final totalRevenue = _orders.fold(0.0, (sum, order) => sum + order.total);

    final pending = _orders
        .where(
          (o) =>
              o.status.toLowerCase() == 'pending' ||
              o.status.toLowerCase() == 'new order',
        )
        .length;

    final processing = _orders
        .where((o) => o.status.toLowerCase() == 'processing')
        .length;
    final shipped = _orders
        .where((o) => o.status.toLowerCase() == 'shipped')
        .length;
    final delivered = _orders
        .where((o) => o.status.toLowerCase() == 'delivered')
        .length;
    final cancelled = _orders
        .where((o) => o.status.toLowerCase() == 'cancelled')
        .length;

    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'pending': pending,
      'processing': processing,
      'shipped': shipped,
      'delivered': delivered,
      'cancelled': cancelled,
    };
  }

  /// Get today's orders
  List<PlacedOrder> getTodaysOrders() {
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;

    return _orders
        .where(
          (o) =>
              o.createdAtMillis >= startOfDay && o.createdAtMillis <= endOfDay,
        )
        .toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  /// Initialize provider ? loads local cache first, then syncs from API
  Future<void> init({bool admin = false, String? userId}) async {
    // If user changed, reset everything to prevent cross-user data leaks
    final newUserId = userId ?? '';
    if (newUserId != _currentUserId) {
      _orders.clear();
      _isInitialized = false;
      _currentUserId = newUserId;
    }

    if (_isInitialized) return;
    _setLoading(true);
    try {
      // Load local cache immediately so UI has data while API loads
      await _loadFromLocal();
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty) {
        await refreshFromApi(admin: admin);
      }
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize orders: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Call this on logout to clear orders from memory
  void clearForLogout() {
    _orders.clear();
    _isInitialized = false;
    _currentUserId = '';
    notifyListeners();
  }

  /// Load orders from local storage
  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) {
        // No local data and no API data - orders will be empty
        return;
      }

      final List<dynamic> decoded = jsonDecode(raw);
      _orders.clear();

      for (final e in decoded) {
        try {
          _orders.add(PlacedOrder.fromJson(Map<String, dynamic>.from(e)));
        } catch (e) {
          if (kDebugMode) debugPrint('Error parsing local order: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Local load error: $e');
    }
  }

  /// Format date helper
  String _formatDate(DateTime date) {
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
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $ampm';
  }

  /// Refresh from API - always fetch fresh from DB
  Future<void> refreshFromApi({bool admin = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await ApiService.getOrders(admin: admin);
      if (list is! List)
        throw OrdersProviderException('Invalid API response format');
      _orders.clear();
      int skipped = 0;
      for (final o in list) {
        try {
          _orders.add(_parseApiOrder(o));
        } catch (e) {
          skipped++;
          if (kDebugMode) debugPrint('Skipping malformed order: $e\nData: $o');
          continue;
        }
      }
      if (kDebugMode && skipped > 0) {
        debugPrint(
          'OrdersProvider: loaded ${_orders.length}, skipped $skipped malformed orders',
        );
      }
    } catch (e) {
      _error = 'Failed to load orders: ${e.toString()}';
      if (kDebugMode) debugPrint('OrdersProvider.refreshFromApi error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse order from API response
  PlacedOrder _parseApiOrder(dynamic orderData) {
    if (orderData == null) throw OrdersProviderException('Order data is null');
    final row = Map<String, dynamic>.from(orderData as Map);

    // Get order ID
    final orderId = _getStringValue(row, ['order_id', 'orderId']);
    if (orderId.isEmpty) throw OrdersProviderException('Order ID missing');

    // Get created date
    final createdAt = _getValue(row, ['order_date', 'createdAt']);
    final createdStr = _formatApiDate(createdAt);
    final createdMillis = _parseDateMillis(createdAt);

    // Get items - never throw, just return empty list
    List<Map<String, dynamic>> items = [];
    try {
      items = _parseItems(row['items']);
    } catch (_) {}

    return PlacedOrder(
      orderId: orderId,
      transactionId: _getStringValue(row, ['transaction_id', 'transactionId']),
      paymentMethod: _getStringValue(row, [
        'payment_method',
        'paymentMethod',
      ], 'Cash'),
      total: _getNumericValue(row, ['total_amount', 'total']),
      subtotal: _getNumericValue(row, ['subtotal_amount', 'subtotal']),
      deliveryCharge: _getNumericValue(row, [
        'delivery_charge',
        'deliveryCharge',
      ]),
      couponDiscount: _getNumericValue(row, [
        'coupon_discount',
        'couponDiscount',
      ]),
      deliveryZone: _getStringValue(row, [
        'delivery_zone',
        'deliveryZone',
      ], null),
      couponCode: _getStringValue(row, ['coupon_code', 'couponCode'], null),
      createdAt: createdStr,
      createdAtMillis: createdMillis,
      status: _getStringValue(row, ['order_status', 'status'], 'pending'),
      estimatedDelivery: _getStringValue(row, [
        'estimated_delivery',
        'estimatedDelivery',
      ], null),
      items: items,
      // User details from users table (or guest order fields)
      customerName: _getStringValue(row, [
        'display_name',
        'customer_name',
        'full_name',
        'customerName',
      ], null),
      customerLastName: _getStringValue(row, [
        'last_name',
        'customerLastName',
      ], null),
      customerEmail: _getStringValue(row, ['email', 'customerEmail'], null),
      customerPhone: _getStringValue(row, [
        'display_phone',
        'customer_phone',
        'phone_number',
        'customerPhone',
      ], null),
      customerAddress: _getStringValue(row, [
        'user_address',
        'address',
        'customerAddress',
      ], null),
      customerGender: _getStringValue(row, ['gender', 'customerGender'], null),
      customerRole: _getStringValue(row, ['role', 'customerRole'], null),
      // Shipping address from order (delivery_address field)
      shippingAddress: _parseShippingAddress(row['delivery_address']),
    );
  }

  /// Parse shipping address
  Map<String, dynamic>? _parseShippingAddress(dynamic address) {
    if (address == null) return null;

    try {
      if (address is Map) {
        return Map<String, dynamic>.from(address);
      } else if (address is String && address.isNotEmpty) {
        // If it's a JSON string, try to parse it
        try {
          final decoded = jsonDecode(address);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          // If not JSON, treat as plain text address
          return {'address': address};
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Shipping address parse error: $e');
    }

    return null;
  }

  /// Helper: Get string value from multiple possible keys
  String _getStringValue(
    Map map,
    List<String> keys, [
    String? defaultValue = '',
  ]) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key].toString();
      }
    }
    return defaultValue ?? '';
  }

  /// Helper: Get numeric value
  double _getNumericValue(Map map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        final v = map[key];
        if (v is num) return v.toDouble();
        if (v is String) {
          final p = double.tryParse(v);
          if (p != null) return p;
        }
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Helper: Get any value
  dynamic _getValue(Map map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  /// Parse items from JSON
  List<Map<String, dynamic>> _parseItems(dynamic items) {
    if (items == null) return [];

    try {
      if (items is List) {
        return items.map((e) {
          if (e is Map) {
            return Map<String, dynamic>.from(e);
          }
          return {'item': e.toString()};
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Items parse error: $e');
    }

    return [];
  }

  /// Format API date
  String _formatApiDate(dynamic dateInput) {
    if (dateInput == null) return _formatDate(DateTime.now());

    try {
      DateTime date;

      if (dateInput is DateTime) {
        date = dateInput;
      } else if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else {
        return dateInput.toString();
      }

      return _formatDate(date);
    } catch (e) {
      return dateInput.toString();
    }
  }

  /// Parse date to milliseconds
  int _parseDateMillis(dynamic dateInput) {
    try {
      if (dateInput == null) return DateTime.now().millisecondsSinceEpoch;

      if (dateInput is DateTime) {
        return dateInput.millisecondsSinceEpoch;
      } else if (dateInput is String) {
        return DateTime.parse(dateInput).millisecondsSinceEpoch;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Date parse error: $e');
    }

    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Persist orders to local storage
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _orders.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('Persist error: $e');
    }
  }

  /// Add new order
  Future<void> addOrder(PlacedOrder order) async {
    try {
      _orders.insert(0, order);
      notifyListeners();
      await _persist();
    } catch (e) {
      throw OrdersProviderException('Failed to add order: $e');
    }
  }

  /// Add order from checkout ? validates required fields
  Future<void> addOrderFromCheckout({
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    String? customerName,
    String? customerPhone,
    Map<String, dynamic>? shippingAddress,
  }) async {
    if (paymentMethod.trim().isEmpty) {
      throw OrdersProviderException('Payment method is required');
    }
    if (total <= 0) {
      throw OrdersProviderException('Order total must be greater than zero');
    }
    if (items.isEmpty) {
      throw OrdersProviderException('Order must contain at least one item');
    }

    final now = DateTime.now();
    final order = PlacedOrder(
      orderId: 'ORD${now.millisecondsSinceEpoch}',
      transactionId: 'TXN${now.millisecondsSinceEpoch}',
      paymentMethod: paymentMethod,
      total: total,
      subtotal: total,
      createdAt: _formatDate(now),
      createdAtMillis: now.millisecondsSinceEpoch,
      status: 'pending',
      estimatedDelivery: _calculateEstimatedDelivery(),
      items: items,
      customerName: customerName,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
    );

    await addOrder(order);
  }

  /// Calculate estimated delivery
  String _calculateEstimatedDelivery() {
    final now = DateTime.now();
    final deliveryDate = now.add(Duration(days: 5));
    return '${deliveryDate.day} ${_getMonth(deliveryDate.month)} ${deliveryDate.year}';
  }

  String _getMonth(int month) {
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
    return months[month - 1];
  }

  /// Update order status ? syncs to API first, then updates local state
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Sync to backend FIRST ? if it fails, local state stays unchanged
    final id = int.tryParse(orderId);
    if (id != null) {
      try {
        await ApiService.updateOrderStatus(id, newStatus);
      } catch (e) {
        throw OrdersProviderException(
          'Failed to update order status on server: ${e.toString()}',
        );
      }
    }

    // Update local state if order exists in list
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index >= 0) {
      final old = _orders[index];
      _orders[index] = PlacedOrder(
        orderId: old.orderId,
        transactionId: old.transactionId,
        paymentMethod: old.paymentMethod,
        total: old.total,
        subtotal: old.subtotal,
        deliveryCharge: old.deliveryCharge,
        couponDiscount: old.couponDiscount,
        deliveryZone: old.deliveryZone,
        couponCode: old.couponCode,
        createdAt: old.createdAt,
        createdAtMillis: old.createdAtMillis,
        status: newStatus,
        estimatedDelivery: old.estimatedDelivery,
        items: old.items,
        customerName: old.customerName,
        customerLastName: old.customerLastName,
        customerEmail: old.customerEmail,
        customerPhone: old.customerPhone,
        customerAddress: old.customerAddress,
        customerGender: old.customerGender,
        customerRole: old.customerRole,
        shippingAddress: old.shippingAddress,
      );
    }

    notifyListeners();
    await _persist();
  }

  /// Delete order ? syncs to API first, then removes locally
  Future<void> deleteOrder(String orderId) async {
    final id = int.tryParse(orderId);
    if (id != null) {
      try {
        await ApiService.delete('/orders?id=$id');
      } catch (e) {
        throw OrdersProviderException(
          'Failed to delete order on server: ${e.toString()}',
        );
      }
    }

    // Remove from local list if present (may not be if list was refreshed)
    _orders.removeWhere((o) => o.orderId == orderId);
    notifyListeners();
    await _persist();
  }

  /// Search orders
  List<PlacedOrder> searchOrders(String query) {
    if (query.isEmpty) return ordersNewestFirst;

    final lowerQuery = query.toLowerCase();
    return _orders.where((order) {
      return order.orderId.toLowerCase().contains(lowerQuery) ||
          order.transactionId.toLowerCase().contains(lowerQuery) ||
          (order.customerName?.toLowerCase().contains(lowerQuery) ?? false) ||
          order.status.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get order by ID
  PlacedOrder? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((o) => o.orderId == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all orders (for testing)
  Future<void> clearAllOrders() async {
    _orders.clear();
    notifyListeners();
    await _persist();
  }
}
