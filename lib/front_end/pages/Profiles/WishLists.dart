import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../All_Pages/CART/Cart_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/image_resolver.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import '../home_page.dart';
import 'Wishlist_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final TextEditingController _linkController = TextEditingController(text: '');
  final TextEditingController _emailController = TextEditingController();
  final Set<String> _cartItemNames = <String>{};
  final Set<String> _selectedItems = <String>{};

  String _formatPriceBdt(double amount) => 'Tk ${amount.toStringAsFixed(2)}';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyWishlistLink() async {
    final link = _linkController.text.trim();
    if (link.isEmpty) {
      _showMessage('No link to copy');
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    _showMessage('Link copied to clipboard');
  }

  Future<void> _shareWishlist() async {
    _showMessage('Share functionality would be implemented here');
  }

  void _removeItem(String productId, WishlistProvider wishlistProvider) {
    wishlistProvider.removeFromWishlist(productId);
    _showMessage('Item removed from wishlist');
  }

  void _clearWishlist(WishlistProvider wishlistProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Wishlist'),
          content: const Text('Are you sure you want to clear all items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                wishlistProvider.clearWishlist();
                Navigator.pop(context);
                _showMessage('Wishlist cleared');
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addItemToCart(
    String productId,
    String productName,
    double price,
    String imageUrl,
    String category,
    WishlistProvider wishlistProvider,
  ) async {
    // ? Stock Validation - Check before adding to cart
    try {
      final pid = int.tryParse(productId);
      if (pid != null) {
        final product = await ApiService.getProduct(pid);
        final availableStock =
            int.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0;

        if (availableStock <= 0) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('?? Out of Stock'),
              content: Text(
                '$productName is currently out of stock.\n\n'
                'This item cannot be added to cart.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        if (availableStock <= 5) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('?? Low Stock'),
              content: Text(
                '$productName\n\n'
                'Only $availableStock unit${availableStock > 1 ? 's' : ''} available in stock.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _proceedToAddToCart(
                      productId,
                      productName,
                      price,
                      imageUrl,
                      category,
                      wishlistProvider,
                    );
                  },
                  child: const Text('Add Anyway'),
                ),
              ],
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to verify stock. Please try again.');
      return;
    }

    // If stock is available, proceed to add
    _proceedToAddToCart(
      productId,
      productName,
      price,
      imageUrl,
      category,
      wishlistProvider,
    );
  }

  void _proceedToAddToCart(
    String productId,
    String productName,
    double price,
    String imageUrl,
    String category,
    WishlistProvider wishlistProvider,
  ) {
    context.read<CartProvider>().addToCart(
      productId: productId,
      name: productName,
      price: price,
      imageUrl: imageUrl,
      category: category,
    );

    // Remove from wishlist after adding to cart
    wishlistProvider.removeFromWishlist(productId);

    _showMessage('Added to cart and removed from wishlist');
  }

  @override
  void dispose() {
    _linkController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: const Header(),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'My Wishlist',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.home_outlined, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const Text(
                        'Wishlist',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wishlist Content
            Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                final items = wishlistProvider.items;

                if (items.isEmpty) {
                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.favorite_outline_rounded,
                                size: 40,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Your wishlist is empty',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Explore our catalog and save your favorite electronics here so you never lose track of them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomePage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                            label: const Text('Start Shopping'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _buildWishlistCardsGrid(
                  context,
                  items,
                  wishlistProvider,
                );
              },
            ),

            const SizedBox(height: 32),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCardsGrid(
    BuildContext context,
    List<WishlistItem> items,
    WishlistProvider wishlistProvider,
  ) {
    final allSelected = items.isNotEmpty &&
        items.every((item) => _selectedItems.contains(item.productId));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: allSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.addAll(items.map((e) => e.productId));
                          } else {
                            _selectedItems.clear();
                          }
                        });
                      },
                      activeColor: const Color(0xFF2563EB),
                    ),
                    Text(
                      'Select All (${items.length} items)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedItems.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          final selectedItemsList = items
                              .where((item) => _selectedItems.contains(item.productId))
                              .toList();
                          for (var item in selectedItemsList) {
                            context.read<CartProvider>().addToCart(
                              productId: item.productId,
                              name: item.name,
                              price: item.price,
                              imageUrl: item.imageUrl,
                              category: item.category,
                            );
                            wishlistProvider.removeFromWishlist(item.productId);
                          }
                          setState(() => _selectedItems.clear());
                          _showMessage('${selectedItemsList.length} items moved to cart');
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                        label: Text('Move Selected (${_selectedItems.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () {
                        for (var item in items) {
                          context.read<CartProvider>().addToCart(
                            productId: item.productId,
                            name: item.name,
                            price: item.price,
                            imageUrl: item.imageUrl,
                            category: item.category,
                          );
                        }
                        wishlistProvider.clearWishlist();
                        setState(() => _selectedItems.clear());
                        _showMessage('All ${items.length} items added to cart');
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Add All to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _clearWishlist(wishlistProvider),
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      label: const Text('Clear', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Product Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1100
                  ? 4
                  : width > 800
                      ? 3
                      : width > 500
                          ? 2
                          : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = _selectedItems.contains(item.productId);
                  final isInCart = _cartItemNames.contains(item.name);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with Overlay Checkbox and Remove Button
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: const Color(0xFFF8FAFC),
                                child: Image(
                                  image: _resolveImageProvider(item.imageUrl),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported_outlined, color: Colors.black26),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedItems.add(item.productId);
                                        } else {
                                          _selectedItems.remove(item.productId);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                                    onPressed: () {
                                      _removeItem(item.productId, wishlistProvider);
                                      setState(() => _selectedItems.remove(item.productId));
                                    },
                                    tooltip: 'Remove from wishlist',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Details
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '৳${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 12, color: Color(0xFF166534)),
                                        SizedBox(width: 3),
                                        Text(
                                          'In Stock',
                                          style: TextStyle(
                                            color: Color(0xFF166534),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isInCart
                                      ? null
                                      : () async {
                                          await _addItemToCart(
                                            item.productId,
                                            item.name,
                                            item.price,
                                            item.imageUrl,
                                            item.category,
                                            wishlistProvider,
                                          );
                                          setState(() {
                                            _cartItemNames.add(item.name);
                                            _selectedItems.remove(item.productId);
                                          });
                                        },
                                  icon: Icon(
                                    isInCart ? Icons.check : Icons.shopping_cart_outlined,
                                    size: 16,
                                  ),
                                  label: Text(isInCart ? 'In Cart' : 'Add to Cart'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isInCart
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFF2563EB),
                                    foregroundColor: isInCart
                                        ? const Color(0xFF64748B)
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveImageProvider(String path) {
    return ImageResolver.imageProvider(path);
  }
}




