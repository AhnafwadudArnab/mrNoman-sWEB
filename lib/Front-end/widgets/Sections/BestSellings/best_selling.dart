import 'dart:convert';

import 'package:electrocitybd1/Front-end/pages/Templates/Dyna_products.dart';
import 'package:electrocitybd1/Front-end/widgets/Sections/BestSellings/ProductData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Provider/Admin_product_provider.dart';
import '../../../Provider/api_ready_notifier.dart';
import '../../../Provider/product_refresh_notifier.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../../utils/optimized_image_widget.dart';

class BestSellingBox extends StatefulWidget {
  const BestSellingBox({super.key});

  @override
  State<BestSellingBox> createState() => _BestSellingBoxState();
}

class _BestSellingBoxState extends State<BestSellingBox> {
  List<Map<String, dynamic>> _dbProducts = [];
  bool _loading = true;
  bool _initialized = false;

  bool _loadTriggered = false;
  int _lastRefreshVersion = -1;

  @override
  void initState() {
    super.initState();
    _initialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ready = context.watch<ApiReadyNotifier>().isReady;
    final refreshVersion = context.watch<ProductRefreshNotifier>().version;

    if (ready && !_loadTriggered) {
      _loadTriggered = true;
      _lastRefreshVersion = refreshVersion;
      _loadFromDb();
    } else if (_loadTriggered && refreshVersion != _lastRefreshVersion) {
      // Admin added/updated a product — reload fresh data
      _lastRefreshVersion = refreshVersion;
      _loadFromDb();
    }
  }

  Future<void> _loadFromDb() async {
    if (mounted) setState(() => _loading = true);
    try {
      // Use best-sellers action endpoint with cache enabled
      final res = await ApiService.get(
        '/products?action=best-sellers&limit=10',
        withAuth: false,
        useCache: true,
      );

      List<dynamic> productsList;
      if (res is Map<String, dynamic>) {
        productsList = (res['products'] as List<dynamic>? ?? []);
      } else if (res is List) {
        productsList = res;
      } else {
        productsList = [];
      }

      if (mounted)
        setState(() {
          _dbProducts = productsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
    } catch (e) {
      debugPrint('Error loading best sellers: $e');
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProducts = context
        .watch<AdminProductProvider>()
        .getProductsBySection("Best Sellings");
    final sampleProducts = SampleProducts.bestSellingProducts;

    final bool useDb = _dbProducts.isNotEmpty;
    final bool hasAdmin = adminProducts.isNotEmpty && !useDb;

    final listTiles = <Widget>[];
    if (!_loading) {
      const int maxItems = 4;
      if (useDb) {
        final count = _dbProducts.length < maxItems
            ? _dbProducts.length
            : maxItems;
        for (int i = 0; i < count; i++) {
          listTiles.add(_buildTileFromDb(context, _dbProducts[i], i));
        }
      } else if (hasAdmin) {
        final count = adminProducts.length < maxItems
            ? adminProducts.length
            : maxItems;
        for (int i = 0; i < count; i++) {
          listTiles.add(
            _buildBestSellingTile(
              context,
              adminProducts[i],
              index: i,
              isFromAdmin: true,
            ),
          );
        }
      } else {
        final count = sampleProducts.length < maxItems
            ? sampleProducts.length
            : maxItems;
        for (int i = 0; i < count; i++) {
          listTiles.add(
            _buildBestSellingTile(
              context,
              sampleProducts[i],
              index: i,
              isFromAdmin: false,
            ),
          );
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Best Selling',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (!_loading && listTiles.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: listTiles,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Widget _buildTileFromDb(
    BuildContext context,
    Map<String, dynamic> p,
    int index,
  ) {
    final id = p['product_id']?.toString() ?? '$index';
    final name = p['product_name'] ?? '';
    final price = _parsePrice(p['price']);
    final imageUrl = ImageResolver.resolveUrl(p['image_url'] as String? ?? '');
    final desc = (p['description'] ?? '').toString();
    final stockQty = int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;

    // Merge brand/category plus any specs_json into additional info
    final Map<String, String> info = {};
    final brandName = p['brand_name']?.toString();
    final catName = p['category_name']?.toString();
    if (brandName != null && brandName.isNotEmpty) info['Brand'] = brandName;
    if (catName != null && catName.isNotEmpty) info['Category'] = catName;
    info['stock_quantity'] = stockQty.toString();
    final specs = p['specs_json'];
    if (specs is Map) {
      for (final entry in specs.entries) {
        final k = entry.key?.toString() ?? '';
        final v = entry.value?.toString() ?? '';
        if (k.isNotEmpty && v.isNotEmpty) info[_normalizeSpecKey(k)] = v;
      }
    } else if (specs is String && specs.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(specs);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final k = entry.key?.toString() ?? '';
            final v = entry.value?.toString() ?? '';
            if (k.isNotEmpty && v.isNotEmpty) info[_normalizeSpecKey(k)] = v;
          }
        }
      } catch (_) {
        /* ignore */
      }
    }

    final productData = ProductData(
      id: id,
      name: name,
      category: p['category_name'] ?? 'Best Selling',
      priceBDT: price,
      images: imageUrl.isNotEmpty ? [imageUrl] : [],
      description: desc,
      additionalInfo: info,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UniversalProductDetails(product: productData),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.white,
                child: imageUrl.isNotEmpty
                    ? OptimizedImageWidget(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stockQty > 0
                        ? (stockQty <= 5
                              ? 'Only $stockQty left!'
                              : '$stockQty in stock')
                        : 'Out of stock',
                    style: TextStyle(
                      fontSize: 11,
                      color: stockQty > 0
                          ? (stockQty <= 5 ? Colors.orange : Colors.green[700])
                          : Colors.red,
                      fontWeight: stockQty <= 5
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳ ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeSpecKey(String raw) {
    final s = raw.replaceAll('_', ' ').trim();
    if (s.isEmpty) return raw;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildBestSellingTile(
    BuildContext context,
    dynamic product, {
    required int index,
    required bool isFromAdmin,
  }) {
    final productId = isFromAdmin
        ? 'admin_best_$index'
        : 'sample_best_${product.id}';
    final productName = isFromAdmin ? (product['name'] ?? '') : product.name;
    final productPrice = isFromAdmin
        ? (double.tryParse(
                product['price']?.toString().replaceAll(
                      RegExp(r'[^0-9.]'),
                      '',
                    ) ??
                    '0',
              ) ??
              0.0)
        : product.priceBDT;

    // Get image URL or bytes
    String? imageUrl;
    dynamic imageBytes;

    if (isFromAdmin) {
      // Check for imageUrl first (from server)
      if (product['imageUrl'] != null &&
          (product['imageUrl'] as String).isNotEmpty) {
        imageUrl = product['imageUrl'] as String;
      }
      // Fallback to image bytes (from file picker)
      if (imageUrl == null && product['bytes'] != null) {
        imageBytes = product['bytes'];
      }
    } else {
      // Sample product
      if (product.images.isNotEmpty) {
        imageUrl = product.images.first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          ProductData productData;
          if (isFromAdmin) {
            productData = ProductData(
              id: productId,
              name: productName,
              category: 'Best Selling',
              priceBDT: productPrice,
              images: imageUrl != null ? [imageUrl] : [],
              description: product['desc'] ?? '',
              additionalInfo: {
                'Category': product['category'] ?? '',
                'stock_quantity':
                    (product['stock_quantity'] ?? product['stock'] ?? 10)
                        .toString(),
              },
            );
          } else {
            productData = product;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UniversalProductDetails(product: productData),
            ),
          );
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                color: Colors.white,
                child: imageUrl != null
                    ? OptimizedImageWidget(
                        imageUrl: imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        '4.5',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (isFromAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳ ${productPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF97316),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

