import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:provider/provider.dart';

import '../All_Pages/CART/Cart_provider.dart';
import '../Dimensions/responsive_dimensions.dart';
import '../pages/Profiles/Wishlist_provider.dart';
import '../utils/optimized_image_widget.dart';

class ProductCard extends StatelessWidget {
  final String? productId;
  final String? category;
  final String title;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final int? discountPercent;
  final bool isPreOrder;
  final String buttonText;
  final VoidCallback? onPress;
  final int? stockQuantity;

  const ProductCard({
    super.key,
    this.productId,
    this.category,
    required this.title,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.discountPercent,
    this.isPreOrder = false,
    this.buttonText = 'Add To Cart',
    this.onPress,
    this.stockQuantity,
  });

  String _safeProductId() {
    if (productId != null && productId!.trim().isNotEmpty) {
      return productId!;
    }
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area with badges
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: OptimizedImageWidget(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (discountPercent != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.padding(context) * 0.5,
                          vertical: AppDimensions.padding(context) * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.read<WishlistProvider>().toggleWishlist(
                          productId: _safeProductId(),
                          name: title,
                          price: price,
                          imageUrl: imageUrl,
                          category: category ?? 'General',
                        );
                        final isAdded = context
                            .read<WishlistProvider>()
                            .isInWishlist(_safeProductId());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAdded
                                  ? '? Wishlist updated'
                                  : '? Removed from wishlist',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xF0FFFFFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x1F000000),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Consumer<WishlistProvider>(
                          builder: (context, wishlistProvider, _) {
                            final isInWishlist = wishlistProvider.isInWishlist(
                              _safeProductId(),
                            );
                            return IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: isInWishlist
                                    ? Colors.red
                                    : AppColors.grey200,
                              ),
                              onPressed: () async {
                                if (isInWishlist) {
                                  await wishlistProvider.removeFromWishlist(
                                    _safeProductId(),
                                  );
                                } else {
                                  await wishlistProvider.addToWishlist(
                                    productId: _safeProductId(),
                                    name: title,
                                    price: price,
                                    imageUrl: imageUrl,
                                    category: category ?? 'general',
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  r.isSmallMobile ? 8 : 10,
                  r.isSmallMobile ? 6 : 8,
                  r.isSmallMobile ? 8 : 10,
                  r.isSmallMobile ? 7 : 9,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDimensions.smallFont(context),
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (stockQuantity != null)
                      Text(
                        stockQuantity! > 0
                            ? (stockQuantity! <= 5
                                  ? 'Only $stockQuantity left!'
                                  : '$stockQuantity in stock')
                            : 'Out of stock',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppDimensions.smallFont(context) * 0.82,
                          color: stockQuantity! > 0
                              ? (stockQuantity! <= 5
                                    ? Colors.orange
                                    : Colors.green[700])
                              : Colors.red,
                          fontWeight: stockQuantity! <= 5
                              ? FontWeight.w600
                              : FontWeight.normal,
                          height: 1.1,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tk ${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: AppDimensions.bodyFont(context),
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandOrange,
                              ),
                            ),
                          ),
                        ),
                        if (originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Tk ${originalPrice!.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppDimensions.smallFont(context),
                                color: AppColors.grey300,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                        if (isPreOrder) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Pre-Order',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize:
                                    AppDimensions.smallFont(context) * 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: r.isSmallMobile ? 30 : 32,
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<CartProvider>().addToCart(
                            productId: _safeProductId(),
                            name: title,
                            price: price,
                            imageUrl: imageUrl,
                            category: category ?? 'General',
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF111827),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            buttonText,
                            maxLines: 1,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
