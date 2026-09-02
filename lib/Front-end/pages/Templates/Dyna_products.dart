import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../All Pages/CART/Cart_provider.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/image_resolver.dart';
import '../../widgets/Sections/BestSellings/ProductData.dart';
import '../../widgets/Sections/Trendings/trending_all_products.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import '../Profiles/Wishlist_provider.dart';
import 'all_products_template.dart';

class UniversalProductDetails extends StatefulWidget {
  final ProductData product;

  const UniversalProductDetails({super.key, required this.product});

  @override
  State<UniversalProductDetails> createState() =>
      _UniversalProductDetailsState();
}

class _UniversalProductDetailsState extends State<UniversalProductDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeImageIndex = 0;
  int _quantity = 1;

  String get _firstImage =>
      widget.product.images.isNotEmpty ? widget.product.images.first : '';

  ImageProvider _resolveImageProvider(String path) {
    return ImageResolver.imageProvider(path);
  }

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ProductData> _getRelatedProducts() {
    return SampleProducts.bestSellingProducts
        .where(
          (product) =>
              product.id != widget.product.id &&
              product.category == widget.product.category,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      drawer:
          r.isSmallMobile || r.isMobile || r.isTablet ? const AppDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBreadcrumb(r),
            _buildProductContent(r),
            _buildRecommendedProducts(r),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(AppResponsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: r.value(
          smallMobile: 16,
          mobile: 16,
          tablet: 40,
          smallDesktop: 80,
          desktop: 100,
        ),
        vertical: r.value(
          smallMobile: 12,
          mobile: 12,
          tablet: 16,
          smallDesktop: 18,
          desktop: 20,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: r.value(
              smallMobile: 12,
              mobile: 12,
              tablet: 14,
              smallDesktop: 15,
              desktop: 16,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Home",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: AppDimensions.smallFont(context),
                    ),
                  ),
                ),
                Text(
                  " / ",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: AppDimensions.smallFont(context),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Navigate to ${widget.product.category} category',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    widget.product.category,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: AppDimensions.smallFont(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent(AppResponsive r) {
    final isSmallScreen = r.isMobile || r.isSmallMobile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(
          smallMobile: 16,
          mobile: 16,
          tablet: 40,
          smallDesktop: 80,
          desktop: 100,
        ),
        vertical: r.value(
          smallMobile: 12,
          mobile: 12,
          tablet: 16,
          smallDesktop: 18,
          desktop: 20,
        ),
      ),
      child: Column(
        children: [
          isSmallScreen
              ? _buildMobileProductLayout(r)
              : _buildDesktopProductLayout(r),
          SizedBox(
            height: r.value(
              smallMobile: 40,
              mobile: 40,
              tablet: 60,
              smallDesktop: 70,
              desktop: 80,
            ),
          ),
          _buildTabsSection(r),
        ],
      ),
    );
  }

  Widget _buildMobileProductLayout(AppResponsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImageGallery(r),
        SizedBox(
          height: r.value(
            smallMobile: 20,
            mobile: 20,
            tablet: 30,
            smallDesktop: 30,
            desktop: 30,
          ),
        ),
        _buildProductInfo(r),
      ],
    );
  }

  Widget _buildDesktopProductLayout(AppResponsive r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 1, child: _buildImageGallery(r)),
        SizedBox(
          width: r.value(
            smallMobile: 20,
            mobile: 20,
            tablet: 40,
            smallDesktop: 50,
            desktop: 60,
          ),
        ),
        Expanded(flex: 1, child: _buildProductInfo(r)),
      ],
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
            borderRadius: BorderRadius.circular(8),
            image: widget.product.images.isEmpty
                ? null
                : DecorationImage(
                    image: _resolveImageProvider(
                      widget.product.images[_activeImageIndex.clamp(
                        0,
                        widget.product.images.length - 1,
                      )],
                    ),
                    fit: BoxFit.contain,
                  ),
          ),
          child: widget.product.images.isEmpty
              ? const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                )
              : null,
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
        widget.product.images.isEmpty
            ? const SizedBox.shrink()
            : SizedBox(
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
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
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
    // Get stock information from product data
    final stockInfo = widget.product.additionalInfo['stock'] ?? 
                      widget.product.additionalInfo['stock_quantity'];
    final stockQuantity = int.tryParse(stockInfo?.toString() ?? '0') ?? 0;
    final isInStock = stockQuantity > 0;
    final isLowStock = stockQuantity > 0 && stockQuantity <= 5;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: TextStyle(
            fontSize: r.value(
              smallMobile: 22.0,
              mobile: 24.0,
              tablet: 32.0,
              smallDesktop: 35.0,
              desktop: 38.0,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 10,
            mobile: 10,
            tablet: 12,
            smallDesktop: 13,
            desktop: 15,
          ),
        ),
        // Stock Status Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: r.value(
              smallMobile: 10.0,
              mobile: 10.0,
              tablet: 12.0,
              smallDesktop: 13.0,
              desktop: 14.0,
            ),
            vertical: r.value(
              smallMobile: 6.0,
              mobile: 6.0,
              tablet: 7.0,
              smallDesktop: 7.5,
              desktop: 8.0,
            ),
          ),
          decoration: BoxDecoration(
            color: isInStock 
                ? (isLowStock ? Colors.orange.shade50 : Colors.green.shade50)
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isInStock 
                  ? (isLowStock ? Colors.orange : Colors.green)
                  : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isInStock 
                    ? (isLowStock ? Icons.warning_amber_rounded : Icons.check_circle)
                    : Icons.cancel,
                size: r.value(
                  smallMobile: 16.0,
                  mobile: 16.0,
                  tablet: 17.0,
                  smallDesktop: 17.5,
                  desktop: 18.0,
                ),
                color: isInStock 
                    ? (isLowStock ? Colors.orange : Colors.green)
                    : Colors.red,
              ),
              SizedBox(width: 6),
              Text(
                isInStock 
                    ? (isLowStock 
                        ? 'Low Stock ($stockQuantity left)' 
                        : 'In Stock ($stockQuantity available)')
                    : 'Out of Stock',
                style: TextStyle(
                  fontSize: AppDimensions.smallFont(context),
                  fontWeight: FontWeight.w600,
                  color: isInStock 
                      ? (isLowStock ? Colors.orange.shade800 : Colors.green.shade800)
                      : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 10,
            mobile: 10,
            tablet: 12,
            smallDesktop: 13,
            desktop: 15,
          ),
        ),
        Row(
          children: [
            ...List.generate(
              4,
              (_) => Icon(
                Icons.star,
                color: Colors.amber,
                size: r.value(
                  smallMobile: 16.0,
                  mobile: 16.0,
                  tablet: 18.0,
                  smallDesktop: 19.0,
                  desktop: 20.0,
                ),
              ),
            ),
            Icon(
              Icons.star_half,
              color: Colors.amber,
              size: r.value(
                smallMobile: 16.0,
                mobile: 16.0,
                tablet: 18.0,
                smallDesktop: 19.0,
                desktop: 20.0,
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (_) {
                final info = widget.product.additionalInfo;
                final rStr =
                    info['rating'] ?? info['rating_avg'] ?? info['avgRating'];
                final cStr =
                    info['reviews'] ??
                    info['review_count'] ??
                    info['reviewCount'];
                final rating = double.tryParse((rStr ?? '').toString());
                final count = int.tryParse((cStr ?? '').toString());
                if (rating == null || rating <= 0)
                  return const SizedBox.shrink();
                return Text(
                  "${rating.toStringAsFixed(1)} ${count != null ? '($count reviews)' : ''}"
                      .trim(),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: AppDimensions.smallFont(context),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(
          height: r.value(
            smallMobile: 10,
            mobile: 10,
            tablet: 12,
            smallDesktop: 13,
            desktop: 15,
          ),
        ),
        Text(
          "৳ ${widget.product.priceBDT.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: r.value(
              smallMobile: 20.0,
              mobile: 20.0,
              tablet: 24.0,
              smallDesktop: 25.0,
              desktop: 26.0,
            ),
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 15,
            mobile: 15,
            tablet: 20,
            smallDesktop: 22,
            desktop: 25,
          ),
        ),
        Text(
          widget.product.description,
          style: TextStyle(
            height: 1.6,
            color: Colors.black54,
            fontSize: AppDimensions.bodyFont(context),
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 25,
            mobile: 25,
            tablet: 30,
            smallDesktop: 35,
            desktop: 40,
          ),
        ),
        _buildQuantityAndActions(r, isInStock, stockQuantity),
      ],
    );
  }

  Widget _buildQuantityAndActions(AppResponsive r, bool isInStock, int stockQuantity) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 8.0,
                  mobile: 8.0,
                  tablet: 10.0,
                  smallDesktop: 11.0,
                  desktop: 12.0,
                ),
                vertical: r.value(
                  smallMobile: 6.0,
                  mobile: 6.0,
                  tablet: 7.0,
                  smallDesktop: 7.5,
                  desktop: 8.0,
                ),
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _quantityButton(
                    icon: Icons.remove,
                    onTap: isInStock ? () {
                      setState(() {
                        if (_quantity > 1) {
                          _quantity -= 1;
                        }
                      });
                    } : null,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.value(
                        smallMobile: 10.0,
                        mobile: 10.0,
                        tablet: 12.0,
                        smallDesktop: 13.0,
                        desktop: 15.0,
                      ),
                    ),
                    child: Text(
                      "$_quantity",
                      style: TextStyle(
                        fontSize: AppDimensions.bodyFont(context),
                      ),
                    ),
                  ),
                  _quantityButton(
                    icon: Icons.add,
                    onTap: isInStock && _quantity < stockQuantity ? () {
                      setState(() {
                        _quantity += 1;
                      });
                    } : null,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: r.value(
                smallMobile: 12,
                mobile: 12,
                tablet: 16,
                smallDesktop: 18,
                desktop: 20,
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: isInStock ? () async {
                  if (_quantity > stockQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Only $stockQuantity items available in stock'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  
                  await context.read<CartProvider>().addToCart(
                    productId: widget.product.id,
                    name: widget.product.name,
                    price: widget.product.priceBDT,
                    imageUrl: _firstImage,
                    category: widget.product.category,
                    quantity: _quantity,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.product.name} added to cart (x$_quantity)',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInStock ? Colors.orange : Colors.grey,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.value(
                      smallMobile: 20.0,
                      mobile: 20.0,
                      tablet: 30.0,
                      smallDesktop: 35.0,
                      desktop: 40.0,
                    ),
                    vertical: r.value(
                      smallMobile: 14.0,
                      mobile: 14.0,
                      tablet: 16.0,
                      smallDesktop: 18.0,
                      desktop: 20.0,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isInStock ? "ADD TO BAG" : "OUT OF STOCK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimensions.bodyFont(context),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!isInStock)
          Padding(
            padding: EdgeInsets.only(
              top: r.value(
                smallMobile: 8.0,
                mobile: 8.0,
                tablet: 10.0,
                smallDesktop: 11.0,
                desktop: 12.0,
              ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 12.0,
                  mobile: 12.0,
                  tablet: 14.0,
                  smallDesktop: 15.0,
                  desktop: 16.0,
                ),
                vertical: r.value(
                  smallMobile: 8.0,
                  mobile: 8.0,
                  tablet: 9.0,
                  smallDesktop: 9.5,
                  desktop: 10.0,
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This product is currently unavailable. Check back later!',
                      style: TextStyle(
                        fontSize: AppDimensions.smallFont(context),
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
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
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<WishlistProvider>().toggleWishlist(
                productId: widget.product.id,
                name: widget.product.name,
                price: widget.product.priceBDT,
                imageUrl: _firstImage,
                category: widget.product.category,
              );
              final isAdded = context.read<WishlistProvider>().isInWishlist(
                widget.product.id,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAdded ? '✓ Wishlist updated' : '✓ Removed from wishlist',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, _) {
                final isInWishlist = wishlistProvider.isInWishlist(
                  widget.product.id,
                );
                return Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.red : Colors.black,
                );
              },
            ),
            label: const Text("Add to Wishlist"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 20.0,
                  mobile: 20.0,
                  tablet: 30.0,
                  smallDesktop: 35.0,
                  desktop: 40.0,
                ),
                vertical: r.value(
                  smallMobile: 14.0,
                  mobile: 14.0,
                  tablet: 16.0,
                  smallDesktop: 18.0,
                  desktop: 20.0,
                ),
              ),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 18)),
      ),
    );
  }

  Widget _buildTabsSection(AppResponsive r) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.orange,
            indicatorColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppDimensions.bodyFont(context),
            ),
            isScrollable: r.isMobile || r.isSmallMobile,
            tabs: const [
              Tab(text: "DESCRIPTION"),
              Tab(text: "SPECIFICATIONS"),
              Tab(text: "REVIEWS"),
            ],
          ),
        ),
        SizedBox(
          height: r.value(
            smallMobile: 200.0,
            mobile: 200.0,
            tablet: 250.0,
            smallDesktop: 275.0,
            desktop: 300.0,
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(
                  r.value(
                    smallMobile: 16.0,
                    mobile: 16.0,
                    tablet: 24.0,
                    smallDesktop: 27.0,
                    desktop: 30.0,
                  ),
                ),
                child: Text(
                  widget.product.description,
                  style: TextStyle(
                    fontSize: AppDimensions.bodyFont(context),
                    height: 1.8,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildSpecsTable(r),
              _buildReviewsSection(r),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsTable(AppResponsive r) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        r.value(
          smallMobile: 16.0,
          mobile: 16.0,
          tablet: 24.0,
          smallDesktop: 27.0,
          desktop: 30.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.product.additionalInfo.entries.map((entry) {
          return Container(
            padding: EdgeInsets.symmetric(
              vertical: r.value(
                smallMobile: 10.0,
                mobile: 10.0,
                tablet: 11.0,
                smallDesktop: 11.5,
                desktop: 12.0,
              ),
              horizontal: r.value(
                smallMobile: 12.0,
                mobile: 12.0,
                tablet: 14.0,
                smallDesktop: 15.0,
                desktop: 16.0,
              ),
            ),
            margin: EdgeInsets.only(
              bottom: r.value(
                smallMobile: 6.0,
                mobile: 6.0,
                tablet: 7.0,
                smallDesktop: 7.5,
                desktop: 8.0,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(left: BorderSide(color: Colors.orange, width: 3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.bodyFont(context),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: AppDimensions.bodyFont(context)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsSection(AppResponsive r) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          r.value(
            smallMobile: 16.0,
            mobile: 16.0,
            tablet: 24.0,
            smallDesktop: 27.0,
            desktop: 30.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: r.value(
                smallMobile: 50.0,
                mobile: 50.0,
                tablet: 55.0,
                smallDesktop: 57.0,
                desktop: 60.0,
              ),
              color: Colors.grey,
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
            Text(
              "No reviews yet for this product.",
              style: TextStyle(
                fontSize: AppDimensions.bodyFont(context),
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: r.value(
                smallMobile: 6,
                mobile: 6,
                tablet: 8,
                smallDesktop: 9,
                desktop: 10,
              ),
            ),
            Text(
              "Be the first to review!",
              style: TextStyle(
                fontSize: AppDimensions.smallFont(context),
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProducts(AppResponsive r) {
    final relatedProducts = _getRelatedProducts();

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: r.value(
          smallMobile: 30.0,
          mobile: 30.0,
          tablet: 40.0,
          smallDesktop: 45.0,
          desktop: 50.0,
        ),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 16.0,
                mobile: 16.0,
                tablet: 40.0,
                smallDesktop: 80.0,
                desktop: 100.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "You May Also Like",
                  style: TextStyle(
                    fontSize: r.value(
                      smallMobile: 20.0,
                      mobile: 20.0,
                      tablet: 24.0,
                      smallDesktop: 26.0,
                      desktop: 28.0,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrendingAllProducts(),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: AppDimensions.bodyFont(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 16,
              mobile: 16,
              tablet: 24,
              smallDesktop: 27,
              desktop: 30,
            ),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 280.0,
              mobile: 280.0,
              tablet: 300.0,
              smallDesktop: 310.0,
              desktop: 320.0,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: r.value(
                  smallMobile: 16.0,
                  mobile: 16.0,
                  tablet: 40.0,
                  smallDesktop: 80.0,
                  desktop: 100.0,
                ),
              ),
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                return _buildHorizontalProductCard(relatedProducts[index], r);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductCard(ProductData product, AppResponsive r) {
    final cardWidth = r.value(
      smallMobile: 180.0,
      mobile: 180.0,
      tablet: 220.0,
      smallDesktop: 235.0,
      desktop: 250.0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UniversalProductDetails(product: product),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(
          right: r.value(
            smallMobile: 12.0,
            mobile: 12.0,
            tablet: 16.0,
            smallDesktop: 18.0,
            desktop: 20.0,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: r.value(
                smallMobile: 150.0,
                mobile: 150.0,
                tablet: 180.0,
                smallDesktop: 190.0,
                desktop: 200.0,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Colors.grey[100],
                image: product.images.isEmpty
                    ? null
                    : DecorationImage(
                        image: _resolveImageProvider(product.images.first),
                        fit: BoxFit.cover,
                      ),
              ),
              child: Stack(
                children: [
                  if (product.images.isEmpty)
                    const Center(
                      child: Icon(Icons.image, size: 40, color: Colors.grey),
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
                              : '',
                          category: product.category,
                        );
                        final isAdded = context
                            .read<WishlistProvider>()
                            .isInWishlist(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAdded
                                  ? '✓ Wishlist updated'
                                  : '✓ Removed from wishlist',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
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
                              size: r.value(
                                smallMobile: 16.0,
                                mobile: 16.0,
                                tablet: 17.0,
                                smallDesktop: 17.5,
                                desktop: 18.0,
                              ),
                              color: isInWishlist ? Colors.red : Colors.grey,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  r.value(
                    smallMobile: 10.0,
                    mobile: 10.0,
                    tablet: 12.0,
                    smallDesktop: 13.0,
                    desktop: 15.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: AppDimensions.bodyFont(context),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: r.value(
                            smallMobile: 14.0,
                            mobile: 14.0,
                            tablet: 15.0,
                            smallDesktop: 15.5,
                            desktop: 16.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "4.5",
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context),
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(120)",
                          style: TextStyle(
                            fontSize: AppDimensions.smallFont(context) - 1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: r.value(
                        smallMobile: 6,
                        mobile: 6,
                        tablet: 8,
                        smallDesktop: 9,
                        desktop: 10,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "৳ ${product.priceBDT.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: r.value(
                                smallMobile: 15.0,
                                mobile: 15.0,
                                tablet: 16.0,
                                smallDesktop: 17.0,
                                desktop: 18.0,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(
                            r.value(
                              smallMobile: 5.0,
                              mobile: 5.0,
                              tablet: 5.5,
                              smallDesktop: 5.7,
                              desktop: 6.0,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.shopping_cart,
                            size: r.value(
                              smallMobile: 14.0,
                              mobile: 14.0,
                              tablet: 15.0,
                              smallDesktop: 15.5,
                              desktop: 16.0,
                            ),
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

