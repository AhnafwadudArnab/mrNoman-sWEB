import 'package:electrocitybd1/front_end/pages/Templates/all_products_template.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../All_Pages/CART/Cart_provider.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import '../../widgets/store_breadcrumb_bar.dart';
import 'Dyna_products.dart';

class CategoryProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String? categoryNameFallback;
  final String? brandFilter; // pre-selected brand from sidebar

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.categoryNameFallback,
    this.brandFilter,
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  static const int _rowsPerPage = 3;
  static const double _priceMin = 0;
  static const double _priceMax = 50000;

  int _currentPage = 1;
  String _selectedSort = 'featured';
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;
  bool _mobileFiltersOpen = false;

  final List<String> _selectedBrands = [];
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _priceRange = const RangeValues(_priceMin, _priceMax);
    // Pre-select brand if passed from sidebar
    if (widget.brandFilter != null && widget.brandFilter!.isNotEmpty) {
      _selectedBrands.add(widget.brandFilter!);
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.getProducts(
        categoryId: widget.categoryId > 0 ? widget.categoryId : null,
        category: widget.categoryId <= 0
            ? (widget.categoryNameFallback ?? widget.categoryName)
            : null,
        limit: 100,
        useCache: false,
      );
      final List<dynamic> list;
      if (res is Map<String, dynamic>) {
        list = (res['products'] as List<dynamic>?) ?? [];
      } else if (res is List) {
        list = res;
      } else {
        list = [];
      }
      if (mounted) {
        setState(() {
          _products = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Unable to load products. Please check your connection.';
          _loading = false;
        });
      }
    }
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0;
  }

  List<Map<String, dynamic>> _filteredProducts() {
    return _products.where((p) {
      final price = _parsePrice(p['price']);
      final brand = p['brand_name'] ?? '';

      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(brand);

      return matchesPrice && matchesBrand;
    }).toList();
  }

  List<String> _getUniqueBrands() {
    final brands = _products
        .map((p) => p['brand_name'] as String?)
        .where((b) => b != null && b.isNotEmpty && b != 'All')
        .toSet()
        .toList();
    brands.sort();
    return brands.cast<String>();
  }

  int _getBrandCount(String brand) {
    return _products.where((p) => (p['brand_name']?.toString() ?? '') == brand).length;
  }

  bool get _hasActiveFilters =>
      _selectedBrands.isNotEmpty ||
      _priceRange.start > _priceMin ||
      _priceRange.end < _priceMax;

  void _clearAllFilters() {
    setState(() {
      _selectedBrands.clear();
      _priceRange = const RangeValues(_priceMin, _priceMax);
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> _sortedProducts() {
    final filtered = _filteredProducts();
    final sorted = List<Map<String, dynamic>>.from(filtered);

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
        (a, b) => (a['product_name'] ?? '').compareTo(b['product_name'] ?? ''),
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

  void _toggleBrand(String brand) {
    setState(() {
      if (_selectedBrands.contains(brand)) {
        _selectedBrands.remove(brand);
      } else {
        _selectedBrands.add(brand);
      }
      _currentPage = 1;
    });
  }

  void _openDetails(Map<String, dynamic> product) {
    final images = product['image_url'] != null
        ? [product['image_url'] as String]
        : <String>[];

    final productData = ProductData(
      id: '${product['product_id']}',
      name: product['product_name'] ?? '',
      category: product['category_name'] ?? widget.categoryName,
      priceBDT: _parsePrice(product['price']),
      images: images,
      description: product['description'] ?? 'High quality product',
      additionalInfo: {
        'Category': product['category_name'] ?? widget.categoryName,
        'Brand': product['brand_name'] ?? 'Unknown',
        'Price': 'Tk ${_parsePrice(product['price']).toStringAsFixed(0)}',
        'stock_quantity': (product['stock_quantity'] ?? '0').toString(),
        if (product['rating_avg'] != null) 'rating': '${product['rating_avg']}',
        if (product['review_count'] != null)
          'review_count': '${product['review_count']}',
      },
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalProductDetails(product: productData),
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
            StoreBreadcrumbBar(
              currentPage: widget.categoryName,
              parentPage: 'Categories',
            ),
            _buildBanner(r),
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
                        _buildMobileFilterToggle(r),
                        if (_mobileFiltersOpen) ...[
                          const SizedBox(height: 12),
                          _buildFilterPanel(r),
                          const SizedBox(height: 16),
                        ] else
                          const SizedBox(height: 16),
                        _buildProductsSection(r, gridCount),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: sideWidth, child: _buildFilterPanel(r)),
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

  Widget _buildBanner(AppResponsive r) {
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
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(AppResponsive r) {
    final brands = _getUniqueBrands();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.tune, size: 18, color: Color(0xFF111827)),
                  SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              if (_hasActiveFilters)
                InkWell(
                  onTap: _clearAllFilters,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tk ${_priceRange.start.round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('-', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Tk ${_priceRange.end.round()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: _priceMin,
            max: _priceMax,
            activeColor: const Color(0xFFF59E0B),
            inactiveColor: const Color(0xFFE5E7EB),
            onChanged: (val) => setState(() {
              _priceRange = val;
              _currentPage = 1;
            }),
          ),
          const SizedBox(height: 12),

          // Brands Section
          if (brands.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            _filterSectionWithCount(
              title: 'Brands',
              options: brands,
              selectedList: _selectedBrands,
              getCount: _getBrandCount,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileFilterToggle(AppResponsive r) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
        icon: Icon(_mobileFiltersOpen ? Icons.close : Icons.tune, size: 18, color: const Color(0xFF111827)),
        label: Text(
          _mobileFiltersOpen ? 'Hide Filters' : 'Show Filters',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _filterSectionWithCount({
    required String title,
    required List<String> options,
    required List<String> selectedList,
    int Function(String)? getCount,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: SingleChildScrollView(
            child: Column(
              children: options.map((opt) {
                final isSelected = selectedList.contains(opt);
                final count = getCount != null ? getCount(opt) : null;
                return InkWell(
                  onTap: () => _toggleBrand(opt),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleBrand(opt),
                            activeColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF111827) : const Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (count != null && count > 0)
                          Text(
                            '($count)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProductsSection(AppResponsive r, int gridCount) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
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
                _error!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProducts,
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

    final items = _sortedProducts();
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
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButton<String>(
                value: _selectedSort,
                underline: const SizedBox(),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF4B5563)),
                items: const [
                  DropdownMenuItem(value: 'featured', child: Text('Sort: Featured', style: TextStyle(color: Color(0xFF111827)))),
                  DropdownMenuItem(value: 'newest', child: Text('Newest First', style: TextStyle(color: Color(0xFF111827)))),
                  DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High', style: TextStyle(color: Color(0xFF111827)))),
                  DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low', style: TextStyle(color: Color(0xFF111827)))),
                  DropdownMenuItem(value: 'title', child: Text('Name: A-Z', style: TextStyle(color: Color(0xFF111827)))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSort = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        pageItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _products.isEmpty
                            ? 'No products in this category yet'
                            : 'No products match your filters',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey300,
                        ),
                      ),
                      if (_selectedBrands.isNotEmpty ||
                          _priceRange.start > _priceMin ||
                          _priceRange.end < _priceMax) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedBrands.clear();
                            _priceRange = const RangeValues(
                              _priceMin,
                              _priceMax,
                            );
                          }),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final totalSpacing = (gridCount - 1) * 15.0;
                  final cardWidth = (availableWidth - totalSpacing) / gridCount;

                  const double imageAspect = 1.22;
                  final imageHeight = cardWidth / imageAspect;

                  // Details area: padding (14px) + 2-line title (~28px) + gap (3px) + stock (~13px) + tight spacing (~8-10px) + price (~18px) + gap (5px) + button (30px) = ~122px
                  final double contentHeight = r.isSmallMobile ? 114.0 : 122.0;
                  final totalCardHeight = imageHeight + contentHeight;
                  final calculatedRatio =
                      (cardWidth / totalCardHeight).clamp(0.55, 0.95);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pageItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCount,
                      childAspectRatio: calculatedRatio,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemBuilder: (context, index) =>
                        _productCard(pageItems[index]),
                  );
                },
              ),
        const SizedBox(height: 30),
        if (pageItems.isNotEmpty) _buildPagination(totalPages),
      ],
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final price = _parsePrice(product['price']);
    final name = product['product_name'] ?? '';
    final imageUrl = product['image_url'] ?? '';
    final stockQty =
        int.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0;

    return InkWell(
      onTap: () => _openDetails(product),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0A000000),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact proportional image
            AspectRatio(
              aspectRatio: 1.22,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: ImageResolver.image(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stockQty > 0
                          ? (stockQty <= 5
                                ? 'Only $stockQty left!'
                                : '$stockQty in stock')
                          : 'Out of stock',
                      style: TextStyle(
                        fontSize: 10,
                        color: stockQty > 0
                            ? (stockQty <= 5
                                  ? Colors.orange
                                  : Colors.green[700])
                            : Colors.red,
                        fontWeight: stockQty <= 5
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Tk ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<CartProvider>().addToCart(
                            productId: 'cat-${product['product_id']}',
                            name: name,
                            price: price,
                            imageUrl: imageUrl,
                            category: widget.categoryName,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name added to cart'),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
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

  Widget _buildPagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: _currentPage > 1 ? Colors.amber[700] : Colors.black12,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black12,
              disabledForegroundColor: Colors.black38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            totalPages,
            (i) {
              final pageNum = i + 1;
              final isActive = _currentPage == pageNum;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  selected: isActive,
                  onSelected: (s) => setState(() => _currentPage = pageNum),
                  selectedColor: Colors.amber[700],
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isActive ? Colors.amber[700]! : const Color(0xFFCBD5E1),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: _currentPage < totalPages ? Colors.amber[700] : Colors.black12,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black12,
              disabledForegroundColor: Colors.black38,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
