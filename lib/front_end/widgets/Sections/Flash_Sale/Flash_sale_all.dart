import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:electrocitybd1/config/app_colors.dart';
import '../../../All_Pages/CART/Cart_provider.dart';
import '../../../Dimensions/responsive_dimensions.dart';
import '../../../Provider/Admin_product_provider.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../footer.dart';
import '../../header.dart';
import '../../store_breadcrumb_bar.dart';

class FlashSaleAll extends StatefulWidget {
  final String breadcrumbLabel;

  const FlashSaleAll({super.key, this.breadcrumbLabel = 'Flash_Sale Products'});

  @override
  State<FlashSaleAll> createState() => _FlashSaleAllState();
}

class _FlashSaleAllState extends State<FlashSaleAll> {
  static const int _rowsPerPage = 3;
  static const double _priceMin = 0;
  static const double _priceMax = 50000;
  static const imgPath = "assets/flash";

  int _currentPage = 1;
  String _selectedSort = 'featured';
  List<Map<String, dynamic>> _dbProducts = [];
  bool _loading = true;
  bool _mobileFiltersOpen = false;

  final List<String> _selectedCategories = [];
  final List<String> _selectedBrands = [];
  final List<String> _selectedSpecifications = [];

  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _priceRange = const RangeValues(_priceMin, _priceMax);
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      dynamic res = await ApiService.getProducts(
        section: 'flash-sale',
        limit: 60,
      );
      List<dynamic> list = [];
      if (res is Map<String, dynamic>) {
        list = (res['products'] as List<dynamic>?) ?? [];
      } else if (res is List) {
        list = res;
      }
      // If flash-sale section is empty, fall back to all DB products
      if (list.isEmpty) {
        res = await ApiService.getProducts(limit: 60);
        if (res is Map<String, dynamic>) {
          list = (res['products'] as List<dynamic>?) ?? [];
        } else if (res is List) {
          list = res;
        }
      }
      if (mounted)
        setState(() {
          _dbProducts = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
    } catch (e) {
      debugPrint('Flash_Sale Load Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, Object>> _convertDbProducts() {
    return _dbProducts
        .map(
          (p) => <String, Object>{
            'title': p['product_name'] ?? '',
            'price': _parsePrice(p['price']),
            'category': p['category_name'] ?? 'General',
            'brand': p['brand_name'] ?? '',
            'specs': const <String>[],
            'image': p['image_url'] ?? '',
            'isDb': true,
            'product_id': p['product_id'] ?? '',
            'stock_quantity':
                int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0,
            'description': p['description'] ?? '',
          },
        )
        .toList();
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0;
  }

  // Convert admin products
  List<Map<String, dynamic>> _convertAdminProducts(
    List<Map<String, dynamic>> adminProducts,
  ) {
    return adminProducts.map((p) {
      final price = _parsePrice(p['price']);
      final imageUrl =
          p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty
          ? p['imageUrl'] as String
          : '';

      return {
        'title': p['name'] ?? '',
        'price': price,
        'category': p['category'] ?? 'Uncategorized',
        'brand': p['brand'] ?? 'Unknown', // Use actual brand if available
        'specs': <String>[],
        'image': imageUrl,
        'isAdmin': true,
        'adminRaw': p,
      };
    }).toList();
  }

  Widget _buildAdminImage(Map<String, Object> item) {
    final raw = item['adminRaw'];
    if (raw == null || raw is! Map<String, dynamic>) {
      return Container(
        color: Colors.black26,
        child: const Icon(Icons.image, size: 50),
      );
    }
    if (raw['bytes'] != null) {
      return Image.memory(raw['bytes']!, fit: BoxFit.contain);
    }
    final url = raw['imageUrl'] as String?;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black26,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }
    return Container(
      color: Colors.black26,
      child: const Icon(Icons.image, size: 50),
    );
  }

  // All products (DB + Admin)
  List<Map<String, Object>> _allProducts(BuildContext context) {
    final adminProducts = Provider.of<AdminProductProvider>(
      context,
    ).getProductsBySection("Flash_Sale");
    final adminConverted = _convertAdminProducts(
      adminProducts,
    ).map((e) => Map<String, Object>.from(e)).toList();
    final dbConverted = _convertDbProducts();

    return [...dbConverted, ...adminConverted];
  }

  List<Map<String, Object>> _filteredProducts(BuildContext context) {
    final allProducts = _allProducts(context);

    return allProducts.where((p) {
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

  // Extract unique categories from products (excluding dummy values)
  List<String> _getUniqueCategories(BuildContext context) {
    final allProducts = _allProducts(context);
    final categories = allProducts
        .map((p) => (p['category'] ?? '').toString())
        .where((c) => c.isNotEmpty && c != 'All' && c != 'General')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Extract unique brands from products
  List<String> _getUniqueBrands(BuildContext context) {
    final allProducts = _allProducts(context);
    final brands = allProducts
        .map((p) => (p['brand'] ?? '').toString())
        .where((b) => b.isNotEmpty && b != 'All')
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  // Extract unique specs from products
  List<String> _getUniqueSpecs(BuildContext context) {
    final allProducts = _allProducts(context);
    final specs = <String>{};
    for (var p in allProducts) {
      final productSpecs = (p['specs'] as List<String>?) ?? const <String>[];
      for (final s in productSpecs) {
        if (s.isNotEmpty && s != 'N/A') specs.add(s);
      }
    }
    final specsList = specs.toList();
    specsList.sort();
    return specsList;
  }

  int _getCategoryCount(BuildContext context, String cat) {
    return _allProducts(context).where((p) => (p['category'] ?? '').toString() == cat).length;
  }

  int _getBrandCount(BuildContext context, String brand) {
    return _allProducts(context).where((p) => (p['brand'] ?? '').toString() == brand).length;
  }

  bool get _hasActiveFilters =>
      _selectedCategories.isNotEmpty ||
      _selectedBrands.isNotEmpty ||
      _selectedSpecifications.isNotEmpty ||
      _priceRange.start > _priceMin ||
      _priceRange.end < _priceMax;

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedBrands.clear();
      _selectedSpecifications.clear();
      _priceRange = const RangeValues(_priceMin, _priceMax);
      _currentPage = 1;
    });
  }

  List<Map<String, Object>> _sortedProducts(BuildContext context) {
    final filtered = _filteredProducts(context);
    final sorted = List<Map<String, Object>>.from(filtered);

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
    final isAdmin = item.containsKey('isAdmin');
    final isDb = item['isDb'] == true;
    final imageStr = item['image'] as String;
    final images = imageStr.isNotEmpty ? [imageStr] : <String>[];

    final product = ProductData(
      id: isDb
          ? '${item['product_id']}'
          : (isAdmin
                ? 'admin_flash_$index'
                : '${item['title']}_${item['price']}'),
      name: item['title'] as String,
      category: item['category'] as String,
      priceBDT: item['price'] as double,
      images: images,
      description: isAdmin
          ? 'Admin uploaded product'
          : isDb
          ? (item['description'] as String? ?? '')
          : 'Limited time Flash_Sale deal.',
      additionalInfo: {
        'Category': item['category'] as String,
        'Brand': item['brand'] as String,
        'Price': 'Tk ${(item['price'] as double).toStringAsFixed(0)}',
        if (item['stock_quantity'] != null)
          'stock_quantity': '${item['stock_quantity']}',
        if (isAdmin) 'Source': 'Admin Upload',
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
            const StoreBreadcrumbBar(currentPage: 'Flash Sale Deals'),
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
                        _buildProductsSection(r, gridCount, context),
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
                        Expanded(
                          child: _buildProductsSection(r, gridCount, context),
                        ),
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
          widget.breadcrumbLabel.toUpperCase(),
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

  Widget _buildFilterPanel(AppResponsive r, BuildContext context) {
    final categories = _getUniqueCategories(context);
    final brands = _getUniqueBrands(context);
    final specs = _getUniqueSpecs(context);

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

          // Price Range Section
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

          // Categories Section
          if (categories.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            _filterSectionWithCount(
              title: 'Categories',
              options: categories,
              selectedList: _selectedCategories,
              getCount: (cat) => _getCategoryCount(context, cat),
            ),
          ],

          // Brands Section
          if (brands.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            _filterSectionWithCount(
              title: 'Brands',
              options: brands,
              selectedList: _selectedBrands,
              getCount: (b) => _getBrandCount(context, b),
            ),
          ],

          // Specs Section
          if (specs.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            _filterSectionWithCount(
              title: 'Specifications',
              options: specs,
              selectedList: _selectedSpecifications,
              getCount: null,
            ),
          ],
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
                  onTap: () => _toggleFilter(selectedList, opt),
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
                            onChanged: (_) => _toggleFilter(selectedList, opt),
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

  Widget _buildProductsSection(
    AppResponsive r,
    int gridCount,
    BuildContext context,
  ) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final items = _sortedProducts(context);
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
              const SizedBox(height: 16),
              Text(
                'No Flash_Sale products available',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
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
            ? const Center(child: Text("No products match your filters."))
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
                  item: pageItems[index],
                  index: index,
                  onTap: () => _openDetails(pageItems[index], index),
                ),
              ),
        const SizedBox(height: 30),
        _buildPagination(totalPages),
      ],
    );
  }

  Widget _productCard({
    required Map<String, Object> item,
    required int index,
    required VoidCallback onTap,
  }) {
    final isAdmin = item.containsKey('isAdmin');

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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: isAdmin
                          ? _buildAdminImage(item)
                          : ImageResolver.image(
                              imageUrl: item['image'] as String?,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tk ${(item['price'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFEA580C),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Use actual product_id if available, else fall back to title slug
                        final cartId =
                            (item['product_id'] != null &&
                                item['product_id'].toString().isNotEmpty)
                            ? item['product_id'].toString()
                            : 'flash-${(item['title'] as String).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '')}';

                        await context.read<CartProvider>().addToCart(
                          productId: cartId,
                          name: item['title'] as String,
                          price: item['price'] as double,
                          imageUrl: (item['image'] as String? ?? '').toString(),
                          category: item['category'] as String,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item['title']} added to cart'),
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
