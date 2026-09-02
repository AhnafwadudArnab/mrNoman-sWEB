import 'package:electrocitybd1/Front-end/pages/Templates/all_products_template.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import '../All Pages/CART/Cart_provider.dart';
import '../All Pages/CART/Orders.dart';
import '../pages/Profiles/Wishlist_provider.dart';
import '../Dimensions/responsive_dimensions.dart';
import '../utils/image_resolver.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductData product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _quantity = 1;
  int _activeImageIndex = 0;
  ImageProvider _resolve(String path) {
    return ImageResolver.imageProvider(path);
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isSmallScreen = r.isMobile || r.isSmallMobile;

    final cartCount = context.watch<CartProvider>().getItemCount();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -4, end: -4),
              badgeContent: Text(
                cartCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              showBadge: cartCount > 0,
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: EdgeInsets.all(5),
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  final total = context.read<CartProvider>().getCartTotal();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubmitOrderPage(totalAmount: total),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            r.value(
              smallMobile: 8,
              mobile: 12,
              tablet: 24,
              smallDesktop: 32,
              desktop: 48,
            ),
          ),
          child: isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(r),
                    SizedBox(height: r.hp(2)),
                    _buildProductInfo(r),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildImageGallery(r)),
                    SizedBox(
                      width: r.value(
                        smallMobile: 12,
                        mobile: 16,
                        tablet: 24,
                        smallDesktop: 32,
                        desktop: 40,
                      ),
                    ),
                    Expanded(flex: 3, child: _buildProductInfo(r)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(AppResponsive r) {
    final images =
        widget.product.images is List<String> &&
            widget.product.images.isNotEmpty
        ? List<String>.from(widget.product.images)
        : ['assets/images/placeholder.png'];
    final imageHeight = r.value(
      smallMobile: 220.0,
      mobile: 260.0,
      tablet: 340.0,
      smallDesktop: 400.0,
      desktop: 480.0,
    );

    return Column(
      children: [
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: _resolve(images[_activeImageIndex]),
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: r.hp(2)),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => setState(() => _activeImageIndex = index),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _activeImageIndex == index
                        ? Colors.orange
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: _resolve(images[index]),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo(AppResponsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: r.value(
              smallMobile: 18,
              mobile: 20,
              tablet: 24,
              smallDesktop: 28,
              desktop: 32,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: r.hp(1)),
        Row(
          children: [
            ...List.generate(
              4,
              (_) => const Icon(Icons.star, color: Colors.amber, size: 22),
            ),
            const Icon(Icons.star_half, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Text(
              "4.5 (128 reviews)",
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ],
        ),
        SizedBox(height: r.hp(1)),
        Text(
          widget.product.formattedPrice,
          style: TextStyle(
            fontSize: r.value(
              smallMobile: 18,
              mobile: 20,
              tablet: 24,
              smallDesktop: 28,
              desktop: 32,
            ),
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: r.hp(1)),
        Text(
          widget.product.description,
          style: TextStyle(fontSize: 15, color: Colors.grey[800]),
        ),
        SizedBox(height: r.hp(2)),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (_quantity > 1) _quantity--;
                      });
                    },
                  ),
                  Text('$_quantity', style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: r.value(
                smallMobile: 8,
                mobile: 10,
                tablet: 16,
                smallDesktop: 18,
                desktop: 20,
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<CartProvider>().addToCart(
                      productId: widget.product.id,
                      name: widget.product.name,
                      price: widget.product.priceBDT,
                      imageUrl: widget.product.images.isNotEmpty
                          ? widget.product.images.first
                          : '',
                      category: widget.product.category,
                      quantity: _quantity,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.product.name} added to cart'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          textColor: Colors.white,
                          onPressed: () {
                            final total =
                                context.read<CartProvider>().getCartTotal();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubmitOrderPage(totalAmount: total),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add to cart: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ADD TO BAG', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
        SizedBox(height: r.hp(1)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final wishlist = context.read<WishlistProvider>();
                await wishlist.toggleWishlist(
                  productId: widget.product.id,
                  name: widget.product.name,
                  price: widget.product.priceBDT,
                  imageUrl: widget.product.images.isNotEmpty
                      ? widget.product.images.first
                      : '',
                  category: widget.product.category,
                );
                if (!mounted) return;
                final isNowInWishlist =
                    wishlist.isInWishlist(widget.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isNowInWishlist
                          ? '${widget.product.name} added to wishlist'
                          : '${widget.product.name} removed from wishlist',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update wishlist: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Consumer<WishlistProvider>(
              builder: (_, wishlist, child) => Icon(
                wishlist.isInWishlist(widget.product.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: wishlist.isInWishlist(widget.product.id)
                    ? Colors.red
                    : null,
              ),
            ),
            label: Consumer<WishlistProvider>(
              builder: (_, wishlist, child) => Text(
                wishlist.isInWishlist(widget.product.id)
                    ? 'Remove from Wishlist'
                    : 'Add to Wishlist',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}
