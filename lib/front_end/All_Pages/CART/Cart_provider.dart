import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/api_service.dart';
import '../../utils/auth_session.dart';
import 'cart_models.dart';

class CartException implements Exception {
  final String message;
  const CartException(this.message);
  @override
  String toString() => 'CartException: $message';
}

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'electrocity_cart_by_user';
  static const String _guestIdKey = 'electrocity_guest_id';

  /// userId (email) or guest_xxx -> productId -> CartItem
  final Map<String, Map<String, CartItem>> _carts = {};

  /// productId -> server cart_id (for API delete/update when logged in)
  final Map<String, int> _serverCartIds = {};
  String _currentUserId = '';

  bool _isLoading = false;
  String? _error;

  String get currentUserId => _currentUserId;
  bool get hasCurrentUser => _currentUserId.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CartItem> get items =>
      _carts[_currentUserId]?.values.toList(growable: false) ?? [];

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          _carts.clear();
          for (final e in decoded.entries) {
            final list = (e.value as List<dynamic>)
                .map((x) => CartItem.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList();
            final map = <String, CartItem>{};
            for (final item in list) {
              map[item.productId] = item;
            }
            _carts[e.key] = map;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Cart local parse error: $e');
          // Don't rethrow ? local cache corruption shouldn't block init
        }
      }

      final userData = await AuthSession.getUserData();
      if (userData != null && userData.email.isNotEmpty) {
        _currentUserId = userData.email;
        final token = await ApiService.getToken();
        if (token != null) {
          try {
            _serverCartIds.clear();
            final res = await ApiService.getCart();
            final list = (res['items'] as List<dynamic>?) ?? [];
            final map = <String, CartItem>{};
            for (final row in list) {
              final r = Map<String, dynamic>.from(row as Map);
              final pid = (r['product_id'] ?? r['productId'])?.toString() ?? '';
              if (pid.isEmpty) continue;
              final cartId = r['cart_id'] as int?;
              if (cartId != null) _serverCartIds[pid] = cartId;
              map[pid] = CartItem(
                productId: pid,
                name: (r['product_name'] ?? r['productName'] ?? '').toString(),
                price: _parseDouble(r['price']),
                imageUrl: (r['image_url'] ?? r['imageUrl'] ?? '').toString(),
                quantity: _parseInt(r['quantity']) ?? 1,
                category: (r['category_name'] ?? r['category'] ?? '').toString(),
              );
            }
            _carts[_currentUserId] = map;
          } catch (e) {
            if (kDebugMode) debugPrint('Cart API sync error (using local): $e');
            // Fall through ? local cart is still usable
          }
        }
      } else {
        String guestId = (await SharedPreferences.getInstance()).getString(_guestIdKey) ?? '';
        if (guestId.isEmpty) {
          guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
          await (await SharedPreferences.getInstance()).setString(_guestIdKey, guestId);
        }
        _currentUserId = guestId;
      }

      _carts.putIfAbsent(_currentUserId, () => {});
    } catch (e) {
      _error = 'Failed to initialize cart: ${e.toString()}';
      if (kDebugMode) debugPrint('Cart init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, List<Map<String, dynamic>>>{};
      for (final e in _carts.entries) {
        data[e.key] = e.value.values.map((x) => x.toJson()).toList();
      }
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('Cart persist error: $e');
    }
  }

  /// Switch current user (e.g. after login). Merges guest cart into user cart if merging from guest.
  Future<void> setCurrentUserId(String userId, {bool mergeFromGuest = false}) async {
    if (mergeFromGuest &&
        _currentUserId.startsWith('guest_') &&
        _currentUserId != userId) {
      final guestCart = _carts[_currentUserId];
      if (guestCart != null && guestCart.isNotEmpty) {
        final userCart = _carts.putIfAbsent(userId, () => {});
        for (final item in guestCart.values) {
          if (userCart.containsKey(item.productId)) {
            final cur = userCart[item.productId]!;
            userCart[item.productId] = cur.copyWith(quantity: cur.quantity + item.quantity);
          } else {
            userCart[item.productId] = item;
          }
        }
        _carts[_currentUserId] = {};
      }
    }
    _currentUserId = userId;
    _carts.putIfAbsent(_currentUserId, () => {});
    notifyListeners();
    await _persist();
  }

  /// Switch to guest (e.g. after logout).
  Future<void> switchToGuest() async {
    final prefs = await SharedPreferences.getInstance();
    String guestId = prefs.getString(_guestIdKey) ?? '';
    if (guestId.isEmpty) {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_guestIdKey, guestId);
    }
    _currentUserId = guestId;
    _serverCartIds.clear();
    _carts.putIfAbsent(_currentUserId, () => {});
    notifyListeners();
    await _persist();
  }

  Future<void> addToCart({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required String category,
    int quantity = 1,
  }) async {
    if (productId.isEmpty) throw const CartException('Invalid product ID');
    if (quantity <= 0) throw const CartException('Quantity must be greater than 0');
    if (_currentUserId.isEmpty) throw const CartException('No active user session');

    final cart = _carts[_currentUserId] ??= {};
    // Snapshot for rollback
    final previous = cart[productId];

    if (cart.containsKey(productId)) {
      final current = cart[productId]!;
      cart[productId] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      cart[productId] = CartItem(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        category: category,
        quantity: quantity,
      );
    }
    notifyListeners();
    await _persist();

    final pid = int.tryParse(productId);
    if (pid != null && !_currentUserId.startsWith('guest_')) {
      try {
        await ApiService.addToCart(pid, quantity: quantity);
      } catch (e) {
        // Rollback local state on API failure
        if (previous != null) {
          cart[productId] = previous;
        } else {
          cart.remove(productId);
        }
        notifyListeners();
        await _persist();
        throw CartException('Failed to add item to cart: ${e.toString()}');
      }
    }
  }

  Future<void> removeFromCart(String productId) async {
    final cart = _carts[_currentUserId];
    if (cart == null || !cart.containsKey(productId)) return;

    // Snapshot for rollback
    final removedItem = cart[productId];
    final removedCartId = _serverCartIds[productId];

    cart.remove(productId);
    _serverCartIds.remove(productId);
    notifyListeners();
    await _persist();

    if (!_currentUserId.startsWith('guest_') && removedCartId != null) {
      try {
        await ApiService.removeCartItem(removedCartId);
      } catch (e) {
        // Rollback
        if (removedItem != null) cart[productId] = removedItem;
        if (removedCartId != null) _serverCartIds[productId] = removedCartId;
        notifyListeners();
        await _persist();
        throw CartException('Failed to remove item: ${e.toString()}');
      }
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1 && quantity != 0) {
      throw const CartException('Quantity must be at least 1');
    }
    final cart = _carts[_currentUserId];
    if (cart == null || !cart.containsKey(productId)) return;

    if (quantity == 0) {
      await removeFromCart(productId);
      return;
    }

    final previous = cart[productId]!;
    cart[productId] = previous.copyWith(quantity: quantity);
    notifyListeners();
    await _persist();

    if (!_currentUserId.startsWith('guest_')) {
      final cartId = _serverCartIds[productId];
      if (cartId != null) {
        try {
          await ApiService.updateCartItem(cartId, quantity);
        } catch (e) {
          // Rollback
          cart[productId] = previous;
          notifyListeners();
          await _persist();
          throw CartException('Failed to update quantity: ${e.toString()}');
        }
      }
    }
  }

  Future<void> incrementQuantity(String productId) async {
    final cart = _carts[_currentUserId];
    if (cart == null || !cart.containsKey(productId)) return;
    final current = cart[productId]!;
    await updateQuantity(productId, current.quantity + 1);
  }

  Future<void> decrementQuantity(String productId) async {
    final cart = _carts[_currentUserId];
    if (cart == null || !cart.containsKey(productId)) return;
    final current = cart[productId]!;
    // Minimum quantity is 1 ? use removeFromCart explicitly to remove an item
    if (current.quantity <= 1) return;
    await updateQuantity(productId, current.quantity - 1);
  }

  Future<void> clearCart() async {
    _carts[_currentUserId]?.clear();
    _serverCartIds.clear();
    notifyListeners();
    await _persist();

    // Best-effort server sync ? don't throw if it fails
    if (!_currentUserId.startsWith('guest_')) {
      try {
        await ApiService.clearCart();
      } catch (e) {
        if (kDebugMode) debugPrint('Cart server clear failed (local cleared): $e');
        // Local cart is already cleared ? don't rollback or throw
      }
    }
  }

  double getCartTotal() => items.fold(0.0, (sum, item) => sum + item.itemTotal);

  int getItemCount() => items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool isInCart(String productId) =>
      _carts[_currentUserId]?.containsKey(productId) ?? false;

  String formatBDT(double value) => 'Tk ${value.toStringAsFixed(2)}';

  static double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// For admin: all non-empty carts by user id.
  Map<String, List<CartItem>> getAllCartsForAdmin() {
    final map = <String, List<CartItem>>{};
    for (final e in _carts.entries) {
      final list = e.value.values.toList();
      if (list.isNotEmpty) map[e.key] = list;
    }
    return map;
  }
}









