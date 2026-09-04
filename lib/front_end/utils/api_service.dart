import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:electrocitybd1/config/app_config.dart';

import 'constants.dart';

String _apiBase() => ApiService.overrideBaseUrl ?? AppConfig.apiBaseUrl;

/// Convert endpoint to .php file (e.g., /products ? /products.php)
/// Used for PHP dev server compatibility
String _toPHP(String endpoint) {
  // Split path and query
  final qIdx = endpoint.indexOf('?');
  if (qIdx == -1) {
    // No query, simple case
    if (endpoint.endsWith('.php')) return endpoint;
    return endpoint.endsWith('/') ? '${endpoint}index.php' : '$endpoint.php';
  }
  // Has query string
  final path = endpoint.substring(0, qIdx);
  final query = endpoint.substring(qIdx);
  if (path.endsWith('.php')) return endpoint;
  return '${path.endsWith('/') ? '${path}index.php' : '$path.php'}$query';
}

class ApiService {
  static const String _tokenKey = 'electrocity_jwt_token';
  static String? _cachedToken;
  static String? overrideBaseUrl;

  // --- In-Memory Cache ---
  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<dynamic>> _pending = {};
  static const Duration _cacheTtl = Duration(
    minutes: 5,
  ); // reduced from 30min for fresher data

  static dynamic _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.time) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  static void _setCache(String key, dynamic data) {
    _cache[key] = _CacheEntry(data, DateTime.now());
  }

  static Future<T> _dedupe<T>(String key, Future<T> Function() loader) async {
    final existing = _pending[key];
    if (existing != null) return await existing as T;

    final future = loader();
    _pending[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_pending[key], future)) {
        _pending.remove(key);
      }
    }
  }

  /// Invalidate cache for a specific key or all keys matching a prefix
  static void invalidateCache([String? prefix]) {
    if (prefix == null) {
      _cache.clear();
      _pending.clear();
    } else {
      _cache.removeWhere((k, _) => k.startsWith(prefix));
      _pending.removeWhere((k, _) => k.startsWith(prefix));
    }
  }

  static void setBaseUrl(String url) {
    overrideBaseUrl = url;
    if (kDebugMode) {
      debugPrint('API Base URL set to: $url');
    }
  }

  /// Get the upload endpoint URL
  static String getUploadUrl() {
    final base = overrideBaseUrl ?? AppConstants.baseUrl;
    if (base.endsWith('/api')) {
      return base.replaceAll('/api', '/api/upload');
    }
    return '$base/upload';
  }

  static String get baseUrl {
    return 'https://electrozonebd.com'; // Always use production
  }

  static const Duration _requestTimeout = Duration(
    seconds: 15,
  ); // 15s for slow hosting

  static Future<String?> _reprobeBase() async {
    final candidates = kIsWeb
        ? <String>[
            if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty)
              overrideBaseUrl!,
            AppConfig.apiBaseUrl,
            'http://127.0.0.1:8080/api',
          ]
        : <String>[
            if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty)
              overrideBaseUrl!,
            // Remove localhost from mobile candidates for faster cPanel connection
            AppConfig.apiBaseUrl,
          ];

    for (final base in candidates) {
      try {
        final res = await http
            .get(Uri.parse('$base/health.php'))
            .timeout(const Duration(seconds: 5)); // Increased from 3s to 5s
        if (res.statusCode >= 200 && res.statusCode < 400) {
          if (kDebugMode) debugPrint('Backend found at: $base');
          return base;
        }
      } catch (_) {
        continue;
      }
    }
    if (kDebugMode)
      debugPrint('No backend found, using default: ${AppConfig.apiBaseUrl}');
    return AppConfig.apiBaseUrl;
  }

  // --- Token Management ---

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    // Fallback: check AuthSession's token key (same key, but ensures cross-save compatibility)
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      _cachedToken = prefs.getString('electrocity_jwt_token');
    }
    return _cachedToken?.isNotEmpty == true ? _cachedToken : null;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- Generic HTTP Methods ---

  static dynamic _tryJsonDecode(String text) {
    // Trim whitespace and check for empty response
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Empty response from server', 0);
    }

    // Validate that response starts with valid JSON characters
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      // Include actual response content for debugging (limit to 200 chars)
      final preview = trimmed.length > 200
          ? '${trimmed.substring(0, 200)}...'
          : trimmed;
      throw ApiException(
        'Invalid response format (expected JSON): $preview',
        0,
      );
    }

    try {
      return jsonDecode(trimmed);
    } catch (e) {
      // Try to extract JSON from response that may have extra content
      final a = trimmed.indexOf('{');
      final b = trimmed.lastIndexOf('}');
      if (a >= 0 && b >= a) {
        final slice = trimmed.substring(a, b + 1);
        try {
          return jsonDecode(slice);
        } catch (_) {}
      }
      final c = trimmed.indexOf('[');
      final d = trimmed.lastIndexOf(']');
      if (c >= 0 && d >= c) {
        final slice = trimmed.substring(c, d + 1);
        try {
          return jsonDecode(slice);
        } catch (_) {}
      }

      // Include actual response content for debugging (limit to 200 chars)
      final preview = trimmed.length > 200
          ? '${trimmed.substring(0, 200)}...'
          : trimmed;
      throw ApiException('Failed to parse JSON response: $preview', 0);
    }
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    final body = _tryJsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      await clearToken();
    }
    if (body is Map) {
      final err = body['error'] ?? body['message'];
      throw ApiException(err ?? 'Request failed', res.statusCode);
    }
    throw ApiException('Request failed', res.statusCode);
  }

  static Future<T> _withReprobeBase<T>(
    Future<T> Function(String base) runner,
  ) async {
    Future<T> _try(String base) async {
      try {
        return await runner(base);
      } on ApiException catch (e) {
        if (e.statusCode == 401 || e.statusCode == 403) {
          final refreshed = await _refreshOnBase(base);
          if (refreshed) {
            return await runner(base);
          }
        }
        rethrow;
      }
    }

    try {
      final currentBase = _apiBase();
      return await _try(currentBase);
    } catch (e) {
      // Only reprobe on connection errors, not API errors
      if (e is ApiException && e.statusCode > 0) rethrow;
      if (kDebugMode) debugPrint('API call failed, reprobing backend: $e');
      final base = await _reprobeBase();
      setBaseUrl(base!);
      return await _try(base);
    }
  }

  static Future<dynamic> get(
    String endpoint, {
    bool withAuth = true,
    bool useCache = false,
  }) async {
    // Convert to .php for PHP dev server compatibility
    final phpEndpoint = _toPHP(endpoint);
    // Ensure no 301 redirect: if endpoint has query params but no trailing slash before '?', add it
    final normalizedEndpoint = _ensureTrailingSlash(phpEndpoint);
    if (useCache) {
      final cached = _getCached(normalizedEndpoint);
      if (cached != null) return cached;
    }

    Future<dynamic> fetch() => _withReprobeBase((base) async {
      final res = await http
          .get(
            Uri.parse('$base$normalizedEndpoint'),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_requestTimeout);
      final body = _tryJsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw ApiException(
        body is Map ? (body['error'] ?? 'Request failed') : 'Request failed',
        res.statusCode,
      );
    });

    final result = useCache
        ? await _dedupe(normalizedEndpoint, fetch)
        : await fetch();
    if (useCache) _setCache(normalizedEndpoint, result);
    return result;
  }

  /// Adds trailing slash before query string to avoid Apache 301 redirects
  /// Only applies to production (Apache). Local dev server (PHP built-in) doesn't need this.
  static String _ensureTrailingSlash(String endpoint) {
    // Don't modify for local dev server - PHP built-in server handles it fine
    if (_apiBase().contains('localhost:8000')) {
      return endpoint;
    }

    // For production Apache servers, add trailing slash before query
    final qIdx = endpoint.indexOf('?');
    if (qIdx == -1) return endpoint; // no query string, leave as-is
    final path = endpoint.substring(0, qIdx);
    final query = endpoint.substring(qIdx);
    // Only add trailing slash if path doesn't already have one
    if (path.endsWith('/')) return endpoint;
    return '$path/$query';
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool withAuth = true,
  }) async {
    final phpEndpoint = _toPHP(endpoint);
    return _withReprobeBase((base) async {
      final res = await http
          .post(
            Uri.parse('$base$phpEndpoint'),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);
      return _handleResponse(res);
    });
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final phpEndpoint = _toPHP(endpoint);
    return _withReprobeBase((base) async {
      final res = await http
          .put(
            Uri.parse('$base$phpEndpoint'),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);
      return _handleResponse(res);
    });
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final phpEndpoint = _toPHP(endpoint);
    return _withReprobeBase((base) async {
      final res = await http
          .delete(Uri.parse('$base$phpEndpoint'), headers: await _headers())
          .timeout(_requestTimeout);
      return _handleResponse(res);
    });
  }

  static Future<bool> _refreshOnBase(String base) async {
    try {
      final res = await http
          .get(Uri.parse('$base/auth/refresh'), headers: await _headers())
          .timeout(_requestTimeout);
      final body = await _handleResponse(res);
      final token = body['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
        return true;
      }
    } catch (_) {}
    // Do NOT clear the token here - the refresh endpoint may not exist,
    // but the original token could still be valid for other requests.
    return false;
  }

  // --- Auth API ---

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = '',
    String gender = 'Male',
  }) async {
    try {
      final result = await post('/auth/register', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'gender': gender,
      }, withAuth: false);
      if (result['token'] != null) await saveToken(result['token']);
      return result;
    } on ApiException catch (e) {
      // Return error message for UI display
      return {'error': e.message, 'statusCode': e.statusCode};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await post('/auth/login', {
      'email': email,
      'password': password,
    }, withAuth: false);
    if (result['token'] != null) await saveToken(result['token']);
    return result;
  }

  static Future<Map<String, dynamic>> adminLogin({
    required String username,
    required String password,
  }) async {
    final result = await post('/auth/admin-login', {
      'username': username,
      'password': password,
    }, withAuth: false);
    if (result['token'] != null) await saveToken(result['token']);
    return result;
  }

  static Future<Map<String, dynamic>> getProfile({
    bool useCache = false,
  }) async {
    return await get('/auth/me', useCache: useCache) as Map<String, dynamic>;
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await put('/auth/me', data);
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // --- Products API ---

  /// [section] = best-sellers | trending | deals | flash-sale | tech-part for homepage sections
  static Future<dynamic> getProducts({
    int? categoryId,
    String? category,
    String? search,
    String? sort,
    String? section,
    int limit = 50,
    int offset = 0,
    bool useCache = false,
    bool fresh = false,
  }) async {
    // Build query string
    String query = '?limit=$limit&offset=$offset';
    if (categoryId != null) query += '&category_id=$categoryId';
    if (category != null && category.isNotEmpty) {
      query += '&category=${Uri.encodeQueryComponent(category)}';
    }
    if (search != null && search.isNotEmpty) {
      query += '&search=${Uri.encodeQueryComponent(search)}';
    }
    if (sort != null) query += '&sort=${Uri.encodeQueryComponent(sort)}';
    if (section != null && section.isNotEmpty) {
      query += '&action=${Uri.encodeQueryComponent(section)}';
    }
    if (fresh) query += '&_t=${DateTime.now().millisecondsSinceEpoch}';

    final endpoint = _toPHP('/products$query');

    // Check cache first
    if (useCache) {
      final cached = _getCached(endpoint);
      if (cached != null) return cached;
    }

    Future<dynamic> fetch() => _withReprobeBase((base) async {
      final res = await http
          .get(
            Uri.parse('$base$endpoint'),
            headers: await _headers(withAuth: false),
          )
          .timeout(_requestTimeout);
      final body = _tryJsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw ApiException(
        body is Map
            ? (body['error'] ?? body['message'] ?? 'Request failed')
            : 'Request failed',
        res.statusCode,
      );
    });

    // Use _withReprobeBase directly to avoid _ensureTrailingSlash
    // (trailing slash before query params can cause Apache to lose GET parameters)
    final result = useCache ? await _dedupe(endpoint, fetch) : await fetch();

    if (useCache) _setCache(endpoint, result);
    return result;
  }

  static Future<void> updateProductSections(
    int productId,
    Map<String, bool> sections,
  ) async {
    await put('/product_sections?id=$productId', sections);
    invalidateCache('/products'); // sections changed, invalidate product caches
  }

  static Future<Map<String, dynamic>> getProduct(int id) async {
    return await get('/products/$id', withAuth: false) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> data,
  ) async {
    return await post('/products', data);
  }

  /// Create product with optional image file (multipart). Pass imageBytes+fileName when image is picked.
  static Future<Map<String, dynamic>> createProductWithImage({
    required String product_name,
    required String description,
    required double price,
    int stock_quantity = 0,
    int? category_id,
    int? brand_id,
    String? image_url,
    List<int>? imageBytes,
    String? imageFileName,
    Map<String, dynamic>? specs,
  }) async {
    Future<Map<String, dynamic>> _send(String base) async {
      final uri = Uri.parse('$base/products');
      final request = http.MultipartRequest('POST', uri);
      final token = await getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.fields['product_name'] = product_name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stock_quantity.toString();
      if (category_id != null)
        request.fields['category_id'] = category_id.toString();
      if (brand_id != null) request.fields['brand_id'] = brand_id.toString();
      if (image_url != null && image_url.isNotEmpty)
        request.fields['image_url'] = image_url;

      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          imageFileName != null &&
          imageFileName.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: imageFileName,
          ),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      // Trim and validate response body before parsing
      final body = res.body.trim();
      if (body.isEmpty) {
        throw ApiException('Empty response from server', res.statusCode);
      }

      // Check if response starts with valid JSON
      if (!body.startsWith('{') && !body.startsWith('[')) {
        final preview = body.length > 200
            ? '${body.substring(0, 200)}...'
            : body;
        throw ApiException(
          'Invalid response format (expected JSON): $preview',
          res.statusCode,
        );
      }

      final decoded = _tryJsonDecode(body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      }
      throw ApiException(
        decoded is Map
            ? (decoded['error'] ?? 'Request failed')
            : 'Request failed',
        res.statusCode,
      );
    }

    try {
      final result = await _send(_apiBase());
      invalidateCache('/products');
      return result;
    } catch (_) {
      final base = await _reprobeBase();
      if (base != null) {
        setBaseUrl(base);
        final result = await _send(base);
        invalidateCache('/products');
        return result;
      }
      rethrow;
    }
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    await put('/products?id=$id', data);
    // Clear all related caches so sections reflect the update
    invalidateCache('/products');
    invalidateCache('/deals');
    invalidateCache('/best_sellers');
    invalidateCache('/trending');
    invalidateCache('/tech_part');
  }

  static Future<void> deleteProduct(int id) async {
    await delete('/products?id=$id');
    invalidateCache('/products');
    invalidateCache('/deals');
    invalidateCache('/best_sellers');
    invalidateCache('/trending');
    invalidateCache('/tech_part');
  }

  // --- Cart API ---

  static Future<Map<String, dynamic>> getCart() async {
    return await get('/cart') as Map<String, dynamic>;
  }

  static Future<void> addToCart(int productId, {int quantity = 1}) async {
    await post('/cart', {'product_id': productId, 'quantity': quantity});
  }

  static Future<void> updateCartItem(int cartId, int quantity) async {
    await put('/cart/$cartId', {'quantity': quantity});
  }

  static Future<void> removeCartItem(int cartId) async {
    await delete('/cart/$cartId');
  }

  static Future<void> clearCart() async {
    await delete('/cart');
  }

  static Future<List<dynamic>> getAdminCarts() async {
    return await get('/cart/admin/all') as List<dynamic>;
  }

  // --- Orders API ---

  static Future<List<dynamic>> getOrders({bool admin = false}) async {
    final endpoint = admin ? '/orders.php?admin=true' : '/orders.php';
    final token = await getToken();
    final withAuth = token != null && token.isNotEmpty;

    // Use _withReprobeBase directly to skip _ensureTrailingSlash
    // (trailing slash on /orders/ causes empty response on some servers)
    final result = await _withReprobeBase((base) async {
      final res = await http
          .get(
            Uri.parse('$base$endpoint'),
            headers: await _headers(withAuth: withAuth),
          )
          .timeout(_requestTimeout);

      // Handle auth errors explicitly before trying to parse body
      if (res.statusCode == 401) {
        throw ApiException('Session expired. Please log in again.', 401);
      }
      if (res.statusCode == 403) {
        throw ApiException('Access denied. Admin privileges required.', 403);
      }

      final body = _tryJsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw ApiException(
        body is Map
            ? (body['error'] ?? body['message'] ?? 'Request failed')
            : 'Request failed',
        res.statusCode,
      );
    });

    if (result is List) return result as List<dynamic>;
    if (result is Map && result.containsKey('orders'))
      return result['orders'] as List<dynamic>;
    if (result is Map && result.containsKey('data')) {
      final d = result['data'];
      if (d is List) return d as List<dynamic>;
    }
    // If backend returned an error map, throw it so UI can show the message
    if (result is Map) {
      final err = result['error'] ?? result['message'];
      if (err != null) throw ApiException(err.toString(), 500);
    }
    return [];
  }

  static Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> data,
  ) async {
    return _withReprobeBase((base) async {
      final res = await http
          .post(
            Uri.parse('$base/orders.php'),
            headers: await _headers(withAuth: true),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(res);
    });
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    await put('/orders?id=$orderId', {'status': status});
  }

  static Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    return _withReprobeBase((base) async {
      final res = await http
          .get(
            Uri.parse('$base/orders.php?id=$orderId'),
            headers: await _headers(withAuth: true),
          )
          .timeout(_requestTimeout);
      return _handleResponse(res);
    });
  }

  // --- Wishlist API ---

  static Future<List<dynamic>> getWishlist() async {
    return await get('/wishlist') as List<dynamic>;
  }

  static Future<void> addToWishlist(int productId) async {
    await post('/wishlist', {'product_id': productId});
  }

  static Future<void> removeFromWishlist(int productId) async {
    await delete('/wishlist?product_id=$productId');
  }

  // --- Categories API ---

  static Future<List<dynamic>> getCategories() async {
    final res = await get('/categories', withAuth: false);
    return _asList(res);
  }

  // --- Discounts API ---

  static Future<List<dynamic>> getDiscounts() async {
    return await get('/discounts', withAuth: false) as List<dynamic>;
  }

  static Future<void> createDiscount(Map<String, dynamic> data) async {
    await post('/discounts', data);
  }

  static Future<void> updateDiscount(int id, Map<String, dynamic> data) async {
    await put('/discounts/$id', data);
  }

  static Future<void> deleteDiscount(int id) async {
    await delete('/discounts/$id');
  }

  // --- Ratings API ---
  static Future<Map<String, dynamic>?> getProductRating(int productId) async {
    final res = await get('/ratings?product_id=$productId', withAuth: false);
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  static Future<void> setProductRating({
    required int productId,
    required double ratingAvg,
    required int reviewCount,
  }) async {
    await post('/ratings', {
      'product_id': productId,
      'rating_avg': ratingAvg,
      'review_count': reviewCount,
    });
  }

  // --- Coupon API ---
  static Future<Map<String, dynamic>?> getActiveCoupon() async {
    final res = await get('/coupons', withAuth: false) as Map<String, dynamic>;
    final c = res['active'];
    if (c is Map<String, dynamic>) return c;
    return null;
  }

  static Future<Map<String, dynamic>> setActiveCoupon({
    required String code,
    required double percent,
    String scope = 'cart',
  }) async {
    return await post('/coupons', {
      'code': code,
      'percent': percent,
      'scope': scope,
      'active': true,
    });
  }

  /// Safely extract a List from a response that may be a List or a Map with a list inside.
  static List<dynamic> _asList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      for (final key in [
        'collections',
        'products',
        'data',
        'items',
        'results',
        'Flash_Sales',
        'promotions',
        'offers',
      ]) {
        if (res[key] is List) return res[key] as List<dynamic>;
        final nested = res[key];
        if (nested is Map) {
          final nestedList = _asList(nested);
          if (nestedList.isNotEmpty) return nestedList;
        }
      }
    }
    return [];
  }

  // --- Deals of the Day API ---

  static Future<List<dynamic>> getDeals({
    int limit = 24,
    bool useCache = true,
    bool includeExpired = false,
  }) async {
    // Use _withReprobeBase directly to avoid _ensureTrailingSlash
    // turning /deals?limit=24 into /deals/?limit=24 (loses query params on Apache)
    Future<List<dynamic>> _fetch(String endpoint) async {
      final cached = useCache ? _getCached(endpoint) : null;
      if (cached != null) return _asList(cached);

      Future<dynamic> fetch() => _withReprobeBase((base) async {
        final res = await http
            .get(
              Uri.parse('$base$endpoint'),
              headers: await _headers(withAuth: false),
            )
            .timeout(_requestTimeout);
        final body = _tryJsonDecode(res.body);
        if (res.statusCode >= 200 && res.statusCode < 300) return body;
        throw ApiException(
          body is Map
              ? (body['error'] ?? body['message'] ?? 'Request failed')
              : 'Request failed',
          res.statusCode,
        );
      });
      final result = useCache ? await _dedupe(endpoint, fetch) : await fetch();
      if (useCache) _setCache(endpoint, result);
      return _asList(result);
    }

    try {
      final list = await _fetch(
        '/deals?limit=$limit${includeExpired ? '&include_expired=1' : ''}',
      );
      if (list.isNotEmpty) return list;
    } catch (_) {}

    try {
      return await _fetch('/products?action=deals&limit=$limit');
    } catch (_) {
      return [];
    }
  }

  static Future<void> createDeal(Map<String, dynamic> data) async {
    await post('/deals', data);
    invalidateCache('/deals');
  }

  static Future<void> updateDeal(int dealId, Map<String, dynamic> data) async {
    await put('/deals/$dealId', {...data, 'deal_id': dealId});
    invalidateCache('/deals');
    invalidateCache('/products');
  }

  static Future<void> deleteDeal(int dealId) async {
    await delete('/deals/$dealId');
    invalidateCache('/deals');
    invalidateCache('/products');
  }

  // --- Flash_Sales API ---

  static Future<List<dynamic>> getFlashSales() async {
    final res = await get('/Flash_Sales', withAuth: false);
    return _asList(res);
  }

  static Future<void> createFlashSale(Map<String, dynamic> data) async {
    await post('/Flash_Sales', data);
    invalidateCache('/products'); // Flash_Sale products cached under /products
    invalidateCache('/Flash_Sales');
  }

  static Future<void> updateFlashSale(int id, Map<String, dynamic> data) async {
    await put('/Flash_Sales/$id', data);
    invalidateCache('/products');
    invalidateCache('/Flash_Sales');
  }

  static Future<void> deleteFlashSale(int id) async {
    await delete('/Flash_Sales/$id');
    invalidateCache('/products');
    invalidateCache('/Flash_Sales');
  }

  // --- Promotions API ---

  static Future<List<dynamic>> getPromotions() async {
    final res = await get('/promotions', withAuth: false);
    return _asList(res);
  }

  static Future<void> createPromotion(Map<String, dynamic> data) async {
    await post('/promotions', data);
  }

  static Future<void> updatePromotion(int id, Map<String, dynamic> data) async {
    await put('/promotions?id=$id', data);
    invalidateCache('/promotions');
  }

  static Future<void> deletePromotion(int id) async {
    await delete('/promotions?id=$id');
    invalidateCache('/promotions');
  }

  // --- Admin Dashboard API ---

  static Future<Map<String, dynamic>> getDashboardStats({
    bool useCache = true,
    int days = 8,
  }) async {
    return await get('/admin/dashboard?days=$days', useCache: useCache)
        as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getCustomers() async {
    return await get('/admin/customers') as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getReports({
    String? from,
    String? to,
  }) async {
    String query = '';
    if (from != null && to != null) query = '?from=$from&to=$to';
    return await get('/admin/reports$query') as Map<String, dynamic>;
  }

  // --- Section Filters (Admin) ---

  static Future<Map<String, dynamic>> getSectionFilters() async {
    return await get('/admin/section-filters') as Map<String, dynamic>;
  }

  static Future<void> updateSectionFilter(
    String section, {
    String? sort,
    int? limit,
    double? minPrice,
    double? maxPrice,
  }) async {
    final payload = <String, dynamic>{};
    if (sort != null) payload['sort'] = sort;
    if (limit != null) payload['limit'] = limit;
    if (minPrice != null) payload['min_price'] = minPrice;
    if (maxPrice != null) payload['max_price'] = maxPrice;
    await put('/admin/section-filters/$section', payload);
  }

  // --- Brands API ---

  static Future<List<dynamic>> getBrands() async {
    final res = await get('/brands', withAuth: false, useCache: true);
    return _asList(res);
  }

  static Future<Map<String, dynamic>> getBrand(int id) async {
    return await get('/brands?id=$id', withAuth: false) as Map<String, dynamic>;
  }

  static Future<void> createBrand(Map<String, dynamic> data) async {
    await post('/brands', data);
    invalidateCache('/brands');
  }

  static Future<void> updateBrand(int id, Map<String, dynamic> data) async {
    await put('/brands?id=$id', data);
    invalidateCache('/brands');
  }

  static Future<void> deleteBrand(int id) async {
    await delete('/brands?id=$id');
    invalidateCache('/brands');
  }

  // --- Collections API ---

  static Future<List<dynamic>> getCollections() async {
    final res = await get('/collections', withAuth: false, useCache: true);
    return _asList(res);
  }

  static Future<Map<String, dynamic>> getCollection(int id) async {
    return await get('/collections?id=$id', withAuth: false)
        as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getCollectionProducts(int collectionId) async {
    final res = await get(
      '/collection-products?collection_id=$collectionId',
      withAuth: false,
      useCache: true,
    );
    return _asList(res);
  }

  static Future<void> createCollection(Map<String, dynamic> data) async {
    await post('/collections', data);
  }

  static Future<void> updateCollection(
    int id,
    Map<String, dynamic> data,
  ) async {
    await put('/collections?id=$id', data);
  }

  static Future<void> deleteCollection(int id) async {
    await delete('/collections?id=$id');
  }

  // --- Best Sellers API ---

  static Future<List<dynamic>> getBestSellers({int limit = 10}) async {
    final res = await get(
      '/best_sellers?limit=$limit',
      withAuth: false,
      useCache: true,
    );
    return _asList(res);
  }

  static Future<void> addBestSeller(Map<String, dynamic> data) async {
    await post('/best_sellers', data);
    invalidateCache('/best_sellers');
    invalidateCache('/products');
  }

  static Future<void> updateBestSeller(
    int productId,
    Map<String, dynamic> data,
  ) async {
    await put('/best_sellers?product_id=$productId', data);
    invalidateCache('/best_sellers');
    invalidateCache('/products');
  }

  static Future<void> removeBestSeller(int productId) async {
    await delete('/best_sellers?product_id=$productId');
    invalidateCache('/best_sellers');
    invalidateCache('/products');
  }

  // --- Trending Products API ---

  static Future<List<dynamic>> getTrendingProducts({int limit = 10}) async {
    final res = await get(
      '/trending?limit=$limit',
      withAuth: false,
      useCache: true,
    );
    return _asList(res);
  }

  static Future<void> addTrendingProduct(Map<String, dynamic> data) async {
    await post('/trending', data);
    invalidateCache('/trending');
    invalidateCache('/products');
  }

  static Future<void> updateTrendingProduct(
    int productId,
    Map<String, dynamic> data,
  ) async {
    await put('/trending?product_id=$productId', data);
    invalidateCache('/trending');
    invalidateCache('/products');
  }

  static Future<void> removeTrendingProduct(int productId) async {
    await delete('/trending?product_id=$productId');
    invalidateCache('/trending');
    invalidateCache('/products');
  }

  // --- Tech Part API ---

  static Future<List<dynamic>> getTechPartProducts({
    int limit = 40,
    bool useCache = true,
  }) async {
    try {
      final primary = await getProducts(
        section: 'tech-part',
        limit: limit,
        useCache: useCache,
      );
      final list = _asList(primary);
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback below
    }

    try {
      final fallback = await get(
        '/tech_part',
        withAuth: false,
        useCache: useCache,
      );
      return _asList(fallback);
    } catch (_) {
      return [];
    }
  }

  static Future<void> prefetchHomeProducts() async {
    Future<void> warm(Future<dynamic> future) {
      return future.then<void>((_) {}).catchError((_) {});
    }

    await Future.wait([
      warm(getProducts(section: 'flash-sale', limit: 20, useCache: true)),
      warm(getProducts(section: 'best-sellers', limit: 10, useCache: true)),
      warm(getProducts(section: 'trending', limit: 12, useCache: true)),
      warm(getTechPartProducts(limit: 40, useCache: true)),
      warm(getDeals(limit: 24, useCache: true)),
      warm(getCollections()),
      warm(getBrands()),
    ]);
  }

  static Future<void> addTechPartProduct(Map<String, dynamic> data) async {
    await post('/tech_part', data);
    invalidateCache('/tech_part');
    invalidateCache('/products');
  }

  // --- Reviews API ---

  static Future<Map<String, dynamic>> getProductReviews(int productId) async {
    return await get('/reviews?product_id=$productId', withAuth: false)
        as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAllReviews() async {
    return await get('/reviews', withAuth: false) as List<dynamic>;
  }

  static Future<void> createReview(Map<String, dynamic> data) async {
    await post('/reviews', data);
  }

  static Future<void> updateReview(int id, Map<String, dynamic> data) async {
    await put('/reviews?id=$id', data);
  }

  static Future<void> deleteReview(int id) async {
    await delete('/reviews?id=$id');
  }

  // --- Customer Support API ---

  static Future<List<dynamic>> getSupportTickets({bool admin = false}) async {
    final endpoint = admin
        ? '/customer_support?admin=true'
        : '/customer_support';
    return await get(endpoint) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getSupportTicket(int id) async {
    return await get('/customer_support?id=$id') as Map<String, dynamic>;
  }

  static Future<void> createSupportTicket(Map<String, dynamic> data) async {
    await post('/customer_support', data);
  }

  static Future<void> updateSupportTicket(
    int id,
    Map<String, dynamic> data,
  ) async {
    await put('/customer_support?id=$id', data);
  }

  static Future<void> deleteSupportTicket(int id) async {
    await delete('/customer_support?id=$id');
  }

  // --- Product Specifications API ---

  static Future<List<dynamic>> getProductSpecifications(int productId) async {
    return await get(
          '/product_specifications?product_id=$productId',
          withAuth: false,
        )
        as List<dynamic>;
  }

  static Future<void> addProductSpecification(Map<String, dynamic> data) async {
    await post('/product_specifications', data);
  }

  // --- Site Settings API ---

  static Future<List<dynamic>> getSiteSettings() async {
    final res = await get('/site_settings', withAuth: false);
    return _asList(res);
  }

  static Future<Map<String, dynamic>> getSiteSetting(String key) async {
    // Use _withReprobeBase directly to avoid _ensureTrailingSlash turning
    // /site_settings?key=foo into /site_settings/?key=foo which loses the param
    final result = await _withReprobeBase((base) async {
      final res = await http
          .get(
            Uri.parse('$base/site_settings?key=$key'),
            headers: await _headers(withAuth: false),
          )
          .timeout(_requestTimeout);
      final body = _tryJsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body is Map<String, dynamic> ? body : <String, dynamic>{};
      }
      throw ApiException(
        body is Map
            ? (body['error'] ?? body['message'] ?? 'Request failed')
            : 'Request failed',
        res.statusCode,
      );
    });
    return result as Map<String, dynamic>;
  }

  static Future<void> saveSiteSetting(Map<String, dynamic> data) async {
    // Use _withReprobeBase directly to avoid trailing slash on /site_settings/
    await _withReprobeBase((base) async {
      final res = await http
          .post(
            Uri.parse('$base/site_settings'),
            headers: await _headers(withAuth: true),
            body: jsonEncode(data),
          )
          .timeout(_requestTimeout);
      return _handleResponse(res);
    });
  }

  // --- Banners API ---

  static Future<Map<String, dynamic>> getBanners() async {
    return await get('/banners', withAuth: false) as Map<String, dynamic>;
  }

  // --- Image Upload API ---

  static Future<String> uploadImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse(getUploadUrl());
      if (kDebugMode) debugPrint('Uploading to: $uri');

      final request = http.MultipartRequest('POST', uri);

      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: fileName),
      );

      if (kDebugMode) debugPrint('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        debugPrint('Upload response status: ${response.statusCode}');
        debugPrint('Upload response body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Return the image URL from response
        final url = data['url'] ?? data['image_url'] ?? data['path'] ?? '';
        if (url.isEmpty) {
          throw ApiException('No URL in upload response', response.statusCode);
        }
        return url;
      } else {
        throw ApiException(
          'Upload failed: ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Upload error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Upload error: $e', 0);
    }
  }

  // --- Search History API ---

  static Future<List<dynamic>> getPopularSearches({int limit = 10}) async {
    return await get(
          '/search_history?popular=true&limit=$limit',
          withAuth: false,
        )
        as List<dynamic>;
  }

  static Future<List<dynamic>> getSearchHistory() async {
    return await get('/search_history', withAuth: false) as List<dynamic>;
  }

  // --- Payments API ---

  static Future<List<dynamic>> getPayments({int? orderId}) async {
    final endpoint = orderId != null
        ? '/payments?order_id=$orderId'
        : '/payments';
    return await get(endpoint) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getPayment(int id) async {
    return await get('/payments?id=$id') as Map<String, dynamic>;
  }

  /// Initiate an SSLCommerz payment session.
  /// Returns a map containing at minimum `GatewayPageURL` (the redirect URL).
  static Future<Map<String, dynamic>> initiateSSLPayment({
    required double amount,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? couponCode,
    double couponDiscount = 0,
    double deliveryCharge = 0,
    String deliveryZone = 'outside_dhaka',
    List<Map<String, dynamic>> items = const [],
  }) async {
    return _withReprobeBase((base) async {
      final res = await http
          .post(
            Uri.parse('$base/ssl/initiate'),
            headers: await _headers(withAuth: false),
            body: jsonEncode({
              'amount': amount,
              'customer_name': customerName,
              'customer_phone': customerPhone,
              'delivery_address': deliveryAddress,
              if (couponCode != null && couponCode.isNotEmpty)
                'coupon_code': couponCode,
              if (couponDiscount > 0) 'coupon_discount': couponDiscount,
              'delivery_charge': deliveryCharge,
              'delivery_zone': deliveryZone,
              'items': items,
            }),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(res);
    });
  }

  // --- Admin Reports API ---

  static Future<List<dynamic>> getAdminReports() async {
    return await get('/reports') as List<dynamic>;
  }

  static Future<void> createAdminReport(Map<String, dynamic> data) async {
    await post('/reports', data);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class _CacheEntry {
  final dynamic data;
  final DateTime time;
  _CacheEntry(this.data, this.time);
}
