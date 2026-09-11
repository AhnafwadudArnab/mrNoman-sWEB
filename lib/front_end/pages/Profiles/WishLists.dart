import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
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
      backgroundColor: AppColors.grey300,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: AppColors.grey300,
              child: Column(
                children: [
                  const Text(
                    'Wishlist',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        child: Text(
                          'Home',
                          style: TextStyle(color: AppColors.grey300, fontSize: 14),
                        ),
                      ),
                      Text(
                        '  /  ',
                        style: TextStyle(color: AppColors.grey300, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          // Refresh wishlist
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wishlist refreshed')),
                          );
                        },
                        child: Text(
                          'Wishlist',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wishlist Table
            Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                final items = wishlistProvider.items;

                if (items.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your wishlist is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add items to get started',
                          style: TextStyle(fontSize: 14, color: AppColors.grey300),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Continue Shopping'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
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

            // Cart Button & Clear
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, _) {
                  final items = wishlistProvider.items;
                  if (items.isEmpty) return const SizedBox.shrink();

                  return Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _clearWishlist(wishlistProvider),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear Wishlist'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_selectedItems.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                final selectedItemsList = items
                                    .where(
                                      (item) => _selectedItems.contains(
                                        item.productId,
                                      ),
                                    )
                                    .toList();

                                final count = selectedItemsList.length;

                                for (var item in selectedItemsList) {
                                  context.read<CartProvider>().addToCart(
                                    productId: item.productId,
                                    name: item.name,
                                    price: item.price,
                                    imageUrl: item.imageUrl,
                                    category: item.category,
                                  );
                                  wishlistProvider.removeFromWishlist(
                                    item.productId,
                                  );
                                }

                                setState(() => _selectedItems.clear());
                                _showMessage(
                                  '$count item${count > 1 ? 's' : ''} added to cart and removed from wishlist',
                                );
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: Text(
                                'Add Selected (${_selectedItems.length})',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // ? Stock Validation for "Add All To Cart"
                          final itemsToAdd = <WishlistItem>[];
                          final outOfStockItems = <String>[];

                          for (var item in items) {
                            try {
                              final pid = int.tryParse(item.productId);
                              if (pid != null) {
                                final product = await ApiService.getProduct(
                                  pid,
                                );
                                final availableStock =
                                    int.tryParse(
                                      product['stock_quantity']?.toString() ??
                                          '0',
                                    ) ??
                                    0;

                                if (availableStock > 0) {
                                  itemsToAdd.add(item);
                                } else {
                                  outOfStockItems.add(item.name);
                                }
                              } else {
                                itemsToAdd.add(item);
                              }
                            } catch (e) {
                              // If error checking stock, skip this item
                              outOfStockItems.add(item.name);
                            }
                          }

                          if (!mounted) return;

                          // Show warning if some items are out of stock
                          if (outOfStockItems.isNotEmpty) {
                            final shouldContinue = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('?? Some Items Out of Stock'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'The following items are out of stock and will be skipped:',
                                    ),
                                    const SizedBox(height: 8),
                                    ...outOfStockItems.map(
                                      (name) => Text(
                                        '? $name',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${itemsToAdd.length} item${itemsToAdd.length > 1 ? 's' : ''} will be added to cart.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldContinue != true) return;
                          }

                          // Add available items to cart
                          for (var item in itemsToAdd) {
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

                          if (itemsToAdd.isEmpty) {
                            _showMessage('All items are out of stock');
                          } else {
                            _showMessage(
                              '${itemsToAdd.length} item${itemsToAdd.length > 1 ? 's' : ''} added to cart',
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Add All To Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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
            child: Row(
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
                const Spacer(),
                if (_selectedItems.isNotEmpty) ...[
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
                  const SizedBox(width: 8),
                ],
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




