import 'package:electrocitybd1/Front-end/pages/Templates/all_products_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Dimensions/responsive_dimensions.dart';
import '../../../Provider/Admin_product_provider.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../utils/api_service.dart';
import '../../../utils/optimized_image_widget.dart';
import '../../footer.dart';
import '../../header.dart';

class BestSellingAll extends StatefulWidget {
  final String breadcrumbLabel;
  const BestSellingAll({super.key, this.breadcrumbLabel = 'Best Selling'});
  @override
  State<BestSellingAll> createState() => _BestSellingAllState();
}

class _BestSellingAllState extends State<BestSellingAll> {
  static const int _rowsPerPage = 3;
  int _currentPage = 1;
  String _selectedSort = 'featured';
  List<Map<String, dynamic>> _db = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getProducts(
        section: 'best-sellers',
        limit: 60,
        useCache: false,
      );
      final List<dynamic> raw;
      if (res is Map<String, dynamic>) {
        raw = (res['products'] as List<dynamic>? ?? []);
      } else if (res is List) {
        raw = res;
      } else {
        raw = [];
      }
      final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted)
        setState(() {
          _db = list;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Unable to load products. Please check your connection.';
          _loading = false;
        });
    }
  }

  List<Map<String, dynamic>> _all(BuildContext context) {
    final admin = context.read<AdminProductProvider>().getProductsBySection(
      'Best Sellings',
    );
    final adminMapped = admin
        .map(
          (p) => {
            'title': (p['name'] ?? '').toString(),
            'price': _parsePrice(p['price']),
            'category': (p['category'] ?? 'General').toString(),
            'image': (p['imageUrl'] ?? '').toString(),
            'isAdmin': true,
          },
        )
        .toList();
    final dbMapped = _db
        .map(
          (p) => {
            'title': (p['product_name'] ?? '').toString(),
            'price': _parsePrice(p['price']),
            'category': (p['category_name'] ?? 'General').toString(),
            'image': (p['image_url'] ?? '').toString(),
            'product_id': p['product_id'],
            'rating': p['rating_avg'],
            'reviews': p['review_count'],
            'stock_quantity': p['stock_quantity'] ?? 0,
            'description': (p['description'] ?? '').toString(),
            'brand': (p['brand_name'] ?? '').toString(),
            'isDb': true,
          },
        )
        .toList();
    return [...dbMapped, ...adminMapped];
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
  }

  List<Map<String, dynamic>> _sorted(BuildContext context) {
    final items = _all(context);
    final sorted = List<Map<String, dynamic>>.from(items);
    if (_selectedSort == 'price_low') {
      sorted.sort(
        (a, b) => (a['price'] as double).compareTo(b['price'] as double),
      );
    } else if (_selectedSort == 'price_high') {
      sorted.sort(
        (a, b) => (b['price'] as double).compareTo(a['price'] as double),
      );
    }
    return sorted;
  }

  void _openDetails(Map<String, dynamic> item, int index) {
    final isDb = item['isDb'] == true;
    final imageStr = (item['image'] ?? '') as String;
    final images = imageStr.isNotEmpty ? [imageStr] : <String>[];
    final stockQty =
        int.tryParse(item['stock_quantity']?.toString() ?? '0') ?? 0;
    final product = ProductData(
      id: isDb ? '${item['product_id']}' : 'admin_best_$index',
      name: item['title'] as String,
      category: (item['category'] ?? 'General') as String,
      priceBDT: (item['price'] as double),
      images: images,
      description: (item['description'] ?? 'Best selling item').toString(),
      additionalInfo: {
        if ((item['brand'] ?? '').toString().isNotEmpty)
          'Brand': item['brand'].toString(),
        if ((item['rating'] ?? '') != '') 'rating': '${item['rating']}',
        if ((item['reviews'] ?? '') != '') 'review_count': '${item['reviews']}',
        'stock_quantity': stockQty.toString(),
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
    final grid = r.value(
      smallMobile: 2,
      mobile: 2,
      tablet: 3,
      smallDesktop: 3,
      desktop: 4,
    );
    final perPage = grid * _rowsPerPage;
    final items = _sorted(context);
    final totalPages = (items.length / perPage).ceil().clamp(1, 99).toInt();
    final pageItems = items
        .skip((_currentPage - 1) * perPage)
        .take(perPage)
        .toList();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: r.value(
                smallMobile: 120,
                mobile: 130,
                tablet: 160,
                smallDesktop: 180,
                desktop: 200,
              ),
              width: double.infinity,
              color: Colors.black12,
              alignment: Alignment.center,
              child: Text(
                widget.breadcrumbLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found ${items.length} items',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      DropdownButton<String>(
                        value: _selectedSort,
                        items: const [
                          DropdownMenuItem(
                            value: 'featured',
                            child: Text('Sort: Featured'),
                          ),
                          DropdownMenuItem(
                            value: 'price_low',
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: 'price_high',
                            child: Text('Price: High to Low'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedSort = v ?? 'featured'),
                        underline: const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Could not load products',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: grid,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemBuilder: (context, i) {
                        final it = pageItems[i];
                        final stockQty =
                            int.tryParse(
                              it['stock_quantity']?.toString() ?? '0',
                            ) ??
                            0;
                        return InkWell(
                          onTap: () => _openDetails(it, i),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
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
                                    child: OptimizedImageWidget(
                                      imageUrl: it['image'] as String?,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${it['title']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tk ${(it['price'] as double).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalPages,
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('${p + 1}'),
                          selected: _currentPage == p + 1,
                          onSelected: (s) =>
                              setState(() => _currentPage = p + 1),
                          selectedColor: Colors.amber,
                          showCheckmark: false,
                        ),
                      ),
                    ),
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
}
