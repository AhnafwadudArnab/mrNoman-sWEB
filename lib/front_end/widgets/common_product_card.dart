import 'package:electrocitybd1/front_end/pages/Profiles/Wishlist_provider.dart';
import 'package:electrocitybd1/front_end/pages/Templates/Dyna_products.dart';
import 'package:electrocitybd1/front_end/pages/Templates/all_products_template.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Dimensions/responsive_dimensions.dart';
import '../utils/optimized_image_widget.dart';

class CommonProductCard extends StatelessWidget {
  final ProductData product;
  final VoidCallback? onTap;

  const CommonProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UniversalProductDetails(product: product),
              ),
            );
          },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFFF8FAFC),
                    child: OptimizedImageWidget(
                      imageUrl: product.images.isNotEmpty
                          ? product.images.first
                          : 'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.read<WishlistProvider>().toggleWishlist(
                          productId: product.id,
                          name: product.name,
                          price: product.priceBDT,
                          imageUrl: product.images.isNotEmpty
                              ? product.images.first
                              : 'assets/images/placeholder.png',
                          category: product.category,
                        );
                        final isAdded = context
                            .read<WishlistProvider>()
                            .isInWishlist(product.id);
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
                        padding: const EdgeInsets.all(6),
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
                              product.id,
                            );
                            return Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: AppDimensions.iconSize(context) * 0.7,
                              color: isInWishlist
                                  ? Colors.red
                                  : AppColors.grey200,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(
                  r.value(
                    smallMobile: 8,
                    mobile: 10,
                    tablet: 12,
                    smallDesktop: 14,
                    desktop: 16,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: AppDimensions.bodyFont(context),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.3,
                      ),
                      maxLines: r.isSmallMobile ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: r.value(
                        smallMobile: 4,
                        mobile: 5,
                        tablet: 6,
                        smallDesktop: 8,
                        desktop: 8,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: AppDimensions.iconSize(context) * 0.7,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "4.5",
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: AppColors.grey300,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.isSmallMobile ? 3 : 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Tk ${product.priceBDT.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: AppDimensions.bodyFont(context),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.all(r.isSmallMobile ? 4 : 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            size: AppDimensions.iconSize(context) * 0.6,
                            color: Colors.white,
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
    );
  }
}












