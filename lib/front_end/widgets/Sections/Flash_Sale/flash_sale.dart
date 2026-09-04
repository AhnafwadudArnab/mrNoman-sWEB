import 'dart:ui';

import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../All_Pages/CART/Cart_provider.dart';
import '../../../Dimensions/responsive_dimensions.dart';
import '../../../Provider/Admin_product_provider.dart';
import '../../../Provider/api_ready_notifier.dart';
import '../../../Provider/product_refresh_notifier.dart';
import '../../../pages/Templates/Dyna_products.dart';
import '../../../pages/Templates/all_products_template.dart';
import '../../../utils/api_service.dart';
import '../../../utils/image_resolver.dart';
import '../../../utils/optimized_image_widget.dart';
import 'Flash_Sale_all.dart';

class FlashSaleItem {
  final String image;
  final String title;
  final int originalPrice;
  final int discountedPrice;
  final String timeRemaining;

  FlashSaleItem({
    required this.image,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.timeRemaining,
  });
}

class FlashSaleCarousel extends StatefulWidget {
  const FlashSaleCarousel({super.key});

  @override
  State<FlashSaleCarousel> createState() => _FlashSaleCarouselState();
}

class _FlashSaleCarouselState extends State<FlashSaleCarousel> {
  List<FlashSaleItem> _dbFlashItems = [];
  List<Map<String, dynamic>> _dbFlashProducts = [];

  bool _loadTriggered = false;
  int _lastRefreshVersion = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger load the first time the API is marked ready.
    // Using watch so this re-runs when ApiReadyNotifier fires.
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

  Future<void> _loadFromDb() async {
    try {
      final res = await ApiService.getProducts(
        section: 'flash-sale',
        limit: 20,
        useCache: true,
      );
      final List<dynamic> list;
      if (res is Map<String, dynamic>) {
        list = (res['products'] as List<dynamic>?) ?? [];
      } else if (res is List) {
        list = res;
      } else {
        list = [];
      }
      final maps = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (mounted) {
        setState(() {
          _dbFlashProducts = maps;
          _dbFlashItems = maps.map((p) {
            final price = _parsePrice(p['flash_price'] ?? p['price']);
            final origPrice = _parsePrice(p['price']);
            return FlashSaleItem(
              image: ImageResolver.resolveUrl(p['image_url'] as String? ?? ''),
              title: p['product_name'] ?? '',
              originalPrice: origPrice.toInt(),
              discountedPrice: price.toInt(),
              timeRemaining: '23:59:59',
            );
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  // ???????? ????????? (??????)
  final List<FlashSaleItem> sampleProducts = [
    FlashSaleItem(
      image: 'assets/flash/av.jpg',
      title: 'Product 1',
      originalPrice: 1500,
      discountedPrice: 999,
      timeRemaining: '02:12:34',
    ),
    FlashSaleItem(
      image: 'assets/flash/handmixxer.jpg',
      title: 'Product 2',
      originalPrice: 2000,
      discountedPrice: 1299,
      timeRemaining: '01:45:20',
    ),
    FlashSaleItem(
      image: 'assets/flash/kennede.jpg',
      title: 'Product 3',
      originalPrice: 1200,
      discountedPrice: 799,
      timeRemaining: '03:30:15',
    ),
    FlashSaleItem(
      image: 'assets/flash/miyoko_kettle.jpg',
      title: 'Product 4',
      originalPrice: 1800,
      discountedPrice: 1199,
      timeRemaining: '02:00:45',
    ),
    FlashSaleItem(
      image: 'assets/flash/nima_grinder.jpg',
      title: 'Product 5',
      originalPrice: 1600,
      discountedPrice: 999,
      timeRemaining: '04:15:30',
    ),
    FlashSaleItem(
      image: 'assets/BestSale/electric kettle.jpg',
      title: 'Electric Kettle',
      originalPrice: 2500,
      discountedPrice: 1699,
      timeRemaining: '01:30:00',
    ),
    FlashSaleItem(
      image: 'assets/BestSale/grinder 400w.jpg',
      title: 'Grinder 400W',
      originalPrice: 1800,
      discountedPrice: 1299,
      timeRemaining: '02:45:15',
    ),
  ];

  static double _parsePrice(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0;
  }

  // ???????? ??????????? FlashSaleItem-? ??????? ???
  List<FlashSaleItem> _convertAdminProducts(
    List<Map<String, dynamic>> adminProducts,
  ) {
    return adminProducts.map((p) {
      final price = _parsePrice(p['price']);
      final discountedPrice = (price * 0.8)
          .toInt(); // 20% ????????? (??? ?????)

      return FlashSaleItem(
        image: p['bytes'] != null
            ? 'admin_image_${p['name']}'
            : 'assets/placeholder.png',
        title: p['name'] ?? '',
        originalPrice: price.toInt(),
        discountedPrice: discountedPrice,
        timeRemaining: '23:59:59', // ?????? ???
      );
    }).toList();
  }

  ProductData _buildProductData(
    dynamic product,
    int index, {
    bool isFromAdmin = false,
  }) {
    if (isFromAdmin) {
      final price = _parsePrice(product['price']);
      final stockQty =
          int.tryParse(
            product['stock_quantity']?.toString() ??
                product['stock']?.toString() ??
                '0',
          ) ??
          0;
      final adminImages =
          product['imageUrl'] != null &&
              (product['imageUrl'] as String).isNotEmpty
          ? [product['imageUrl'] as String]
          : <String>[];
      return ProductData(
        id: 'admin_flash_$index',
        name: product['name'] ?? '',
        category: 'Flash_Sale',
        priceBDT: price,
        images: adminImages,
        description: product['desc'] ?? '',
        additionalInfo: {
          'Category': product['category'] ?? '',
          'stock_quantity': stockQty.toString(),
        },
      );
    } else {
      return ProductData(
        id: 'flash_$index',
        name: product.title,
        category: 'Flash_Sale',
        priceBDT: product.discountedPrice.toDouble(),
        images: [product.image],
        description: 'Limited time Flash_Sale deal.',
        additionalInfo: {
          'Original Price': 'Tk ${product.originalPrice}',
          'Time Remaining': product.timeRemaining,
          'stock_quantity': '10',
        },
      );
    }
  }

  void _openDetails(
    BuildContext context,
    dynamic product,
    int index, {
    bool isFromAdmin = false,
  }) {
    final details = _buildProductData(product, index, isFromAdmin: isFromAdmin);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalProductDetails(product: details),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProducts = Provider.of<AdminProductProvider>(
      context,
    ).getProductsBySection("Flash_Sale");
    final adminFlashItems = _convertAdminProducts(adminProducts);
    // Only show sample products if no DB products AND no admin products exist
    final hasRealProducts =
        _dbFlashItems.isNotEmpty || adminFlashItems.isNotEmpty;
    final allProducts = hasRealProducts
        ? [..._dbFlashItems, ...adminFlashItems]
        : [...sampleProducts];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Flash_Sale',
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FlashSaleAll(breadcrumbLabel: 'Flash_Sale'),
                  ),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.padding(context) * 0.3,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimensions.padding(context) * 0.5),
                decoration: BoxDecoration(
                  color: const Color(0x38212121),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: SizedBox(
                  height: 230,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final product = allProducts[index];
                      final isFromDb = index < _dbFlashItems.length;
                      final isFromAdmin =
                          !isFromDb &&
                          index < _dbFlashItems.length + adminFlashItems.length;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (isFromDb) {
                              final p = _dbFlashProducts[index];
                              final pd = ProductData(
                                id: '${p['product_id']}',
                                name: p['product_name'] ?? '',
                                category: 'Flash_Sale',
                                priceBDT: _parsePrice(p['price']),
                                images:
                                    (p['image_url'] != null &&
                                        (p['image_url'] as String).isNotEmpty)
                                    ? [p['image_url'] as String]
                                    : [],
                                description: p['description'] ?? '',
                                additionalInfo: {
                                  'Brand': p['brand_name'] ?? '',
                                  'stock_quantity':
                                      (int.tryParse(
                                                p['stock_quantity']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              0)
                                          .toString(),
                                  if (p['rating_avg'] != null)
                                    'rating': '${p['rating_avg']}',
                                  if (p['review_count'] != null)
                                    'review_count': '${p['review_count']}',
                                },
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UniversalProductDetails(product: pd),
                                ),
                              );
                            } else {
                              _openDetails(
                                context,
                                isFromAdmin
                                    ? adminProducts[index -
                                          _dbFlashItems.length]
                                    : product,
                                index,
                                isFromAdmin: isFromAdmin,
                              );
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Glass-style panel
                              Positioned(
                                top: 16,
                                left: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      width: 190,
                                      height: 195,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Main product card
                              Container(
                                width: 190,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color.fromARGB(
                                      255,
                                      98,
                                      169,
                                      216,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child: isFromDb
                                                ? OptimizedImageWidget(
                                                    imageUrl: product.image,
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            12,
                                                          ),
                                                        ),
                                                  )
                                                : isFromAdmin
                                                ? (adminProducts[index -
                                                              _dbFlashItems
                                                                  .length]['bytes'] !=
                                                          null
                                                      ? Image.memory(
                                                          adminProducts[index -
                                                              _dbFlashItems
                                                                  .length]['bytes']!,
                                                          fit: BoxFit.contain,
                                                          width:
                                                              double.infinity,
                                                          height:
                                                              double.infinity,
                                                        )
                                                      : (adminProducts[index -
                                                                        _dbFlashItems
                                                                            .length]['imageUrl'] !=
                                                                    null &&
                                                                (adminProducts[index -
                                                                            _dbFlashItems.length]['imageUrl']
                                                                        as String)
                                                                    .isNotEmpty
                                                            ? OptimizedImageWidget(
                                                                imageUrl:
                                                                    adminProducts[index -
                                                                            _dbFlashItems.length]['imageUrl']
                                                                        as String,
                                                                fit: BoxFit
                                                                    .contain,
                                                                width: double
                                                                    .infinity,
                                                                height: double
                                                                    .infinity,
                                                              )
                                                            : Container(
                                                                color: Colors
                                                                    .grey[300],
                                                                child:
                                                                    const Icon(
                                                                      Icons
                                                                          .image,
                                                                    ),
                                                              )))
                                                : OptimizedImageWidget(
                                                    imageUrl: product.image,
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                          ),
                                          if (isFromAdmin)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
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
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Product Title
                                            Flexible(
                                              child: Text(
                                                isFromAdmin
                                                    ? adminProducts[index]['product_name'] ??
                                                          adminProducts[index]['name'] ??
                                                          ''
                                                    : product.title,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Original Price & Discounted Price
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    isFromAdmin
                                                        ? 'Tk ${adminProducts[index]['price'] ?? ''}'
                                                        : 'Tk ${product.originalPrice}',
                                                    style: const TextStyle(
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                        color: Colors.black,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    isFromAdmin
                                                        ? 'Tk ${_getDiscountedPrice(adminProducts[index]['price'])}'
                                                        : 'Tk ${product.discountedPrice}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Time Remaining with Add button
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.timer,
                                                        size: 12,
                                                        color: Colors.orange,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          isFromAdmin
                                                              ? '23:59:59'
                                                              : product
                                                                    .timeRemaining,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .orange,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  height: 24,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      final data =
                                                          _buildProductData(
                                                            isFromAdmin
                                                                ? adminProducts[index]
                                                                : product,
                                                            index,
                                                            isFromAdmin:
                                                                isFromAdmin,
                                                          );
                                                      await context
                                                          .read<CartProvider>()
                                                          .addToCart(
                                                            productId: data.id,
                                                            name: data.name,
                                                            price:
                                                                data.priceBDT,
                                                            imageUrl:
                                                                data
                                                                    .images
                                                                    .isNotEmpty
                                                                ? data
                                                                      .images
                                                                      .first
                                                                : '',
                                                            category:
                                                                data.category,
                                                          );

                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              '${data.name} added to cart',
                                                            ),
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      900,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.orange,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      minimumSize: const Size(
                                                        0,
                                                        24,
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Add',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getDiscountedPrice(String? priceStr) {
    final price =
        double.tryParse(priceStr?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ??
        0;
    return (price * 0.8).toStringAsFixed(0);
  }
}


