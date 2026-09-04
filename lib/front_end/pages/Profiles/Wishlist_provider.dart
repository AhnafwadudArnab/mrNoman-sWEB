import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/api_service.dart';
import '../../utils/auth_session.dart';

class WishlistItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final String dateAdded;

  const WishlistItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.dateAdded,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'category': category,
    'dateAdded': dateAdded,
  };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
    productId: json['productId']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    dateAdded:
        json['dateAdded']?.toString() ?? DateTime.now().toIso8601String(),
  );
}

class WishlistProvider extends ChangeNotifier {
  static const String _storageKey = 'electrocity_wishlist_items';
  final Map<String, WishlistItem> _items = {};

  bool _isLoading = false;
  String? _error;

  List<WishlistItem> get items => _items.values.toList(growable: false);
  int get itemCount => _items.length;
  int get wishlistCount => _items.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load local cache first
      await _loadFromLocal();

      // Sync from API if logged in
      final userData = await AuthSession.getUserData();
      if (userData != null && userData.email.isNotEmpty) {
        final token = await ApiService.getToken();
        if (token != null) {
          try {
            final list = await ApiService.getWishlist();
            _items.clear();
            for (final row in list) {
              final r = Map<String, dynamic>.from(row as Map);
              final pid = (r['product_id'] ?? r['productId'])?.toString() ?? '';
              if (pid.isEmpty) continue;
              _items[pid] = WishlistItem(
                productId: pid,
                name: (r['product_name'] ?? r['name'] ?? '').toString(),
                price: (r['price'] as num?)?.toDouble() ?? 0,
                imageUrl: (r['image_url'] ?? r['imageUrl'] ?? '').toString(),
                category: (r['category_name'] ?? r['category'] ?? '')
                    .toString(),
                dateAdded:
                    r['created_at']?.toString() ??
                    DateTime.now().toIso8601String(),
              );
            }
            await _persist();
          } catch (e) {
            if (kDebugMode)
              debugPrint('Wishlist API sync error (using local): $e');
            // Local cache is still valid ? don't surface this as an error
          }
        }
      }
    } catch (e) {
      _error = 'Failed to load wishlist: ${e.toString()}';
      if (kDebugMode) debugPrint('Wishlist init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      _items.clear();
      for (final element in decoded) {
        try {
          final item = WishlistItem.fromJson(
            Map<String, dynamic>.from(element as Map),
          );
          if (item.productId.isNotEmpty) _items[item.productId] = item;
        } catch (e) {
          if (kDebugMode) debugPrint('Wishlist item parse error: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist local load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _items.values.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist persist error: $e');
    }
  }

  bool isInWishlist(String productId) => _items.containsKey(productId);

  Future<void> addToWishlist({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required String category,
  }) async {
    if (productId.isEmpty) return;
    if (isInWishlist(productId)) return;

    final item = WishlistItem(
      productId: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      category: category,
      dateAdded: DateTime.now().toIso8601String(),
    );

    _items[productId] = item;
    notifyListeners();
    await _persist();

    // Sync to API if logged in
    final pid = int.tryParse(productId);
    if (pid != null) {
      final token = await ApiService.getToken();
      if (token != null) {
        try {
          await ApiService.addToWishlist(pid);
        } catch (e) {
          if (kDebugMode) debugPrint('Wishlist API add error: $e');
          // Don't rollback ? local wishlist is still valid
        }
      }
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    if (!_items.containsKey(productId)) return;

    final removed = _items.remove(productId);
    notifyListeners();
    await _persist();

    // Sync to API if logged in
    final pid = int.tryParse(productId);
    if (pid != null) {
      final token = await ApiService.getToken();
      if (token != null) {
        try {
          await ApiService.removeFromWishlist(pid);
        } catch (e) {
          if (kDebugMode) debugPrint('Wishlist API remove error: $e');
          // Restore on API failure
          if (removed != null) {
            _items[productId] = removed;
            notifyListeners();
            await _persist();
          }
        }
      }
    }
  }

  Future<void> toggleWishlist({
    required String productId,
    required String name,
    required double price,
    required String imageUrl,
    required String category,
  }) async {
    if (isInWishlist(productId)) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        category: category,
      );
    }
  }

  Future<void> clearWishlist() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }
}
