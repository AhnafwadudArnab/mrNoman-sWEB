import 'package:electrocitybd1/front_end/pages/Templates/Dyna_products.dart';
import 'package:electrocitybd1/front_end/pages/Templates/all_products_template.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../All_Pages/CART/Cart_provider.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Admin_product_provider.dart';
import '../../Provider/api_ready_notifier.dart';
import '../../Provider/product_refresh_notifier.dart';
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';

class Techpart extends StatefulWidget {
  const Techpart({super.key});

  @override
  State<Techpart> createState() => _TechpartState();
}

class _TechpartState extends State<Techpart> {
  static const int _rowsPerPage = 2;
  int _itemsToShow = 0;
  int _itemsPerPage = 0;
  String _selectedSort = 'featured';
  List<Map<String, dynamic>> _dbProducts = [];
  bool _isLoading = true;
  String? _loadError;
  DateTime? _lastSyncAt;
  Timer? _autoRefreshTimer;

  Future<void> _loadFromDb({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final productsList = await ApiService.getTechPartProducts(
        limit: 40,
        useCache: true,
      );

      if (mounted) {
        setState(() {
          _dbProducts = productsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
          _loadError = null;
          _lastSyncAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Could not refresh Tech Part right now.';
        });
      }
      debugPrint('Error loading tech part: $e');
    }
  }

  static const List<String> _techImages = [
    'assets/prod/6.png',
    'assets/prod/7.png',
    'assets/prod/8.png',
    'assets/prod/9.png',
    'assets/prod/01.png',
    'assets/prod/09.png',
    'assets/prod/99.png',
  ];

  bool _loadTriggered = false;
  int _lastRefreshVersion = -1;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadFromDb(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger load the first time the API is marked ready.
    final ready = context.watch<ApiReadyNotifier>().isReady;
    final refreshVersion = context.watch<ProductRefreshNotifier>().version;

    if (ready && !_loadTriggered) {
      _loadTriggered = true;
      _lastRefreshVersion = refreshVersion;
      _loadFromDb();
    } else if (_loadTriggered && refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = refreshVersion;
      _loadFromDb();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ???????? ??????????? ????????????? ???????? ??????? ???
  List<Map<String, dynamic>> _convertAdminProducts(
    List<Map<String, dynamic>> adminProducts,
  ) {
    return adminProducts.map((p) {
      return {
        'name': p['name'] ?? '',
        'price': 'Tk ${p['price'] ?? '0'}',
        'rating': 4,
        'image': 'admin_image',
        'isAdmin': true,
        'adminData': p,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _convertDbProducts(
    List<Map<String, dynamic>> list,
  ) {
    return list
        .map(
          (p) => {
            'name': p['product_name'] ?? '',
            'price': 'Tk ${_parsePrice(p['price']).toStringAsFixed(0)}',
            'rating': 4,
            'image': p['image_url'] as String? ?? '',
            'isDb': true,
            'product_id': p['product_id'],
            'stock_quantity': p['stock_quantity'] ?? 0,
            'brand': p['brand_name'] ?? '',
            'description': p['description'] ?? '',
          },
        )
        .toList();
  }

  // ?? ????????? (DB + ????????)
  List<Map<String, dynamic>> _allProducts(BuildContext context) {
    final adminProducts = context
        .read<AdminProductProvider>()
        .getProductsBySection("Tech Part");
    final adminConverted = _convertAdminProducts(adminProducts);
    final dbConverted = _convertDbProducts(_dbProducts);
    return [...dbConverted, ...adminConverted];
  }

  void _loadMore() {
    final total = _sortedProducts(context).length;
    setState(() {
      final pageSize = _itemsPerPage > 0 ? _itemsPerPage : total;
      _itemsToShow = (_itemsToShow + pageSize).clamp(0, total);
    });
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _syncLabel() {
    final at = _lastSyncAt;
    if (at == null) return 'Syncing...';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    return 'Updated ${diff.inMinutes}m ago';
  }

  List<Map<String, dynamic>> _sortedProducts(BuildContext context) {
    final allProducts = _allProducts(context);
    final sorted = List<Map<String, dynamic>>.from(allProducts);

    if (_selectedSort == 'price_low') {
      sorted.sort(
        (a, b) => _parsePrice(a['price']).compareTo(_parsePrice(b['price'])),
      );
    } else if (_selectedSort == 'price_high') {
      sorted.sort(
        (a, b) => _parsePrice(b['price']).compareTo(_parsePrice(a['price'])),
      );
    } else if (_selectedSort == 'title') {
      sorted.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
    } else if (_selectedSort == 'newest') {
      sorted.sort(
        (a, b) => (b['product_id'] ?? 0).toString().compareTo(
          (a['product_id'] ?? 0).toString(),
        ),
      );
    }
    return sorted;
  }

  ProductData _buildProductData(Map<String, dynamic> product, int index) {
    if (product['isDb'] == true) {
      final stockQty =
          int.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0;
      return ProductData(
        id: '${product['product_id'] ?? index}',
        name: product['name'] as String,
        category: 'Tech Part',
        priceBDT: _parsePrice(product['price']),
        images:
            (product['image'] != null &&
                (product['image'] as String).isNotEmpty)
            ? [product['image'] as String]
            : [],
        description:
            (product['description'] ?? 'Tech part from our latest collection.')
                .toString(),
        additionalInfo: {
          'Brand': (product['brand'] ?? '').toString(),
          'Rating': '${product['rating'] ?? 4}',
          'stock_quantity': stockQty.toString(),
        },
      );
    }
    final isAdmin = product.containsKey('isAdmin');

    if (isAdmin) {
      final adminData = product['adminData'] as Map<String, dynamic>;
      final price = _parsePrice(adminData['price']);
      final stockQty =
          int.tryParse(
            adminData['stock_quantity']?.toString() ??
                adminData['stock']?.toString() ??
                '0',
          ) ??
          0;
      final adminImages =
          adminData['imageUrl'] != null &&
              (adminData['imageUrl'] as String).isNotEmpty
          ? [adminData['imageUrl'] as String]
          : <String>[];

      return ProductData(
        id: 'admin_tech_$index',
        name: adminData['name'] ?? '',
        category: 'Tech Part',
        priceBDT: price,
        images: adminImages,
        description: adminData['desc'] ?? '',
        additionalInfo: {
          'Category': adminData['category'] ?? '',
          'stock_quantity': stockQty.toString(),
        },
      );
    } else {
      return ProductData(
        id: 'tech_$index',
        name: product['name'] as String,
        category: 'Tech Part',
        priceBDT: _parsePrice(product['price']),
        images: [product['image'] as String],
        description: 'Tech part from our latest collection.',
        additionalInfo: {
          'Rating': '${product['rating']}',
          'stock_quantity': '10',
        },
      );
    }
  }

  void _openDetails(
    BuildContext context,
    Map<String, dynamic> product,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UniversalProductDetails(product: _buildProductData(product, index)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final crossAxisCount = r.value(
      smallMobile: 2,
      mobile: 2,
      tablet: 3,
      smallDesktop: 4,
      desktop: 5,
    );
    final sortedProducts = _sortedProducts(context);
    final total = sortedProducts.length;
    final itemsPerPage = crossAxisCount * _rowsPerPage;

    if (_isLoading && total == 0) {
      return Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (total == 0) {
      return const SizedBox.shrink();
    }

    if (_itemsPerPage != itemsPerPage || _itemsToShow == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _itemsPerPage = itemsPerPage;
          _itemsToShow = itemsPerPage.clamp(0, total);
        });
      });
    }

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.padding(context)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopBar(),
                  Builder(
                    builder: (context) {
                      final visibleCount = _itemsToShow.clamp(
                        0,
                        sortedProducts.length,
                      );
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: r.value(
                            smallMobile: 6.0,
                            mobile: 8.0,
                            tablet: 12.0,
                            smallDesktop: 14.0,
                            desktop: 16.0,
                          ),
                          mainAxisSpacing: r.value(
                            smallMobile: 6.0,
                            mobile: 8.0,
                            tablet: 12.0,
                            smallDesktop: 14.0,
                            desktop: 16.0,
                          ),
                        ),
                        itemCount: visibleCount,
                        itemBuilder: (context, index) =>
                            _buildProductCard(index, sortedProducts),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (total > 0 && _itemsToShow < total)
                    ElevatedButton(
                      onPressed: _loadMore,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Load More'),
                    )
                  else if (total > 0)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No more products here',
                        style: TextStyle(color: AppColors.bgDarkAlt),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminProductImage(Map<String, dynamic> product) {
    final adminData = product['adminData'] as Map<String, dynamic>?;
    if (adminData == null) {
      return Container(
        color: Colors.black26,
        child: const Icon(Icons.image, size: 50),
      );
    }
    if (adminData['bytes'] != null) {
      return Image.memory(adminData['bytes']!, fit: BoxFit.cover);
    }
    final imageUrl = adminData['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        ImageResolver.resolveUrl(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black26,
          child: const Icon(Icons.image, size: 50),
        ),
      );
    }
    return Container(
      color: Colors.black26,
      child: const Icon(Icons.image, size: 50),
    );
  }

  Widget _buildProductCard(
    int index,
    List<Map<String, dynamic>> sortedProducts,
  ) {
    final product = sortedProducts[index % sortedProducts.length];
    final isAdmin = product.containsKey('isAdmin');
    final imagePath = isAdmin ? null : _techImages[index % _techImages.length];
    final productData = _buildProductData(product, index);

    return InkWell(
      onTap: () => _openDetails(context, product, index),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.whiteOverlay36,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.error, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: product['isDb'] == true
                        ? ImageResolver.image(
                            imageUrl: product['image'] as String?,
                            fit: BoxFit.cover,
                          )
                        : isAdmin
                        ? _buildAdminProductImage(product)
                        : Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.monitor,
                              size: 100,
                              color: AppColors.overlayBlack26,
                            ),
                          ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      fontSize: AppDimensions.smallFont(context),
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 12,
                        color: i < (product['rating'] ?? 4)
                            ? AppColors.brandOrange
                            : AppColors.overlayBlack26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stock information
                  if (product['stock'] != null ||
                      product['stock_quantity'] != null)
                    Builder(
                      builder: (context) {
                        final stockQty =
                            int.tryParse(
                              product['stock']?.toString() ??
                                  product['stock_quantity']?.toString() ??
                                  '0',
                            ) ??
                            0;
                        return Text(
                          stockQty > 0
                              ? (stockQty <= 5
                                    ? 'Only $stockQty left!'
                                    : '$stockQty in stock')
                              : 'Out of stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: stockQty > 0
                                ? (stockQty <= 5
                                      ? AppColors.warningOrange
                                      : AppColors.greenShade800)
                                : AppColors.error,
                            fontWeight: stockQty <= 5
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product['price'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.bodyFont(context),
                      color: AppColors.brandOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await context.read<CartProvider>().addToCart(
                          productId: productData.id,
                          name: productData.name,
                          price: productData.priceBDT,
                          imageUrl: productData.images.isNotEmpty
                              ? productData.images.first
                              : '',
                          category: productData.category,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${productData.name} added to cart'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.add_shopping_cart, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final total = _sortedProducts(context).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '${total == 0 ? 0 : 1}-${_itemsToShow.clamp(0, total)} of $total results',
            style: const TextStyle(color: AppColors.bgDarkAlt, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _syncLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.bgDarkAlt, fontSize: 11),
            ),
          ),
          IconButton(
            tooltip: 'Refresh Tech Part',
            onPressed: () => _loadFromDb(),
            icon: const Icon(Icons.refresh, size: 18),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: _selectedSort,
            style: const TextStyle(color: Colors.black),
            items: const [
              DropdownMenuItem(
                value: 'featured',
                child: Text('Sort by', style: TextStyle(color: Colors.black)),
              ),
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              DropdownMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              DropdownMenuItem(value: 'title', child: Text('Name: A-Z')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedSort = v;
                _itemsToShow = _itemsPerPage;
              });
            },
          ),
        ],
      ),
    );
  }
}
