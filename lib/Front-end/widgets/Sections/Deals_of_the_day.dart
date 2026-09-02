import 'dart:async';

import 'package:electrocitybd1/Front-end/pages/Templates/Dyna_products.dart';
import 'package:electrocitybd1/Front-end/pages/Templates/all_products_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../All Pages/CART/Cart_provider.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Admin_product_provider.dart';
import '../../Provider/api_ready_notifier.dart';
import '../../Provider/product_refresh_notifier.dart';
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';

class DealsOfTheDay extends StatefulWidget {
  const DealsOfTheDay({super.key});

  @override
  State<DealsOfTheDay> createState() => _DealsOfTheDayState();
}

class _DealsOfTheDayState extends State<DealsOfTheDay> {
  Timer? _timer;
  Timer? _autoRefreshTimer;
  late ScrollController _scrollController;
  List<Map<String, dynamic>> _dbDeals = [];
  Duration _remaining = const Duration(days: 3, hours: 11, minutes: 15);
  bool _isTimerActive = true;
  bool _isLoadingDeals = true;
  String? _loadError;
  DateTime? _lastDealsSyncAt;

  bool _loadTriggered = false;
  int _lastRefreshVersion = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scheduleAutoRefresh();
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
      _loadDealsFromDb();
      _loadTimerFromApi();
    } else if (_loadTriggered && refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = refreshVersion;
      _loadDealsFromDb();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    // Auto-refresh every 30 seconds to catch new deals/timer updates quickly
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDealsFromDb(silent: true);
      _loadTimerFromApi(silent: true);
    });
  }

  Future<void> _loadDealsFromDb({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoadingDeals = true;
        _loadError = null;
      });
    }

    try {
      // Don't use cache for automatic refreshes to catch new deals quickly
      // Only use cache for manual user refreshes
      final List<dynamic> dealsList = await ApiService.getDeals(
        limit: 24,
        useCache:
            silent, // Use cache only for silent auto-refreshes, not initial load
      );

      if (mounted) {
        setState(() {
          _dbDeals = dealsList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoadingDeals = false;
          _loadError = null;
          _lastDealsSyncAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDeals = false;
          _loadError = 'Could not refresh deals right now.';
        });
      }
      debugPrint('Error loading deals: $e');
    }
  }

  Future<void> _loadTimerFromApi({bool silent = false}) async {
    try {
      // Use _withReprobeBase directly to avoid trailing slash issue
      final data = await ApiService.get('/deals_timer', withAuth: false);

      if (data is Map && data['success'] == true) {
        Map<String, dynamic>? activeTimer;

        final timersList = data['timers'];
        if (timersList is List && timersList.isNotEmpty) {
          // Find the FIRST active timer
          for (final t in timersList) {
            if (_parseBool(t['is_active'])) {
              activeTimer = Map<String, dynamic>.from(t as Map);
              break;
            }
          }
          // If no active timer found, use the first one but mark as inactive
          if (activeTimer == null) {
            activeTimer = Map<String, dynamic>.from(timersList.first as Map);
            activeTimer['is_active'] = false;
          }
        } else if (data['timer'] != null) {
          activeTimer = Map<String, dynamic>.from(data['timer'] as Map);
        }

        if (activeTimer != null && mounted) {
          final isActive = _parseBool(activeTimer['is_active']);
          Duration remaining;

          final rawEndTime = activeTimer['end_time']?.toString() ?? '';
          if (rawEndTime.isNotEmpty && rawEndTime != 'null') {
            final isoString = rawEndTime.replaceFirst(' ', 'T');
            final endDt = DateTime.tryParse(isoString);
            if (endDt != null) {
              final diff = endDt.difference(DateTime.now());
              remaining = diff.isNegative ? Duration.zero : diff;
            } else {
              remaining = _durationFromFields(activeTimer);
            }
          } else {
            remaining = _durationFromFields(activeTimer);
          }

          setState(() {
            _remaining = remaining;
            // Only active if timer is marked active AND has remaining time
            _isTimerActive = isActive && remaining.inSeconds > 0;
          });

          if (_isTimerActive) {
            _startCountdown();
          } else {
            _timer?.cancel();
          }
          return;
        }
      }
      _useDefaultTimer(silent: silent);
    } catch (e) {
      debugPrint('⚠️ Timer load failed: $e');
      _useDefaultTimer(silent: silent);
    }
  }

  Duration _durationFromFields(Map<String, dynamic> t) {
    return Duration(
      days: int.tryParse(t['days']?.toString() ?? '') ?? 0,
      hours: int.tryParse(t['hours']?.toString() ?? '') ?? 0,
      minutes: int.tryParse(t['minutes']?.toString() ?? '') ?? 0,
      seconds: int.tryParse(t['seconds']?.toString() ?? '') ?? 0,
    );
  }

  void _useDefaultTimer({bool silent = false}) {
    if (mounted) {
      setState(() {
        _remaining = const Duration(days: 3, hours: 11, minutes: 15);
        _isTimerActive = true;
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Defer setState to avoid triggering a rebuild during Flutter's
      // mouse-tracker device-update phase (causes assertion on web).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (_remaining.inSeconds > 0) {
            _remaining = _remaining - const Duration(seconds: 1);
          } else {
            _timer?.cancel();
          }
        });
      });
    });
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return true;
  }

  static double _parsePrice(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  ProductData _buildProductDataFromDb(Map<String, dynamic> p, int index) {
    final price = _parsePrice(p['price']);
    final oldPrice = price * 1.15;
    final imageUrl = ImageResolver.resolveUrl(p['image_url'] as String? ?? '');
    final stockQty = int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;

    return ProductData(
      id: 'deal_db_${p['product_id'] ?? index}',
      name: p['product_name'] ?? '',
      category: 'Deals of the Day',
      priceBDT: price,
      images: imageUrl.isNotEmpty ? [imageUrl] : [],
      description: p['description'] ?? '',
      additionalInfo: {
        'Brand': p['brand_name'] ?? '',
        'Old Price': '৳${oldPrice.toStringAsFixed(0)}',
        'stock_quantity': stockQty.toString(),
        if (p['rating_avg'] != null) 'rating': '${p['rating_avg']}',
        if (p['review_count'] != null) 'review_count': '${p['review_count']}',
      },
    );
  }

  ProductData _buildProductDataFromAdmin(Map<String, dynamic> p, int index) {
    final price = _parsePrice(p['price']);
    final oldPrice = price * 1.15;
    final stockQty =
        int.tryParse(
          p['stock_quantity']?.toString() ?? p['stock']?.toString() ?? '0',
        ) ??
        0;
    final images = <String>[];
    if (p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty) {
      images.add(ImageResolver.resolveUrl(p['imageUrl'] as String));
    }
    return ProductData(
      id: 'deal_admin_$index',
      name: p['name'] ?? '',
      category: 'Deals of the Day',
      priceBDT: price,
      images: images,
      description: p['desc'] ?? '',
      additionalInfo: {
        'Category': p['category'] ?? '',
        'Old Price': '৳${oldPrice.toStringAsFixed(0)}',
        'stock_quantity': stockQty.toString(),
      },
    );
  }

  void _openDetails(ProductData product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalProductDetails(product: product),
      ),
    );
  }

  Future<void> _scrollBy(double delta) async {
    if (!_scrollController.hasClients) return;

    final min = _scrollController.position.minScrollExtent;
    final max = _scrollController.position.maxScrollExtent;
    final next = (_scrollController.offset + delta).clamp(min, max);

    try {
      await _scrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (_) {
      _scrollController.jumpTo(next);
    }
  }

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  String _syncLabel() {
    final at = _lastDealsSyncAt;
    if (at == null) return 'Syncing...';
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    return 'Updated ${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    final adminDeals = context
        .watch<AdminProductProvider>()
        .getProductsBySection('Deals of the Day');
    final hasOffers = _dbDeals.isNotEmpty || adminDeals.isNotEmpty;
    final r = AppResponsive.of(context);
    final isMobileView = r.isMobile || r.isSmallMobile;

    // Auto-hide section if timer expired and no deals
    final timerExpired = _remaining.inSeconds <= 0;
    final shouldHide = timerExpired && !hasOffers;

    if (!hasOffers && _isLoadingDeals) {
      return Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Hide section completely if timer expired and no active deals
    if (shouldHide) {
      return const SizedBox.shrink();
    }

    // Also hide if timer not active and no deals
    if (!_isTimerActive && !hasOffers) {
      return const SizedBox.shrink();
    }

    if (!hasOffers) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Deals of the Day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: _isTimerActive
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _timeBox(twoDigits(days), 'Days'),
                                    const SizedBox(width: 8),
                                    _timeBox(twoDigits(hours), 'Hours'),
                                    const SizedBox(width: 8),
                                    _timeBox(twoDigits(minutes), 'Min'),
                                    const SizedBox(width: 8),
                                    _timeBox(twoDigits(seconds), 'Sec'),
                                  ],
                                )
                              : const Text(
                                  'Offer Ended',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobileView) ...[
                  const SizedBox(width: 8),
                  _navButton(Icons.arrow_back_ios, () => _scrollBy(-320)),
                  const SizedBox(width: 8),
                  _navButton(Icons.arrow_forward_ios, () => _scrollBy(320)),
                  const SizedBox(width: 8),
                  _navButton(Icons.refresh, () {
                    _loadDealsFromDb();
                    _loadTimerFromApi();
                  }),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _syncLabel(),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product cards list (admin products first, then static deals)
            SizedBox(
              height: 120,
              child: Builder(
                builder: (context) {
                  final List<Widget> cards = [];

                  for (var i = 0; i < _dbDeals.length; i++) {
                    final p = _dbDeals[i];
                    final priceVal = _parsePrice(p['price']);
                    final dealPrice = _parsePrice(
                      p['deal_price'] ?? p['price'],
                    );
                    final imageUrl = ImageResolver.resolveUrl(
                      p['image_url'] as String? ?? '',
                    );
                    final productData = _buildProductDataFromDb(p, i);
                    cards.add(
                      _productCard(
                        brand: p['brand_name'] ?? 'Deal',
                        title: p['product_name'] ?? '',
                        price: '৳${dealPrice.toStringAsFixed(0)}',
                        oldPrice: '৳${priceVal.toStringAsFixed(0)}',
                        imagePath: '',
                        onTap: () => _openDetails(productData),
                        imageWidget: imageUrl.isNotEmpty
                            ? ImageResolver.image(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              )
                            : null,
                        onAddToCart: () async {
                          await context.read<CartProvider>().addToCart(
                            productId: productData.id,
                            name: productData.name,
                            price: dealPrice,
                            imageUrl: productData.images.isNotEmpty
                                ? productData.images.first
                                : '',
                            category: productData.category,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${productData.name} added to cart',
                              ),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  for (var i = 0; i < adminDeals.length; i++) {
                    final p = adminDeals[i];
                    final priceVal = _parsePrice(p['price']);
                    final oldPriceVal = priceVal * 1.15;
                    Widget? imageWidget;
                    if (p['bytes'] != null) {
                      imageWidget = Image.memory(
                        p['bytes']!,
                        fit: BoxFit.cover,
                      );
                    } else if (p['imageUrl'] != null &&
                        (p['imageUrl'] as String).isNotEmpty) {
                      imageWidget = Image.network(
                        ImageResolver.resolveUrl(p['imageUrl'] as String),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      );
                    }
                    final productData = _buildProductDataFromAdmin(p, i);
                    cards.add(
                      _productCard(
                        brand: p['category'] ?? 'Deal',
                        title: p['name'] ?? '',
                        price: '৳${priceVal.toStringAsFixed(0)}',
                        oldPrice: '৳${oldPriceVal.toStringAsFixed(0)}',
                        imagePath: '',
                        onTap: () => _openDetails(productData),
                        imageWidget: imageWidget,
                        onAddToCart: () async {
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
                              content: Text(
                                '${productData.name} added to cart',
                              ),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  // All products loaded from database and admin provider
                  return ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    children: cards,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _timeBox(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54)),
      ],
    );
  }

  static Widget _navButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF123456),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _productCard({
    required String brand,
    required String title,
    required String price,
    required String oldPrice,
    String? badge,
    required String imagePath,
    required VoidCallback onTap,
    Widget? imageWidget,
    VoidCallback? onAddToCart,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 310,
        height: 104,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color.fromARGB(255, 207, 150, 65),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child:
                    imageWidget ??
                    (imagePath.isNotEmpty
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          )
                        : const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    brand,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF123456),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          oldPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  onAddToCart ??
                  () async {
                    final productId = title
                        .toLowerCase()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                        .replaceAll(RegExp(r'^-|-$'), '');

                    await context.read<CartProvider>().addToCart(
                      productId: 'deal-$productId',
                      name: title,
                      price: _parsePrice(price),
                      imageUrl: imagePath,
                      category: 'Deals of the Day',
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title added to cart'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              color: const Color(0xFF123456),
              tooltip: 'Add to cart',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            ),
          ],
        ),
      ),
    );
  }
}
