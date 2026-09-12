import 'package:electrocitybd1/front_end/pages/Templates/all_products_template.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Dimensions/responsive_dimensions.dart';
import '../../../Provider/Admin_product_provider.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../utils/api_service.dart';
import '../../../utils/optimized_image_widget.dart';
import '../../footer.dart';
import '../../header.dart';
import '../../store_breadcrumb_bar.dart';

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
            StoreBreadcrumbBar(currentPage: widget.breadcrumbLabel),
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
                  color: Colors.black,
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
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                              color: Colors.black54,
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
                                color: AppColors.grey300,
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
                  if (totalPages > 1) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
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
                            (p) {
                              final pageNum = p + 1;
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
                    ),
                  ],
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






