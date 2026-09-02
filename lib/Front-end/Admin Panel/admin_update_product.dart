import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Provider/Admin_product_provider.dart';
import '../Provider/product_refresh_notifier.dart';
import '../pages/home_page.dart';
import '../utils/api_service.dart';
import '../utils/constants.dart';
import '../utils/image_resolver.dart';
import 'Admin_sidebar.dart';
import 'A_customers.dart';
import 'admin_scaffold.dart';

/// Admin page to view and delete specific products (from database and from website sections).
class AdminUpdateProductPage extends StatefulWidget {
  const AdminUpdateProductPage({super.key});

  @override
  State<AdminUpdateProductPage> createState() => _AdminUpdateProductPageState();
}

class _AdminUpdateProductPageState extends State<AdminUpdateProductPage> {
  List<Map<String, dynamic>> _dbProducts = [];
  bool _loading = true;
  String? _error;
  int _totalDb = 0;
  static const String _cacheKey = 'admin_db_products_cache';
  bool _probing = false;
  String? _probeStatus;

  @override
  void initState() {
    super.initState();
    _loadDbProducts();
  }

  String _effectiveApiBase() {
    return ApiService.overrideBaseUrl ?? AppConstants.baseUrl;
  }

  Future<void> _showApiConfigDialog() async {
    final controller = TextEditingController(text: _effectiveApiBase());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        title: const Text(
          'Set API Base URL',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://your-host/api',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = controller.text.trim();
      if (!v.startsWith('http')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Enter a valid URL starting with http or https'),
          ),
        );
        return;
      }
      ApiService.setBaseUrl(v);
      setState(() {
        _probeStatus = null;
      });
      await _loadDbProducts();
    }
  }

  Future<void> _probeApi() async {
    setState(() {
      _probing = true;
      _probeStatus = null;
    });
    try {
      await ApiService.get('/health', withAuth: false);
      if (!mounted) return;
      setState(() {
        _probeStatus = 'OK';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _probeStatus = 'Fail';
      });
    } finally {
      if (mounted) {
        setState(() {
          _probing = false;
        });
      }
    }
  }

  Future<void> _loadDbProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      debugPrint('🔍 Loading products from API...');
      final res = await ApiService.getProducts(limit: 200);
      debugPrint('✅ API Response type: ${res.runtimeType}');

      // Handle different response formats
      List<dynamic> list = [];
      if (res is List) {
        // Direct list response
        debugPrint('📦 Direct list response with ${res.length} items');
        list = res;
      } else if (res is Map) {
        // Map response with products key
        debugPrint('📦 Map response');
        list =
            (res['products'] as List<dynamic>?) ??
            (res['data'] as List<dynamic>?) ??
            [];
        debugPrint('📦 Extracted ${list.length} products from map');
      }

      _dbProducts = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      debugPrint('✅ Loaded ${_dbProducts.length} products');

      // Load section information for each product
      await _loadProductSections();

      // Get total count
      if (res is Map) {
        _totalDb = (res['total'] as int?) ?? _dbProducts.length;
      } else {
        _totalDb = _dbProducts.length;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(_dbProducts));
        debugPrint('💾 Cached products');
      } catch (e) {
        debugPrint('⚠️ Cache save failed: $e');
      }
    } on ApiException catch (e) {
      debugPrint('❌ ApiException: ${e.message}');
      bool restored = await _restoreFromCache();
      if (!restored) {
        setState(() {
          _error = e.message;
          _dbProducts = [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading products: $e');
      debugPrint('Stack trace: $stackTrace');
      bool restored = await _restoreFromCache();
      if (!restored) {
        setState(() {
          _error = 'Failed to load products: $e';
          _dbProducts = [];
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProductSections() async {
    try {
      // Load all section data
      final bestSellers = await ApiService.getBestSellers(limit: 100);
      final trending = await ApiService.getTrendingProducts(limit: 100);
      final techPart = await ApiService.getTechPartProducts();
      final deals = await ApiService.getDeals();
      final flashSales = await ApiService.getFlashSales();

      // Create maps for quick lookup
      final bestSellerIds = bestSellers.map((p) => p['product_id']).toSet();
      final trendingIds = trending.map((p) => p['product_id']).toSet();
      final techPartIds = techPart.map((p) => p['product_id']).toSet();
      final dealIds = deals.map((p) => p['product_id']).toSet();

      // Extract flash sale product IDs
      final flashSaleIds = <int>{};
      for (var sale in flashSales) {
        if (sale['products'] != null) {
          for (var p in sale['products']) {
            flashSaleIds.add(p['product_id']);
          }
        }
      }

      // Add section info to each product
      for (var product in _dbProducts) {
        final pid = product['product_id'];
        final sections = <String>[];

        if (bestSellerIds.contains(pid)) sections.add('Best Sellers');
        if (trendingIds.contains(pid)) sections.add('Trending');
        if (techPartIds.contains(pid)) sections.add('Tech Part');
        if (dealIds.contains(pid)) sections.add('Deals');
        if (flashSaleIds.contains(pid)) sections.add('Flash Sale');

        product['sections'] = sections;
      }

      debugPrint('✅ Loaded section information for products');
    } catch (e) {
      debugPrint('⚠️ Failed to load section info: $e');
      // Continue without section info
    }
  }

  Future<bool> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _dbProducts = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _totalDb = _dbProducts.length;
        setState(() {
          _error = 'Showing cached products (offline)';
        });
        return true;
      }
    } catch (_) {}
    return false;
  }

  static void _navigateFromSidebar(
    BuildContext context,
    AdminSidebarItem item,
  ) {
    AdminNav.go(context, item);
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFF151C2C);
    const Color brandOrange = Color(0xFFF59E0B);

    final content = Column(
      children: [
        Container(
          color: cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Flexible(
                child: Text(
                  'Update & Delete Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: brandOrange),
                onPressed: _loading ? null : _loadDbProducts,
                tooltip: 'Refresh list',
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                ),
                icon: const Icon(Icons.store, color: brandOrange, size: 20),
                label: const Text(
                  'Back to Store',
                  style: TextStyle(
                    color: brandOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: brandOrange,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: brandOrange,
                  tabs: const [
                    Tab(text: 'Products in database'),
                    Tab(text: 'Section Products'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDbProductsList(context, brandOrange, cardBg),
                      _buildSectionProductsList(context, brandOrange, cardBg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return AdminScaffold(
      selected: AdminSidebarItem.products,
      onItemSelected: (item) => _navigateFromSidebar(context, item),
      body: content,
    );
  }

  Widget _buildDbProductsList(
    BuildContext context,
    Color brandOrange,
    Color cardBg,
  ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }
    if (_error != null && _dbProducts.isEmpty) {
      final provider = context.read<AdminProductProvider>();
      final fallback = <Map<String, dynamic>>[];
      provider.sectionProducts.forEach((section, list) {
        for (final p in list) {
          fallback.add({
            'product_id': null,
            'product_name': (p['name'] ?? '').toString(),
            'price': (p['price'] ?? '').toString(),
            'image_url': (p['imageUrl'] ?? '').toString(),
          });
        }
      });
      if (fallback.isNotEmpty) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Backend unavailable — showing products from website sections',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: fallback.length,
                itemBuilder: (context, index) {
                  final p = fallback[index];
                  final name = (p['product_name'] ?? '—').toString();
                  final price = (p['price'] ?? '').toString();
                  final imageUrl = (p['image_url'] ?? '').toString();
                  return _DbProductTile(
                    productId: null,
                    name: name,
                    price: price,
                    imageUrl: imageUrl,
                    onDeleted: () {},
                  );
                },
              ),
            ),
          ],
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.orange[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadDbProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
              ),
            ],
          ),
        ),
      );
    }
    if (_dbProducts.isEmpty) {
      return const Center(
        child: Text(
          'No products in database.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDbProducts,
      color: brandOrange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dbProducts.length,
        itemBuilder: (context, index) {
          final p = _dbProducts[index];
          final id = p['product_id'] ?? p['productId'];
          final name = (p['product_name'] ?? p['productName'] ?? '—')
              .toString();
          final price = (p['price'] ?? 0).toString();
          final imageUrl = (p['image_url'] ?? p['imageUrl'] ?? '').toString();
          final rating = (p['rating_avg'] ?? '').toString();
          final reviews = (p['review_count'] ?? '').toString();
          final sections = (p['sections'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();

          return _DbProductTile(
            productId: id is int ? id : int.tryParse(id?.toString() ?? ''),
            name: name,
            price: price,
            imageUrl: imageUrl,
            rating: rating.isNotEmpty ? rating : null,
            reviews: reviews.isNotEmpty ? reviews : null,
            sections: sections,
            onRefresh: _loadDbProducts,
            onDeleted: () {
              _dbProducts.removeAt(index);
              setState(() {});
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionProductsList(
    BuildContext context,
    Color brandOrange,
    Color cardBg,
  ) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _loadWebsiteSections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading sections: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sections = snapshot.data ?? {};
        int total = 0;
        for (final list in sections.values) {
          total += list.length;
        }

        if (total == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products in website sections yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add products to sections like Best Sellers, Trending, etc.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: brandOrange,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: sections.entries.map((entry) {
              final sectionName = entry.key;
              final list = entry.value;
              if (list.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _getSectionIcon(sectionName),
                        const SizedBox(width: 8),
                        Text(
                          sectionName,
                          style: TextStyle(
                            color: brandOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: brandOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${list.length} items',
                            style: TextStyle(
                              color: brandOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(list.length, (index) {
                      final p = list[index];
                      return _WebsiteSectionProductTile(
                        sectionName: sectionName,
                        productId: p['product_id'],
                        name: (p['product_name'] ?? '—').toString(),
                        price: (p['price'] ?? '').toString(),
                        imageUrl: (p['image_url'] ?? '').toString(),
                        onRefresh: () => setState(() {}),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _getSectionIcon(String sectionName) {
    IconData icon;
    Color color;

    switch (sectionName) {
      case 'Best Sellers':
        icon = Icons.star;
        color = Colors.amber;
        break;
      case 'Trending':
        icon = Icons.trending_up;
        color = Colors.pink;
        break;
      case 'Tech Part':
        icon = Icons.computer;
        color = Colors.blue;
        break;
      case 'Deals':
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      case 'Flash Sale':
        icon = Icons.flash_on;
        color = Colors.red;
        break;
      default:
        icon = Icons.category;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadWebsiteSections() async {
    final sections = <String, List<Map<String, dynamic>>>{};

    try {
      // Load Best Sellers
      final bestSellers = await ApiService.getBestSellers(limit: 100);
      sections['Best Sellers'] = bestSellers
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Load Trending
      final trending = await ApiService.getTrendingProducts(limit: 100);
      sections['Trending'] = trending
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Load Tech Part
      final techPart = await ApiService.getTechPartProducts();
      sections['Tech Part'] = techPart
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Load Deals
      final deals = await ApiService.getDeals();
      sections['Deals'] = deals
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Load Flash Sales
      final flashSales = await ApiService.getFlashSales();
      final flashProducts = <Map<String, dynamic>>[];
      for (var sale in flashSales) {
        if (sale['products'] != null) {
          for (var p in sale['products']) {
            flashProducts.add(Map<String, dynamic>.from(p as Map));
          }
        }
      }
      sections['Flash Sale'] = flashProducts;

      debugPrint('✅ Loaded website sections:');
      sections.forEach((key, value) {
        debugPrint('  - $key: ${value.length} products');
      });
    } catch (e) {
      debugPrint('❌ Error loading website sections: $e');
      rethrow;
    }

    return sections;
  }
}

class _DbProductTile extends StatelessWidget {
  final int? productId;
  final String name;
  final String price;
  final String imageUrl;
  final VoidCallback onDeleted;
  final VoidCallback? onRefresh;
  final String? rating;
  final String? reviews;
  final List<String>? sections;

  const _DbProductTile({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.rating,
    this.reviews,
    this.sections,
    this.onRefresh,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFF151C2C);
    const Color brandOrange = Color(0xFFF59E0B);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: Colors.white12,
              child: imageUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        ImageResolver.resolveUrl(imageUrl),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      color: Colors.redAccent,
                      size: 22,
                    ),
            ),
            if (imageUrl.isEmpty)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'No Img',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        title: Text(name, style: const TextStyle(color: Colors.black87)),
        subtitle: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '৳ $price • ID: $productId${(rating != null && rating!.isNotEmpty) ? ' • ★ $rating' : ''}${(reviews != null && reviews!.isNotEmpty) ? ' ($reviews)' : ''}',
              style: const TextStyle(color: Colors.green),
            ),
            if (imageUrl.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '⚠ No image — tap edit to add one',
                  style: TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
            if (sections != null && sections!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: sections!.map((section) {
                    Color chipColor;
                    IconData chipIcon;

                    switch (section) {
                      case 'Best Sellers':
                        chipColor = Colors.amber;
                        chipIcon = Icons.star;
                        break;
                      case 'Trending':
                        chipColor = Colors.pink;
                        chipIcon = Icons.trending_up;
                        break;
                      case 'Tech Part':
                        chipColor = Colors.blue;
                        chipIcon = Icons.computer;
                        break;
                      case 'Deals':
                        chipColor = Colors.orange;
                        chipIcon = Icons.local_offer;
                        break;
                      case 'Flash Sale':
                        chipColor = Colors.red;
                        chipIcon = Icons.flash_on;
                        break;
                      default:
                        chipColor = Colors.grey;
                        chipIcon = Icons.label;
                    }

                    return Chip(
                      avatar: Icon(chipIcon, size: 14, color: Colors.white),
                      label: Text(
                        section,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor: chipColor.withOpacity(0.85),
                      side: BorderSide(color: chipColor, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        trailing: productId == null
            ? null
            : SizedBox(
                width: 132,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 0,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit product',
                      onPressed: () => _editProduct(context, productId!),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_rate, color: Colors.amber),
                      tooltip: 'Edit rating',
                      onPressed: () => _editRating(context, productId!),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete from database',
                      onPressed: () => _confirmDelete(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _editRating(BuildContext context, int pid) async {
    final rCtrl = TextEditingController(text: rating ?? '');
    final cCtrl = TextEditingController(text: reviews ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        title: const Text(
          'Update Rating',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Average rating (0-5)',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Review count',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final avg = double.tryParse(rCtrl.text.trim()) ?? 0;
      final cnt = int.tryParse(cCtrl.text.trim()) ?? 0;
      try {
        await ApiService.setProductRating(
          productId: pid,
          ratingAvg: avg,
          reviewCount: cnt,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Rating updated'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update rating'),
          ),
        );
      }
    }
  }

  Future<void> _editProduct(BuildContext context, int pid) async {
    // Load product data first
    Map<String, dynamic>? productData;
    try {
      final res = await ApiService.get('/products?id=$pid', withAuth: false);
      if (res is Map<String, dynamic>) {
        productData = res['product'] as Map<String, dynamic>? ?? res;
      }
    } catch (_) {}

    if (!context.mounted) return;

    List<Map<String, dynamic>> categories = [];
    List<Map<String, dynamic>> brands = [];
    try {
      final catRes = await ApiService.get('/categories', withAuth: false);
      categories =
          (catRes is List
                  ? catRes
                  : (catRes as Map)['categories'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      final brandRes = await ApiService.getBrands();
      brands = brandRes
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {}

    if (!context.mounted) return;

    final nameC = TextEditingController(
      text: productData?['product_name']?.toString() ?? name,
    );
    final priceC = TextEditingController(
      text: productData?['price']?.toString() ?? price,
    );
    final stockC = TextEditingController(
      text: productData?['stock_quantity']?.toString() ?? '0',
    );
    final descC = TextEditingController(
      text: productData?['description']?.toString() ?? '',
    );
    int? selectedCategoryId = productData?['category_id'] is int
        ? productData!['category_id'] as int
        : int.tryParse(productData?['category_id']?.toString() ?? '');
    int? selectedBrandId = productData?['brand_id'] is int
        ? productData!['brand_id'] as int
        : int.tryParse(productData?['brand_id']?.toString() ?? '');
    Uint8List? pickedBytes;
    String? pickedFileName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF151C2C),
          title: Text(
            'Edit: $name',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _editField(nameC, 'Product Name'),
                  const SizedBox(height: 10),
                  _editField(priceC, 'Price (BDT)', numeric: true),
                  const SizedBox(height: 10),
                  _editField(stockC, 'Stock Quantity', numeric: true),
                  const SizedBox(height: 10),
                  _editField(descC, 'Description', maxLines: 3),
                  const SizedBox(height: 10),
                  if (categories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      dropdownColor: const Color(0xFF0B121E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['category_id'] as int?,
                              child: Text(c['category_name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => selectedCategoryId = v),
                    ),
                  const SizedBox(height: 10),
                  if (brands.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedBrandId,
                      dropdownColor: const Color(0xFF0B121E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: brands
                          .map(
                            (b) => DropdownMenuItem<int>(
                              value: b['brand_id'] as int?,
                              child: Text(b['brand_name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => selectedBrandId = v),
                    ),
                  const SizedBox(height: 12),
                  // Image preview
                  if (pickedBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        pickedBytes!,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if ((productData?['image_url'] ?? imageUrl)
                      .toString()
                      .isNotEmpty)
                    Image.network(
                      ImageResolver.resolveUrl(
                        (productData?['image_url'] ?? imageUrl).toString(),
                      ),
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      pickedBytes != null ? 'Change Image' : 'Pick New Image',
                    ),
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          imageQuality: 85,
                        );
                        if (file != null) {
                          final bytes = await file.readAsBytes();
                          setS(() {
                            pickedBytes = bytes;
                            pickedFileName = file.name;
                          });
                        }
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      final base = ApiService.overrideBaseUrl ?? AppConstants.baseUrl;
      if (pickedBytes != null && pickedFileName != null) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('$base/products?id=$pid'),
        );
        final token = await ApiService.getToken();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
        request.fields['product_name'] = nameC.text.trim();
        request.fields['price'] = priceC.text.trim();
        request.fields['stock_quantity'] = stockC.text.trim();
        request.fields['description'] = descC.text.trim();
        if (selectedCategoryId != null)
          request.fields['category_id'] = selectedCategoryId.toString();
        if (selectedBrandId != null)
          request.fields['brand_id'] = selectedBrandId.toString();
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            pickedBytes!,
            filename: pickedFileName!,
          ),
        );
        await request.send();
      } else {
        await ApiService.put('/products?id=$pid', {
          'product_name': nameC.text.trim(),
          'price': double.tryParse(priceC.text.trim()) ?? 0,
          'stock_quantity': int.tryParse(stockC.text.trim()) ?? 0,
          'description': descC.text.trim(),
          if (selectedCategoryId != null) 'category_id': selectedCategoryId,
          if (selectedBrandId != null) 'brand_id': selectedBrandId,
        });
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Product updated'),
        ),
      );
      // Notify all product section widgets to reload fresh data
      context.read<ProductRefreshNotifier>().refresh();
      onRefresh?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Failed: $e')),
      );
    }
  }

  static Widget _editField(
    TextEditingController c,
    String label, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        title: const Text(
          'Delete product from database?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will remove "$name" from the database. It will no longer appear on the website.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ApiService.deleteProduct(productId!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Product deleted from database'),
        ),
      );
      // Notify all product section widgets to reload fresh data
      context.read<ProductRefreshNotifier>().refresh();
      onDeleted();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Delete failed. Check backend.'),
        ),
      );
    }
  }
}

class _SectionProductTile extends StatelessWidget {
  final String sectionTitle;
  final int index;
  final String name;
  final String price;
  final String imageUrl;
  final bool hasImageBytes;
  final dynamic imageBytes;

  const _SectionProductTile({
    required this.sectionTitle,
    required this.index,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.hasImageBytes,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFF151C2C);
    const Color brandOrange = Color(0xFFF59E0B);
    final provider = context.read<AdminProductProvider>();

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.white12,
          child: hasImageBytes && imageBytes != null
              ? ClipOval(
                  child: Image.memory(
                    Uint8List.fromList(List<int>.from(imageBytes as List)),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                )
              : imageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    ImageResolver.resolveUrl(imageUrl),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                )
              : const Icon(Icons.image, color: Colors.white54),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          '৳ $price',
          style: const TextStyle(color: Colors.green, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 22,
          ),
          tooltip: 'Remove from website section',
          onPressed: () => _confirmRemove(context, provider),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AdminProductProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        title: const Text(
          'Remove from section?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$name" from "$sectionTitle" on the website?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      provider.removeProduct(sectionTitle, index);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Product removed from section'),
          ),
        );
      }
    }
  }
}

class _WebsiteSectionProductTile extends StatelessWidget {
  final String sectionName;
  final int productId;
  final String name;
  final String price;
  final String imageUrl;
  final VoidCallback onRefresh;

  const _WebsiteSectionProductTile({
    required this.sectionName,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFF151C2C);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: Colors.white12,
          child: imageUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    ImageResolver.resolveUrl(imageUrl),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                )
              : const Icon(Icons.image, color: Colors.white54),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          '৳ $price • ID: $productId',
          style: const TextStyle(color: Colors.green, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 22,
          ),
          tooltip: 'Remove from section',
          onPressed: () => _confirmRemove(context),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151C2C),
        title: const Text(
          'Remove from section?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove "$name" from "$sectionName"?\n\nNote: This will remove it from the database section table.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        // Remove from appropriate section based on name
        switch (sectionName) {
          case 'Best Sellers':
            await ApiService.removeBestSeller(productId);
            break;
          case 'Trending':
            await ApiService.removeTrendingProduct(productId);
            break;
          case 'Deals':
            await ApiService.deleteDeal(productId);
            break;
          // Add other sections as needed
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Product removed from section'),
            ),
          );
          onRefresh();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Failed to remove: $e'),
            ),
          );
        }
      }
    }
  }
}
