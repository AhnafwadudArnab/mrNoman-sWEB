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
import '../Admin_Panel/A_customers.dart';
import '../utils/image_resolver.dart';
import '../Provider/api_ready_notifier.dart';
import '../Provider/product_refresh_notifier.dart';
import '../pages/Templates/all_products_template.dart';
import '../utils/api_service.dart';
import '../utils/search_history.dart';
import '../pages/Profiles/Profile.dart';
import 'Sidebar/sidebar.dart';
import 'SearchRes.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

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
  bool _isAdmin = false;
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
    final admin = await AuthSession.isAdmin();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isAdmin = admin;
      });
    }
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

  void _openSidebar(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasDrawer) {
      scaffold.openDrawer();
      return;
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogCtx, anim1, anim2) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white,
            elevation: 16,
            child: SizedBox(
              width: 290,
              height: MediaQuery.of(dialogCtx).size.height,
              child: const SafeArea(
                child: Sidebar(width: 290),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  void _navigateToProfile() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfilePage()))
        .then((_) => _refreshAuthState());
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int count = 0,
    bool showLabel = true,
    bool isMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 8 : (isMobile ? 3 : 5),
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badges.Badge(
              position: badges.BadgePosition.topEnd(top: -7, end: -7),
              badgeContent: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: count > 0,
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.black,
                padding: EdgeInsets.all(3),
                elevation: 0,
              ),
              child: Icon(icon, color: Colors.black, size: isMobile ? 20 : 22),
            ),
            if (showLabel) ...[
              const SizedBox(width: 6),
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
    final showHamburger = width < 1024;
    final cartCount = context.watch<CartProvider>().getItemCount();
    final wishlistCount = context.watch<WishlistProvider>().wishlistCount;
    final double headerHeight = _isSearchExpanded && isSmall ? 124.0 : 64.0;

    return Material(
      color: const Color(0xFFFAB12F),
      elevation: 4,
      shadowColor: const Color(0x1A000000),
      child: Container(
        width: double.infinity,
        height: headerHeight,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // Hamburger Menu for Mobile & Tablet (when permanent sidebar is hidden)
                if (showHamburger) ...[
                  Builder(
                    builder: (menuCtx) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black, size: 24),
                      padding: const EdgeInsets.only(right: 4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Menu',
                      onPressed: () => _openSidebar(menuCtx),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // 1. Logo & Brand Name (Fixed size, NEVER truncates or disappears)
                InkWell(
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: isMobile ? 26 : (isSmall ? 30 : 38),
                          width: isMobile ? 26 : (isSmall ? 30 : 38),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              isMobile ? 6 : 8,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: Image.asset(
                            'assets/elogo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.electric_bolt,
                              color: const Color(0xFFFAB12F),
                              size: isMobile ? 16 : 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ElectroZoneBD',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isMobile ? 14 : 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Centered Search Bar on Desktop / Tablets
                if (!isSmall)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 540),
                          child: _buildSearchField(isSmall: false),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                // 3. Far-Right Action Icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSmall)
                      IconButton(
                        icon: Icon(
                          _isSearchExpanded ? Icons.close : Icons.search,
                          color: Colors.black,
                          size: isMobile ? 20 : 22,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(
                            () => _isSearchExpanded = !_isSearchExpanded,
                          );
                        },
                      ),
                    if (isSmall) SizedBox(width: isMobile ? 1 : 4),
                    _buildHeaderAction(
                      icon: Icons.favorite_outline,
                      label: 'Wishlist',
                      count: wishlistCount,
                      showLabel: width >= 1150,
                      isMobile: isMobile,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WishlistPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: isMobile ? 1 : 4),
                    _buildHeaderAction(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Cart',
                      count: cartCount,
                      showLabel: width >= 1150,
                      isMobile: isMobile,
                      onTap: () => _openCart(context),
                    ),
                    SizedBox(width: isMobile ? 1 : 4),
                    _buildHeaderAction(
                      icon: Icons.account_circle_outlined,
                      label: _isLoggedIn ? 'Account' : 'Login',
                      showLabel: width >= 1150,
                      isMobile: isMobile,
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
                    if (_isAdmin) ...[
                      SizedBox(width: isMobile ? 1 : 4),
                      _buildHeaderAction(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin',
                        showLabel: width >= 1150,
                        isMobile: isMobile,
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminLayoutPage(),
                                ),
                              )
                              .then((_) => _refreshAuthState());
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (_isSearchExpanded && isSmall)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildSearchField(isSmall: true),
              ),
          ],
        ),
      ),
    );
  }
}





