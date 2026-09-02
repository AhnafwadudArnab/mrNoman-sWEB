import 'package:electrocitybd1/Front-end/pages/Templates/all_products_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Provider/Admin_product_provider.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../utils/api_service.dart';
import '../../../utils/optimized_image_widget.dart';
import '../../footer.dart';
import '../../header.dart';

class CollectionDetailPage extends StatefulWidget {
  final String collectionName;
  final String collectionSlug;
  final int? collectionId;
  final IconData icon;

  const CollectionDetailPage({
    super.key,
    required this.collectionName,
    required this.collectionSlug,
    this.collectionId,
    required this.icon,
  });

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _dbProducts = [];
  bool _isLoading = true;
  String? _error;

  // Filter state
  String? _selectedCategory;
  bool _mobileFiltersOpen = false;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 12;
  int get _totalPages {
    final total = _allProducts.length;
    if (total == 0) return 1;
    return (total / _itemsPerPage).ceil();
  }

  // Maximum pages to show in pagination
  int get _maxPagesToShow => 5;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load products from API based on collection
      // Try using collectionId first if available, otherwise use slug as category
      final res = await ApiService.getProducts(
        categoryId: widget.collectionId,
        category: widget.collectionId == null ? widget.collectionSlug : null,
        limit: 100,
        fresh: true,
      );

      // Handle both Map and List responses
      List<dynamic> productsList;
      if (res is Map<String, dynamic>) {
        productsList = (res['products'] as List<dynamic>? ?? []);
      } else if (res is List) {
        productsList = List<dynamic>.from(res as Iterable<dynamic>);
      } else {
        productsList = [];
      }

      final list = productsList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (mounted) {
        setState(() {
          _dbProducts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _allProducts {
    final admin = context.read<AdminProductProvider>().getProductsBySection(
      widget.collectionName,
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

    final dbMapped = _dbProducts
        .map(
          (p) => {
            'title': (p['product_name'] ?? '').toString(),
            'price': _parsePrice(p['price']),
            'category': (p['category_name'] ?? 'General').toString(),
            'image': (p['image_url'] ?? '').toString(),
            'product_id': p['product_id'],
            'rating': p['rating_avg'],
            'reviews': p['review_count'],
            'stock': p['stock_quantity'],
            'isDb': true,
          },
        )
        .toList();

    // Filter by selected category if any
    final combined = [...dbMapped, ...adminMapped];
    if (_selectedCategory != null) {
      return combined.where((p) => p['category'] == _selectedCategory).toList();
    }
    return combined;
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0;
  }

  List<Map<String, dynamic>> get _paginatedProducts {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final products = _allProducts;
    return products.sublist(
      startIndex,
      endIndex > products.length ? products.length : endIndex,
    );
  }

  void _openProductDetails(Map<String, dynamic> item, int index) {
    final isDb = item['isDb'] == true;
    final images = ((item['image'] ?? '') as String).isNotEmpty
        ? [item['image'] as String]
        : <String>[];

    final product = ProductData(
      id: isDb
          ? '${item['product_id']}'
          : 'admin_${widget.collectionSlug}_$index',
      name: item['title'] as String,
      category: (item['category'] ?? 'General') as String,
      priceBDT: (item['price'] as double),
      images: images,
      description: '${widget.collectionName} product',
      additionalInfo: {
        if ((item['rating'] ?? '') != '') 'rating': '${item['rating']}',
        if ((item['reviews'] ?? '') != '') 'review_count': '${item['reviews']}',
        if ((item['stock'] ?? '') != '') 'stock_quantity': '${item['stock']}',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 768;
          final content = _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _error != null
              ? _buildErrorState()
              : _buildProductsGrid(isNarrow: isNarrow);

          return SingleChildScrollView(
            child: Column(
              children: [
                const Header(),
                if (isNarrow)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 12 : 24,
                      vertical: isNarrow ? 12 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMobileFilterToggle(),
                        if (_mobileFiltersOpen) ...[
                          const SizedBox(height: 12),
                          _buildFilterPanel(isNarrow: true),
                          const SizedBox(height: 16),
                        ] else
                          const SizedBox(height: 16),
                        content,
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar categories panel
                        SizedBox(
                          width: 280,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: _buildCategoriesFilter(isNarrow: false),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Main content
                        Expanded(child: content),
                      ],
                    ),
                  ),
                const FooterSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel({bool isNarrow = false}) {
    return SingleChildScrollView(
      scrollDirection: isNarrow ? Axis.horizontal : Axis.vertical,
      padding: EdgeInsets.all(isNarrow ? 12 : 20),
      child: _buildCategoriesFilter(isNarrow: isNarrow),
    );
  }

  Widget _buildMobileFilterToggle() {
    return OutlinedButton.icon(
      onPressed: () => setState(() => _mobileFiltersOpen = !_mobileFiltersOpen),
      icon: Icon(_mobileFiltersOpen ? Icons.close : Icons.tune, size: 18),
      label: Text(_mobileFiltersOpen ? 'Hide Filters' : 'Show Filters'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCategoriesFilter({bool isNarrow = false}) {
    // Get categories based on collection
    final categories = _getCategoriesForCollection();

    final chips = categories.map((cat) {
      final selected = _selectedCategory == cat;
      return Padding(
        padding: EdgeInsets.only(
          right: isNarrow ? 8 : 0,
          bottom: isNarrow ? 0 : 12,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = selected ? null : cat;
              _currentPage = 1;
              // Don't call _loadProducts() here - just update UI
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.red.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.04),
              border: Border.all(
                color: selected ? Colors.red.shade300 : Colors.grey.shade200,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected ? Colors.red.shade700 : Colors.black87,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.red.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_getCountForCategory(cat)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return isNarrow
        ? Row(children: chips)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Filter by category',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ...chips,
            ],
          );
  }

  List<String> _getCategoriesForCollection() {
    // Return categories based on collection name
    switch (widget.collectionSlug) {
      case 'fans':
        return ['Charger Fan', 'Mini Hand Fan'];
      case 'cookers':
        return ['Rice Cooker', 'Mini Cooker', 'Curry Cooker'];
      case 'blenders':
        return ['Hand Blender', 'Blender'];
      case 'phone-related':
        return ['Telephone Set', 'Sim Telephone'];
      case 'massager-items':
        return ['Massage Gun', 'Head Massage'];
      default:
        return [widget.collectionName];
    }
  }

  int _getCountForCategory(String category) {
    return _allProducts
        .where((p) => (p['category'] ?? '').toString() == category)
        .length;
  }

  Widget _buildProductsGrid({required bool isNarrow}) {
    final gridCount = isNarrow ? 2 : 4;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isNarrow ? 0 : 24),
      child: Column(
        children: [
          // Header with view toggle and sort
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(widget.icon, size: 22, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.collectionName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage - 1) * _itemsPerPage + _paginatedProducts.length} of ${_allProducts.length} result',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'Showing ${(_currentPage - 1) * _itemsPerPage + 1} - ${(_currentPage - 1) * _itemsPerPage + _paginatedProducts.length} of ${_allProducts.length} result',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 24),
                    Icon(widget.icon, size: 24, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.collectionName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildSortPill(),
                  ],
                ),
          if (isNarrow) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: _buildSortPill()),
          ],
          const SizedBox(height: 24),

          // Products Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              childAspectRatio: isNarrow ? 0.60 : 0.95,
              crossAxisSpacing: isNarrow ? 10 : 16,
              mainAxisSpacing: isNarrow ? 10 : 16,
            ),
            itemCount: _paginatedProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(_paginatedProducts[index], index),
          ),

          // Pagination
          const SizedBox(height: 32),
          if (_totalPages > 1)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                  color: _currentPage > 1 ? Colors.grey : Colors.grey[300],
                ),
                if (_totalPages <= 7) ...[
                  ...List.generate(_totalPages, (index) {
                    final pageNum = index + 1;
                    return _pageButton(pageNum);
                  }),
                ] else ...[
                  _pageButton(1),
                  if (_currentPage > 3)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('...'),
                    ),
                  ...List.generate(_maxPagesToShow, (index) {
                    final start = (_currentPage - 2).clamp(2, _totalPages - 4);
                    final pageNum = start + index;
                    if (pageNum >= _totalPages) return const SizedBox.shrink();
                    return _pageButton(pageNum);
                  }),
                  if (_currentPage < _totalPages - 2)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('...'),
                    ),
                  _pageButton(_totalPages),
                ],
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                  color: _currentPage < _totalPages
                      ? Colors.grey
                      : Colors.grey[300],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSortPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort By:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          const Text(
            'Alphabetically, A-Z',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _pageButton(int pageNum) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = pageNum;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _currentPage == pageNum ? Colors.red : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$pageNum',
            style: TextStyle(
              color: _currentPage == pageNum ? Colors.white : Colors.black,
              fontWeight: _currentPage == pageNum
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load products',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final stock = product['stock'] ?? 0;
    final stockQuantity = stock is int
        ? stock
        : (stock is String ? int.tryParse(stock.toString()) ?? 0 : 0);
    final isInStock = stockQuantity > 0;

    return InkWell(
      onTap: () => _openProductDetails(product, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color.fromARGB(255, 187, 108, 108),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Stock Badge
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: (product['image'] ?? '').toString().isNotEmpty
                        ? OptimizedImageWidget(
                            imageUrl: product['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                  ),
                  // Stock Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isInStock ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isInStock ? 'In Stock' : 'Stock Out',
                        style: const TextStyle(
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

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product['title'] ?? 'Product',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Star Rating
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 12,
                        color: i < 4 ? Colors.orange : Colors.grey[300],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '৳${(product['price'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Stock Quantity
                  if (isInStock)
                    Text(
                      '$stockQuantity items available',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    )
                  else
                    Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
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
}

