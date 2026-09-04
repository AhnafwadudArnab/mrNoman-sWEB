import 'package:electrocitybd1/front_end/pages/Profiles/WishLists.dart';
import 'package:electrocitybd1/front_end/pages/Profiles/Wishlist_provider.dart';
import 'package:electrocitybd1/front_end/pages/home_page.dart';
import 'package:electrocitybd1/front_end/utils/auth_session.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import '../All_Pages/CART/Cart_provider.dart';
import '../All_Pages/CART/Orders.dart';
import '../All_Pages/Registrations/login.dart';
import '../utils/image_resolver.dart';
import '../Provider/api_ready_notifier.dart';
import '../Provider/product_refresh_notifier.dart';
import '../pages/Templates/all_products_template.dart';
import '../utils/api_service.dart';
import '../utils/search_history.dart';
import 'SearchRes.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(124); // Large enough to accommodate expanded search

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductData> _allProducts = [];
  bool _productsLoaded = false;
  bool _loadTriggered = false;
  int _lastRefreshVersion = -1;
  bool _isLoggedIn = false;
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;
  bool _isSearchExpanded = false; // New state for mobile search dropdown
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _refreshAuthState();
    _loadSearchHistory();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() => _showSearchHistory = true);
    }
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistory.getHistory();
    setState(() => _searchHistory = history);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ready = context.watch<ApiReadyNotifier>().isReady;
    final refreshVersion = context.watch<ProductRefreshNotifier>().version;

    if (ready && !_loadTriggered) {
      _loadTriggered = true;
      _lastRefreshVersion = refreshVersion;
      _loadProducts();
    } else if (_loadTriggered && refreshVersion != _lastRefreshVersion) {
      _lastRefreshVersion = refreshVersion;
      _productsLoaded = false;
      ApiService.invalidateCache('/products');
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshAuthState() async {
    final loggedIn = await AuthSession.isLoggedIn();
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

  Future<void> _loadProducts() async {
    try {
      final res = await ApiService.getProducts(limit: 500, useCache: true);
      final List<dynamic> productList = res is Map
          ? (res['products'] as List?) ?? []
          : (res is List ? res : []);

      final products = productList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);

        // Handle price - can be string or number
        double price = 0.0;
        final priceVal = map['price'];
        if (priceVal is num) {
          price = priceVal.toDouble();
        } else if (priceVal is String) {
          price = double.tryParse(priceVal) ?? 0.0;
        }

        return ProductData(
          id: map['product_id']?.toString() ?? '0',
          name: map['product_name']?.toString() ?? '',
          category: map['category_name']?.toString() ?? '',
          priceBDT: price,
          images: [
            if (map['image_url'] != null)
              ImageResolver.resolveUrl(map['image_url'].toString()),
          ],
          description: map['description']?.toString() ?? '',
          additionalInfo: {},
        );
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = products;
          _productsLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _productsLoaded = true);
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) return;

    // Save to history
    await SearchHistory.addSearch(query);

    try {
      // Try to use cached products first
      var products = _productsLoaded && _allProducts.isNotEmpty
          ? _allProducts
          : <ProductData>[];

      // If no cached products, fetch from API
      if (products.isEmpty) {
        final res = await ApiService.getProducts(
          limit: 500,
          search: query,
          useCache: false,
        );
        final List<dynamic> productList = res is Map
            ? (res['products'] as List?) ?? []
            : (res is List ? res : []);

        products = productList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);

          // Handle price - can be string or number
          double price = 0.0;
          final priceVal = map['price'];
          if (priceVal is num) {
            price = priceVal.toDouble();
          } else if (priceVal is String) {
            price = double.tryParse(priceVal) ?? 0.0;
          }

          return ProductData(
            id: map['product_id']?.toString() ?? '0',
            name: map['product_name']?.toString() ?? '',
            category: map['category_name']?.toString() ?? '',
            priceBDT: price,
            images: [
              if (map['image_url'] != null)
                ImageResolver.resolveUrl(map['image_url'].toString()),
            ],
            description: map['description']?.toString() ?? '',
            additionalInfo: {},
          );
        }).toList();
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SearchResultsPage(query: query, allProducts: products),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSearchField({required bool isSmall}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            focusNode: isSmall ? null : _searchFocusNode,
            onChanged: (val) => setState(() {
              _showSearchHistory =
                  val.isEmpty && (isSmall || _searchFocusNode.hasFocus);
            }),
            decoration: InputDecoration(
              hintText: 'Search for gadgets...',
              hintStyle: TextStyle(
                color: const Color(0x66000000),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: const Color(0x4D000000),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
            onSubmitted: (query) {
              _onSearch(query);
              if (isSmall) setState(() => _isSearchExpanded = false);
            },
          ),
        ),
        // Search history dropdown
        if (_showSearchHistory && _searchHistory.isNotEmpty)
          Positioned(
            top: 45,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.grey300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x26000000),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._searchHistory
                      .take(5)
                      .map(
                        (query) => InkWell(
                          onTap: () {
                            _searchController.text = query;
                            _showSearchHistory = false;
                            if (isSmall)
                              setState(() => _isSearchExpanded = false);
                            _onSearch(query);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.grey300),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Color(0xFFCCCCCC),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    query,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.grey300,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await SearchHistory.removeSearch(query);
                                    _loadSearchHistory();
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Color(0xFFDDDDDD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  if (_searchHistory.length > 5)
                    InkWell(
                      onTap: () async {
                        await SearchHistory.clearHistory();
                        _loadSearchHistory();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        width: double.infinity,
                        child: const Text(
                          'Clear history',
                          style: TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openCart(BuildContext context) {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }
    final cartTotal = cart.getCartTotal();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubmitOrderPage(totalAmount: cartTotal),
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to profile - use deferred import to avoid circular dependency
    Future.microtask(() async {
      if (!mounted) return;
      try {
        // Use string-based route if app supports it, otherwise use lazy loading
        // For now, we'll use a simple workaround by loading the module conditionally
        final profile = await _loadProfileModule();
        if (profile != null && mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => profile));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to load profile')),
          );
        }
      }
    });
  }

  Future<Widget?> _loadProfileModule() async {
    try {
      // Dynamic import using Type.fromString pattern
      // This is a workaround for circular imports
      const modulePath =
          'package:electrocitybd1/front_end/pages/Profiles/Profile';

      // Since Dart doesn't support dynamic imports at runtime easily,
      // we create a factory pattern. The Profile page should be accessible
      // through a factory or provider. For now, return null to defer loading.
      // This would be better solved with dependency injection.
      return null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int count = 0,
    bool showLabel = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -8, end: -8),
              badgeContent: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: count > 0,
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.black,
                padding: EdgeInsets.all(4),
                elevation: 0,
              ),
              child: Icon(icon, color: Colors.black, size: 22),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width <= 768;
    final isMobile = width <= 480;
    final cartCount = context.watch<CartProvider>().getItemCount();
    final wishlistCount = context.watch<WishlistProvider>().wishlistCount;

    return AppBar(
      backgroundColor: const Color(0xFFFAB12F),
      elevation: 4,
      shadowColor: const Color(0x1A000000),
      titleSpacing: 0,
      toolbarHeight: _isSearchExpanded && isSmall ? 124 : 64,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAB12F), Color(0xFFFAB12F), Color(0xFFFAB12F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Logo & Brand Name (Wrapped in Flexible to prevent overflow)
                Flexible(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: isMobile ? 24 : (isSmall ? 32 : 42),
                            width: isMobile ? 24 : (isSmall ? 32 : 42),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                isMobile ? 4 : 10,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Image.asset(
                              'assets/elogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.electric_bolt,
                                color: const Color(0xFFFAB12F),
                                size: isMobile ? 14 : 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ElectroZoneBD',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: isMobile ? 13 : 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Spacer only on larger screens to push icons to the right
                if (!isSmall) const Spacer(),

                // Search bar - Hidden on mobile/small tablets
                if (!isSmall)
                  Container(
                    width: width * 0.4, // Responsive width
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildSearchField(isSmall: false),
                  ),

                if (!isSmall) const Spacer(),

                // Right side items (Icons Row)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search icon for mobile
                    if (isSmall)
                      IconButton(
                        icon: Icon(
                          _isSearchExpanded ? Icons.close : Icons.search,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(
                            () => _isSearchExpanded = !_isSearchExpanded,
                          );
                        },
                      ),

                    _buildHeaderAction(
                      icon: Icons.favorite_outline,
                      label: 'Wishlist',
                      count: wishlistCount,
                      showLabel: width > 950, // Increased threshold
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WishlistPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: isMobile ? 2 : (isSmall ? 4 : 12)),
                    _buildHeaderAction(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Cart',
                      count: cartCount,
                      showLabel: width > 850, // Increased threshold
                      onTap: () => _openCart(context),
                    ),
                    SizedBox(width: isMobile ? 2 : (isSmall ? 4 : 12)),
                    _buildHeaderAction(
                      icon: Icons.account_circle_outlined,
                      label: _isLoggedIn ? 'Account' : 'Login',
                      showLabel: width > 750, // Increased threshold
                      onTap: () {
                        if (_isLoggedIn) {
                          _navigateToProfile();
                        } else {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const LogIn(),
                                ),
                              )
                              .then((_) => _refreshAuthState());
                        }
                      },
                    ),
                  ],
                ),
                if (!isSmall) const SizedBox(width: 20),
              ],
            ),
            if (_isSearchExpanded && isSmall)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: _buildSearchField(isSmall: true),
              ),
          ],
        ),
      ),
    );
  }
}





