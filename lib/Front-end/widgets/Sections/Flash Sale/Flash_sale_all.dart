import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../All Pages/CART/Cart_provider.dart';
import '../../../Dimensions/responsive_dimensions.dart';
import '../../../Provider/Admin_product_provider.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../footer.dart';
import '../../header.dart';

class FlashSaleAll extends StatefulWidget {
  final String breadcrumbLabel;

  const FlashSaleAll({super.key, this.breadcrumbLabel = 'Flash Sale Products'});

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
      final res = await ApiService.getProducts(
        section: 'flash-sale',
        limit: 60,
      );
      final List<dynamic> list;
      if (res is Map<String, dynamic>) {
        list = (res['products'] as List<dynamic>?) ?? [];
      } else if (res is List) {
        list = res;
      } else {
        list = [];
      }
      if (mounted)
        setState(() {
          _dbProducts = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
    } catch (e) {
      debugPrint('Flash Sale Load Error: $e');
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

  // স্যাম্পল প্রোডাক্ট (ডিফল্ট)
  static const List<Map<String, Object>> _sampleProducts = [
    {
      'title': 'Circular Saw',
      'price': 7200.0,
      'category': 'Power Tools',
      'brand': 'Brand A',
      'specs': ['Corded', 'Laser Guide'],
      'image': "$imgPath/Circular Saw.jpg",
    },
    {
      'title': 'Orbital Sander',
      'price': 3800.0,
      'category': 'Power Tools',
      'brand': 'Brand B',
      'specs': ['Cordless', 'LED Light', 'Ergonomic Grip'],
      'image': "$imgPath/Orbital Sander.jpg",
    },
    // ... অন্যান্য স্যাম্পল প্রোডাক্ট
  ];

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0;
  }

  // অ্যাডমিন প্রোডাক্টকে স্ট্যান্ডার্ড ফরম্যাটে কনভার্ট করা
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
        color: Colors.grey[300],
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
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 50),
    );
  }

  // সব প্রোডাক্ট (DB + অ্যাডমিন)
  List<Map<String, Object>> _allProducts(BuildContext context) {
    final adminProducts = Provider.of<AdminProductProvider>(
      context,
    ).getProductsBySection("Flash Sale");
    final adminConverted = _convertAdminProducts(
      adminProducts,
    ).map((e) => Map<String, Object>.from(e)).toList();
    final dbConverted = _convertDbProducts();
    // Only show DB and admin products, no sample products
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

  // Extract unique categories from products
  List<String> _getUniqueCategories(BuildContext context) {
    final allProducts = _allProducts(context);
    final categories = allProducts
        .map((p) => p['category'] as String)
        .toSet()
        .toList();
    categories.sort();
    return categories.isEmpty ? ['All'] : categories;
  }

  // Extract unique brands from products
  List<String> _getUniqueBrands(BuildContext context) {
    final allProducts = _allProducts(context);
    final brands = allProducts
        .map((p) => p['brand'] as String)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    brands.sort();
    return brands.isEmpty ? ['All'] : brands;
  }

  // Extract unique specs from products
  List<String> _getUniqueSpecs(BuildContext context) {
    final allProducts = _allProducts(context);
    final specs = <String>{};
    for (var p in allProducts) {
      final productSpecs = (p['specs'] as List<String>?) ?? const <String>[];
      specs.addAll(productSpecs);
    }
    final specsList = specs.toList();
    specsList.sort();
    return specsList.isEmpty ? ['N/A'] : specsList;
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
          : 'Limited time flash sale deal.',
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

  // --- UI Components (আগের মতোই থাকবে, শুধু _buildProductsSection আপডেট হবে) ---

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
            inactiveColor: Colors.grey[300],
            onChanged: (val) => setState(() => _priceRange = val),
          ),
          Text(
            'Tk ${_priceRange.start.round()} - Tk ${_priceRange.end.round()}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 20),
          _filterSection(
            title: 'Categories',
            options: _getUniqueCategories(context),
            selectedList: _selectedCategories,
          ),
          _filterSection(
            title: 'Brands',
            options: _getUniqueBrands(context),
            selectedList: _selectedBrands,
          ),
          _filterSection(
            title: 'Specs',
            options: _getUniqueSpecs(context),
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
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey[300]!),
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
            ),
          )
          .toList(),
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
    if (_dbProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No flash sale products available',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    final items = _sortedProducts(context);
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
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
          border: Border.all(color: Colors.grey[200]!),
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
                      child: item['isDb'] == true
                          ? ImageResolver.image(
                              imageUrl: item['image'] as String?,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : isAdmin
                          ? _buildAdminImage(item)
                          : Image.asset(
                              item['image'] as String,
                              fit: BoxFit.fill,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
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
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '৳ ${(item['price'] as double).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.amber[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text('${i + 1}'),
            selected: _currentPage == i + 1,
            onSelected: (s) => setState(() => _currentPage = i + 1),
            selectedColor: Colors.amber,
            showCheckmark: false,
          ),
        ),
      ),
    );
  }
}
