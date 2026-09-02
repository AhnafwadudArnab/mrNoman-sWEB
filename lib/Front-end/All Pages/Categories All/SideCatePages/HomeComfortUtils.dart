import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Dimensions/responsive_dimensions.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../../widgets/footer.dart';
import '../../../widgets/header.dart';
import '../../CART/Cart_provider.dart';

class HomeComfortUtilityPage extends StatefulWidget {
  final String breadcrumbLabel;
  const HomeComfortUtilityPage({
    super.key,
    this.breadcrumbLabel = 'Home Comfort & Utility',
  });

  @override
  State<HomeComfortUtilityPage> createState() => _HomeComfortUtilityPageState();
}

class _HomeComfortUtilityPageState extends State<HomeComfortUtilityPage> {
  static const double _priceMin = 0;
  static const double _priceMax = 50000;

  static double _parsePrice(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  RangeValues _priceRange = const RangeValues(_priceMin, _priceMax);
  List<Map<String, Object>> _dbProducts = [];
  Timer? _autoRefreshTimer;
  bool _mobileFiltersOpen = false;
  bool _isLoading = false;

  final List<String> _selectedCategories = [];
  final List<String> _selectedBrands = [];
  final List<String> _selectedSpecifications = [];

  @override
  void initState() {
    super.initState();
    _loadFromDb();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _loadFromDb();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFromDb() async {
    try {
      // Store current filter selections before loading
      final currentSelectedCats = List<String>.from(_selectedCategories);
      final currentSelectedBrands = List<String>.from(_selectedBrands);

      if (mounted) setState(() => _isLoading = true);

      final res = await ApiService.getProducts(
        category: 'Home Appliances',
        categoryId: 1,
        limit: 50,
        fresh: true,
      );
      final list = (res['products'] as List<dynamic>?) ?? [];
      if (mounted)
        setState(() {
          _dbProducts = list.map((e) {
            final p = e as Map<String, dynamic>;
            return <String, Object>{
              'title': (p['product_name'] ?? '').toString().trim(),
              'price': _parsePrice(p['price']),
              'subCat': (p['category_name'] ?? p['category'] ?? '')
                  .toString()
                  .trim(),
              'brand': (p['brand_name'] ?? 'Brand').toString().trim(),
              'specs': (p['specifications'] ?? '').toString().trim(),
              'image': (p['image_url'] ?? '').toString().trim(),
            };
          }).toList();
          // Restore and validate filter selections
          _selectedCategories.clear();
          _selectedCategories.addAll(
            currentSelectedCats.where((x) => _categoryOptions.contains(x)),
          );
          _selectedBrands.clear();
          _selectedBrands.addAll(
            currentSelectedBrands.where((x) => _brandOptions.contains(x)),
          );
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, Object>> get _products => _dbProducts;

  List<String> get _categoryOptions {
    final set = _products
        .map((p) => (p['subCat'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  List<String> get _brandOptions {
    final set = _products
        .map((p) => (p['brand'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty && v.toLowerCase() != 'brand')
        .toSet()
        .toList();
    set.sort();
    return set;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon for new arrivals.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
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
      smallDesktop: 4,
      desktop: 4,
    );

    return Scaffold(
      appBar: const Header(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBanner(),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 8,
                  mobile: 12,
                  tablet: 24,
                  smallDesktop: 36,
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
                          _buildFilterPanel(),
                          const SizedBox(height: 20),
                        ] else
                          const SizedBox(height: 20),
                        _buildGrid(gridCount),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 300, child: _buildFilterPanel()),
                        const SizedBox(width: 24),
                        Expanded(child: _buildGrid(gridCount)),
                      ],
                    ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final hasActiveFilters =
        _selectedCategories.isNotEmpty ||
        _selectedBrands.isNotEmpty ||
        _priceRange.start > _priceMin ||
        _priceRange.end < _priceMax;

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (hasActiveFilters)
                  GestureDetector(
                    onTap: () => setState(() {
                      _priceRange = const RangeValues(_priceMin, _priceMax);
                      _selectedCategories.clear();
                      _selectedBrands.clear();
                      _selectedSpecifications.clear();
                    }),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
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
              activeColor: Colors.orange,
              inactiveColor: Colors.grey[200],
              divisions: 50,
              labels: RangeLabels(
                '৳${_priceRange.start.round()}',
                '৳${_priceRange.end.round()}',
              ),
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Tk ${_priceRange.start.round()} - Tk ${_priceRange.end.round()}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(height: 30),
            if (_categoryOptions.isNotEmpty) ...[
              _filterGroup('Categories', _categoryOptions, _selectedCategories),
              const Divider(),
            ],
            if (_brandOptions.isNotEmpty) ...[
              _filterGroup('Brands', _brandOptions, _selectedBrands),
            ],
            if (_categoryOptions.isEmpty && _brandOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No filters available',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
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

  Widget _filterGroup(
    String title,
    List<String> options,
    List<String> selectedList,
  ) {
    final selectedCount = selectedList.length;
    return ExpansionTile(
      initiallyExpanded: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ),
        ],
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8, right: 0),
      children: options
          .map(
            (opt) => CheckboxListTile(
              title: Text(opt, style: const TextStyle(fontSize: 12)),
              value: selectedList.contains(opt),
              onChanged: (v) => setState(
                () => v! ? selectedList.add(opt) : selectedList.remove(opt),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.orange,
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid(int gridCount) {
    final filtered = _products.where((p) {
      final matchesPrice =
          (p['price'] as double) >= _priceRange.start &&
          (p['price'] as double) <= _priceRange.end;
      final matchesCat =
          _selectedCategories.isEmpty ||
          _selectedCategories.contains(p['subCat']);
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(p['brand']);
      return matchesPrice && matchesCat && matchesBrand;
    }).toList();

    if (filtered.isEmpty) return _buildEmptyState();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridCount,
        childAspectRatio: gridCount == 2 ? 0.58 : 0.7,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemBuilder: (context, i) => _productCard(filtered[i]),
    );
  }

  Widget _productCard(Map<String, Object> item) {
    return InkWell(
      onTap: () => _openDetails(item),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ImageResolver.image(imageUrl: item['image'] as String?),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '৳${(item['price'] as double).round()}',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<CartProvider>().addToCart(
                      productId: item['title'].toString(),
                      name: item['title'].toString(),
                      price: item['price'] as double,
                      imageUrl: item['image'] as String,
                      category: 'Home Utility',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size.fromHeight(32),
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(color: Colors.white, fontSize: 12),
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

  void _openDetails(Map<String, Object> item) {
    final product = ProductData(
      id: item['title'].toString(),
      name: item['title'] as String,
      category: 'Home Utility',
      priceBDT: item['price'] as double,
      images: [item['image'] as String],
      description: 'Reliable ${item['title']} for your home.',
      additionalInfo: {
        'Brand': item['brand'].toString(),
        'Type': item['subCat'].toString(),
      },
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalProductDetails(product: product),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.blueGrey[800],
      child: Center(
        child: Text(
          widget.breadcrumbLabel.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
