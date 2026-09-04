import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import '../../All_Pages/CART/Cart_provider.dart';
import '../../All_Pages/CART/Orders.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../pages/Profiles/Wishlist_provider.dart';
import '../../utils/image_resolver.dart';
import 'all_products_template.dart';

class LatestArrivalPage extends StatefulWidget {
  final ProductData product;

  const LatestArrivalPage({super.key, required this.product});

  @override
  State<LatestArrivalPage> createState() => _LatestArrivalPageState();
}

class _LatestArrivalPageState extends State<LatestArrivalPage> {
  int _activeImageIndex = 0;
  int _quantity = 1;

  ImageProvider _resolveImageProvider(String path) {
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
        title: Text(
          widget.product.name,
          style: TextStyle(fontSize: AppDimensions.titleFont(context)),
        ),
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
          padding: EdgeInsets.all(AppDimensions.padding(context)),
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
    final imageHeight = r.value(
      smallMobile: 280.0,
      mobile: 300.0,
      tablet: 400.0,
      smallDesktop: 450.0,
      desktop: 500.0,
    );

    return Column(
      children: [
        Container(
          height: imageHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(
              AppDimensions.borderRadius(context),
            ),
            image: DecorationImage(
              image: _resolveImageProvider(
                widget.product.images.isNotEmpty
                    ? widget.product.images[_activeImageIndex]
                    : 'assets/images/placeholder.png',
              ),
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 12,
            mobile: 12,
            tablet: 16,
            smallDesktop: 18,
            desktop: 20,
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 60.0,
            mobile: 60.0,
            tablet: 70.0,
            smallDesktop: 75.0,
            desktop: 80.0,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => setState(() => _activeImageIndex = index),
                child: Container(
                  margin: EdgeInsets.only(
                    right: r.value(
                      smallMobile: 8.0,
                      mobile: 8.0,
                      tablet: 10.0,
                      smallDesktop: 10.0,
                      desktop: 10.0,
                    ),
                  ),
                  width: r.value(
                    smallMobile: 60.0,
                    mobile: 60.0,
                    tablet: 70.0,
                    smallDesktop: 75.0,
                    desktop: 80.0,
                  ),
                  height: r.value(
                    smallMobile: 60.0,
                    mobile: 60.0,
                    tablet: 70.0,
                    smallDesktop: 75.0,
                    desktop: 80.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _activeImageIndex == index
                          ? Colors.black
                          : Colors.black26,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius(context) / 2,
                    ),
                    image: DecorationImage(
                      image: _resolveImageProvider(
                        widget.product.images[index],
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
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
            fontSize: AppDimensions.titleFont(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: r.hp(1)),
        Row(
          children: [
            ...List.generate(
              4,
              (_) => Icon(
                Icons.star,
                color: Colors.amber,
                size: AppDimensions.iconSize(context),
              ),
            ),
            Icon(
              Icons.star_half,
              color: Colors.amber,
              size: AppDimensions.iconSize(context),
            ),
            SizedBox(width: AppDimensions.padding(context) / 2),
            Text(
              "4.5 (128 reviews)",
              style: TextStyle(
                color: AppColors.grey300,
                fontSize: AppDimensions.smallFont(context),
              ),
            ),
          ],
        ),
        SizedBox(height: r.hp(1)),
        Text(
          widget.product.formattedPrice,
          style: TextStyle(
            fontSize: AppDimensions.titleFont(context) - 8,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: r.hp(1)),
        Text(
          widget.product.description,
          style: TextStyle(
            fontSize: AppDimensions.bodyFont(context),
            color: AppColors.grey300,
          ),
        ),
        SizedBox(height: r.hp(2)),
        _buildQuantityAndActions(r),
      ],
    );
  }

  Widget _buildQuantityAndActions(AppResponsive r) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadius(context) / 2,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove,
                      size: AppDimensions.iconSize(context),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_quantity > 1) _quantity -= 1;
                      });
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: TextStyle(fontSize: AppDimensions.bodyFont(context)),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: AppDimensions.iconSize(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _quantity += 1;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.padding(context)),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final firstImage = widget.product.images.isNotEmpty
                      ? widget.product.images.first
                      : '';
                  await context.read<CartProvider>().addToCart(
                    productId: widget.product.id,
                    name: widget.product.name,
                    price: widget.product.priceBDT,
                    imageUrl: firstImage,
                    category: widget.product.category,
                    quantity: _quantity,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(
                    AppDimensions.buttonHeight(context),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.borderRadius(context) / 2,
                    ),
                  ),
                ),
                child: Text(
                  'ADD TO BAG',
                  style: TextStyle(fontSize: AppDimensions.bodyFont(context)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: r.hp(1)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final firstImage = widget.product.images.isNotEmpty
                  ? widget.product.images.first
                  : '';
              context.read<WishlistProvider>().toggleWishlist(
                productId: widget.product.id,
                name: widget.product.name,
                price: widget.product.priceBDT,
                imageUrl: firstImage,
                category: widget.product.category,
              );
              final isAdded = context.read<WishlistProvider>().isInWishlist(
                widget.product.id,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAdded ? '? Added to wishlist' : '? Removed from wishlist',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: Consumer<WishlistProvider>(
              builder: (_, wishlist, __) => Icon(
                wishlist.isInWishlist(widget.product.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: AppDimensions.iconSize(context),
                color: wishlist.isInWishlist(widget.product.id)
                    ? Colors.red
                    : null,
              ),
            ),
            label: Text(
              'Add to Wishlist',
              style: TextStyle(fontSize: AppDimensions.bodyFont(context)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: AppColors.grey300),
              minimumSize: Size.fromHeight(AppDimensions.buttonHeight(context)),
            ),
          ),
        ),
      ],
    );
  }
}




