import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../All_Pages/CART/Cart_provider.dart';
import '../../../Dimensions/responsive_dimensions.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../footer.dart';
import '../../header.dart';

class TrendingAllProducts extends StatefulWidget {
  final String breadcrumbLabel;
  final String? categoryFilter; // Add category filter parameter

  const TrendingAllProducts({
    super.key,
    this.breadcrumbLabel = 'Trending Products',
    this.categoryFilter, // Optional category filter
  });

  @override
  State<TrendingAllProducts> createState() => _TrendingAllProducts();
}

class _TrendingAllProducts extends State<TrendingAllProducts> {
  static const int _rowsPerPage = 3;
  static const double _priceMin = 0;
  static const double _priceMax = 50000;
  static const imgPath = "assets/prod";

  int _currentPage = 1;
  String _selectedSort = 'featured';

  final List<String> _selectedCategories = [];
  final List<String> _selectedBrands = [];
  final List<String> _selectedSpecifications = [];

  // Products loaded from backend (DB)
  List<Map<String, Object>> _dbProducts = [];
  bool _loadingProducts = false;
  String? _loadError;
  bool _mobileFiltersOpen = false;

  static double _parsePrice(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _priceRange = const RangeValues(_priceMin, _priceMax);

    // If category filter is provided, add it to selected categories
    if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
      _selectedCategories.add(widget.categoryFilter!);
    }

    _fetchProductsFromBackend();
  }

  Future<void> _fetchProductsFromBackend() async {
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });
    try {
      // First try to get trending products
      dynamic res = await ApiService.getProducts(
        section: 'trending',
        category: widget.categoryFilter,
        sort: 'newest',
        limit: 60,
        useCache: false,
      );
      debugPrint('Trending API Response: $res');
      debugPrint('Category Filter: ${widget.categoryFilter}');

      // If trending returns empty, fall back to all products
      List<dynamic> checkList;
      if (res is Map<String, dynamic>) {
        checkList = (res['products'] as List<dynamic>? ?? []);
      } else if (res is List) {
        checkList = res;
      } else {
        checkList = [];
      }

      if (checkList.isEmpty) {
        debugPrint('No trending products found, falling back to all products');
        res = await ApiService.getProducts(
          category: widget.categoryFilter,
          sort: 'newest',
          limit: 60,
          useCache: false,
        );
      }

      // Handle both Map and List responses
      List<dynamic> productsList;
      if (res is Map<String, dynamic>) {
        productsList = (res['products'] as List<dynamic>? ?? []);
      } else if (res is List) {
        productsList = res;
      } else {
        productsList = [];
      }

      final list = productsList
          .where((raw) => raw != null)
          .map<Map<String, Object>>((raw) {
            if (raw == null) return <String, Object>{};
            final p = raw is Map
                ? Map<String, dynamic>.from(raw)
                : <String, dynamic>{};
            return {
              'title': (p['product_name'] ?? '') as String,
              'price': _parsePrice(p['price']),
              'category': (p['category_name'] ?? 'General') as String,
              'brand': (p['brand_name'] ?? '') as String,
              // Specs can later be mapped from attributes if needed.
              'specs': const <String>[],
              'image': (p['image_url'] ?? '') as String,
              'rating': p['rating_avg'] ?? p['rating'] ?? '',
              'reviews': p['review_count'] ?? p['reviews'] ?? '',
              'stock_quantity':
                  int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0,
              'product_id': p['product_id'] ?? '',
            };
          })
          .where((p) => p.isNotEmpty && (p['title'] as String).isNotEmpty)
          .toList();
      debugPrint('Trending Products Count: ${list.length}');
      if (mounted) {
        setState(() {
          _dbProducts = list;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trending products: $e');
      if (mounted) {
        setState(() {
          _loadError = e is ApiException
              ? e.message
              : 'Unable to load products. Please check your connection.';
          _loadingProducts = false;
        });
      }
    }
  }

  List<Map<String, Object>> _filteredProducts() {
    // Always use DB products, no fallback to sample products
    final base = _dbProducts;

    // If no products from DB, return empty list
    if (base.isEmpty) {
      return [];
    }

    return base.where((p) {
      final price = p['price'] as double;
      final category = p['category'] as String;
      final brand = p['brand'] as String;
      final specs = (p['specs'] as List<String>?) ?? const <String>[];

      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;
      final matchesCategory =
          _selectedCategories.isEmpty || _selectedCategories.contains(category);
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(brand);
      final matchesSpecs =
          _selectedSpecifications.isEmpty ||
          _selectedSpecifications.any(specs.contains);

      return matchesPrice && matchesCategory && matchesBrand && matchesSpecs;
    }).toList();
  }

  // Extract unique categories from products
  List<String> _getUniqueCategories() {
    // Only use DB products that are currently loaded
    final base = _dbProducts;
    if (base.isEmpty) return [];

    final categories = base
        .map((p) => p['category'] as String)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Extract unique brands from products
  List<String> _getUniqueBrands() {
    // Only use DB products that are currently loaded
    final base = _dbProducts;
    if (base.isEmpty) return [];

    final brands = base
        .map((p) => p['brand'] as String)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  // Extract unique specs from products
  List<String> _getUniqueSpecs() {
    // Only use DB products that are currently loaded
    final base = _dbProducts;
    if (base.isEmpty) return [];

    final specs = <String>{};
    for (var p in base) {
      final productSpecs = (p['specs'] as List<String>?) ?? const <String>[];
      specs.addAll(productSpecs);
    }
    final specsList = specs.toList();
    specsList.sort();
    return specsList;
  }

  List<Map<String, Object>> _sortedProducts(List<Map<String, Object>> items) {
    final sorted = List<Map<String, Object>>.from(items);
    if (_selectedSort == 'price_low') {
      sorted.sort(
        (a, b) => (a['price'] as double).compareTo(b['price'] as double),
      );
    } else if (_selectedSort == 'price_high') {
      sorted.sort(
        (a, b) => (b['price'] as double).compareTo(a['price'] as double),
      );
    } else if (_selectedSort == 'title') {
      sorted.sort(
        (a, b) => (a['title'] as String).compareTo(b['title'] as String),
      );
    } else if (_selectedSort == 'newest') {
      sorted.sort(
        (a, b) =>
            b['product_id'].toString().compareTo(a['product_id'].toString()),
      );
    }
    return sorted;
  }

  void _toggleFilter(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _currentPage = 1;
    });
  }

  void _openDetails(Map<String, Object> item, int index) {
    final product = ProductData(
      id: '${item['product_id'] ?? '${item['title']}_${item['price']}'}',
      name: item['title'] as String,
      category: item['category'] as String,
      priceBDT: item['price'] as double,
      images: [item['image'] as String],
      description:
          'High quality industrial ${item['title']} for professional use.',
      additionalInfo: {
        'Category': item['category'] as String,
        'Brand': item['brand'] as String,
        'Price': 'Tk ${(item['price'] as double).toStringAsFixed(0)}',
        'Specifications': (item['specs'] as List<String>).join(', '),
        if ((item['rating'] ?? '') != '') 'rating': '${item['rating']}',
        if ((item['reviews'] ?? '') != '') 'review_count': '${item['reviews']}',
        if (item['stock_quantity'] != null)
          'stock_quantity': '${item['stock_quantity']}',
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalProductDetails(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isNarrow = r.isSmallMobile || r.isMobile;
    final gridCount = r.value(
      smallMobile: 2,
      mobile: 2,
      tablet: 3,
      smallDesktop: 3,
      desktop: 4,
    );
    final sideWidth = r.value(
      smallMobile: 220.0,
      mobile: 240.0,
      tablet: 260.0,
      smallDesktop: 280.0,
      desktop: 300.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBanner(r, context),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 12,
                  mobile: 12,
                  tablet: 24,
                  smallDesktop: 32,
                  desktop: 48,
                ),
                vertical: 20,
              ),
              child: isNarrow
                  ? Column(
                      children: [
                        _buildMobileFilterToggle(),
                        if (_mobileFiltersOpen) ...[
                          const SizedBox(height: 12),
                          _buildFilterPanel(r, context),
                          const SizedBox(height: 16),
                        ] else
                          const SizedBox(height: 16),
                        _buildProductsSection(r, gridCount),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: sideWidth,
                          child: _buildFilterPanel(r, context),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: _buildProductsSection(r, gridCount)),
                      ],
                    ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildBanner(AppResponsive r, BuildContext context) {
    // Show category name in banner if filter is applied
    final displayTitle =
        widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty
        ? '${widget.breadcrumbLabel} - ${widget.categoryFilter}'
        : widget.breadcrumbLabel;

    return Container(
      height: r.value(
        smallMobile: 120,
        mobile: 130,
        tablet: 160,
        smallDesktop: 180,
        desktop: 200,
      ),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          displayTitle.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFilterPanel(AppResponsive r, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.grey300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: const Color(0x05000000), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (widget.categoryFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1A2196F3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.categoryFilter!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 30),
          const Text(
            'Price Range',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          RangeSlider(
            values: _priceRange,
            min: _priceMin,
            max: _priceMax,
            activeColor: Colors.amber[700],
            inactiveColor: Colors.black26,
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          Text(
            'Tk ${_priceRange.start.round()} - Tk ${_priceRange.end.round()}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          _filterSection(
            title: 'Categories',
            options: _getUniqueCategories(),
            selectedList: _selectedCategories,
          ),
          _filterSection(
            title: 'Brands',
            options: _getUniqueBrands(),
            selectedList: _selectedBrands,
          ),
          _filterSection(
            title: 'Specs',
            options: _getUniqueSpecs(),
            selectedList: _selectedSpecifications,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterToggle() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
        icon: Icon(_mobileFiltersOpen ? Icons.close : Icons.tune, size: 18),
        label: Text(_mobileFiltersOpen ? 'Hide Filters' : 'Show Filters'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.grey300,
          side: BorderSide(color: Colors.black26),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _filterSection({
    required String title,
    required List<String> options,
    required List<String> selectedList,
  }) {
    // Don't show filter section if no options available
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: true,
      children: options
          .map(
            (opt) => CheckboxListTile(
              title: Text(opt, style: const TextStyle(fontSize: 12)),
              value: selectedList.contains(opt),
              onChanged: (_) => _toggleFilter(selectedList, opt),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.amber[700],
            ),
          )
          .toList(),
    );
  }

  Widget _buildProductsSection(AppResponsive r, int gridCount) {
    // Show loading state
    if (_loadingProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.black54),
              const SizedBox(height: 16),
              const Text(
                'Could not load products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: TextStyle(color: AppColors.grey300, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProductsFromBackend,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _sortedProducts(_filteredProducts());
    final perPage = gridCount * _rowsPerPage;
    final totalPages = (items.length / perPage).ceil().clamp(1, 99).toInt();
    final pageItems = items
        .skip((_currentPage - 1) * perPage)
        .take(perPage)
        .toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Found ${items.length} items',
              style: const TextStyle(color: AppColors.grey300, fontSize: 13),
            ),
            DropdownButton<String>(
              value: _selectedSort,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: 'featured',
                  child: Text('Sort: Featured'),
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
              onChanged: (v) => setState(() => _selectedSort = v!),
            ),
          ],
        ),
        const SizedBox(height: 16),
        pageItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppColors.grey300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _dbProducts.isEmpty
                            ? "No products available."
                            : "No products match your filters.",
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.grey300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_dbProducts.isEmpty)
                        const Text(
                          "Please add products to the database.",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey300,
                          ),
                        ),
                      if (_selectedCategories.isNotEmpty ||
                          _selectedBrands.isNotEmpty ||
                          _selectedSpecifications.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategories.clear();
                              _selectedBrands.clear();
                              _selectedSpecifications.clear();
                              _priceRange = const RangeValues(
                                _priceMin,
                                _priceMax,
                              );
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: r.isSmallMobile || r.isMobile ? 0.60 : 0.72,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, index) => _productCard(
                  title: pageItems[index]['title'] as String,
                  price: pageItems[index]['price'] as double,
                  category: pageItems[index]['category'] as String,
                  image: pageItems[index]['image'] as String,
                  stockQuantity: pageItems[index]['stock_quantity'] as int?,
                  productId: pageItems[index]['product_id']?.toString(),
                  onTap: () => _openDetails(pageItems[index], index),
                ),
              ),
        const SizedBox(height: 30),
        if (pageItems.isNotEmpty) _buildPagination(totalPages),
      ],
    );
  }

  Widget _productCard({
    required String title,
    required double price,
    required String category,
    required String image,
    required VoidCallback onTap,
    int? stockQuantity,
    String? productId,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: ImageResolver.image(
                    imageUrl: image,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tk ${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.amber[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (stockQuantity != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      stockQuantity > 0
                          ? (stockQuantity <= 5
                                ? 'Only $stockQuantity left!'
                                : '$stockQuantity in stock')
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: stockQuantity > 0
                            ? (stockQuantity <= 5
                                  ? Colors.orange
                                  : Colors.green[700])
                            : Colors.red,
                        fontWeight: stockQuantity <= 5
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Use actual product_id if available, else fall back to title slug
                        final cartId =
                            (productId != null && productId.isNotEmpty)
                            ? productId
                            : 'trend-${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '')}';

                        await context.read<CartProvider>().addToCart(
                          productId: cartId,
                          name: title,
                          price: price,
                          imageUrl: image,
                          category: category,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$title added to cart'),
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(32),
                      ),
                      child: const Text('Add to Cart'),
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

  Widget _buildPagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous button
        IconButton(
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: _currentPage > 1
                ? Colors.amber[700]
                : Colors.black26,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Page numbers
        ...List.generate(totalPages > 7 ? 7 : totalPages, (i) {
          int pageNum;
          if (totalPages <= 7) {
            pageNum = i + 1;
          } else {
            // Smart pagination: show first, last, current and nearby pages
            if (i == 0) {
              pageNum = 1;
            } else if (i == 6) {
              pageNum = totalPages;
            } else if (_currentPage <= 4) {
              pageNum = i + 1;
            } else if (_currentPage >= totalPages - 3) {
              pageNum = totalPages - 6 + i;
            } else {
              pageNum = _currentPage - 3 + i;
            }
          }

          final isActive = _currentPage == pageNum;
          final isEllipsis =
              totalPages > 7 &&
              ((i == 1 && _currentPage > 4) ||
                  (i == 5 && _currentPage < totalPages - 3));

          if (isEllipsis) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '...',
                style: TextStyle(fontSize: 18, color: AppColors.grey300),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _currentPage = pageNum),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? Colors.amber[700] : Colors.white,
                  border: Border.all(
                    color: isActive ? Colors.amber[700]! : Colors.black26,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.grey200,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(width: 12),
        // Next button
        IconButton(
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: _currentPage < totalPages
                ? Colors.amber[700]
                : Colors.black26,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
