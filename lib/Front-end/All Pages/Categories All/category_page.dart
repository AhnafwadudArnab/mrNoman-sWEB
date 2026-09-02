import 'package:electrocitybd1/Front-end/Dimensions/responsive_dimensions.dart';
import 'package:electrocitybd1/Front-end/widgets/header.dart';
import 'package:electrocitybd1/Front-end/widgets/footer.dart';
import 'package:flutter/material.dart';

import 'SideCatePages/HomeComfortUtils.dart';
import 'SideCatePages/KitchenAppliances.dart';
import 'SideCatePages/PersonalCareLifestyle.dart';

class CategoryPage extends StatelessWidget {
  final String title;
  const CategoryPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final categories = [
      {'name': 'Kitchen Appliances', 'widget': const KitchenAppliancesPage()},
      {
        'name': 'Home Comfort & Utility',
        'widget': const HomeComfortUtilityPage(),
      },
      {
        'name': 'Personal Care & Lifestyle',
        'widget': const PersonalCareLifestylePage(),
      },
    ];

    final padding = AppDimensions.padding(context);
    final cardWidth = r.value(
      smallMobile: double.infinity,
      mobile: double.infinity,
      tablet: MediaQuery.of(context).size.width / 2 - padding,
      smallDesktop: MediaQuery.of(context).size.width / 3 - padding * 1.2,
      desktop: MediaQuery.of(context).size.width / 3 - padding * 1.5,
    );
    final crossAxisCount = r.value(
      smallMobile: 1,
      mobile: 1,
      tablet: 2,
      smallDesktop: 3,
      desktop: 3,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const Header(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppDimensions.titleFont(context),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: padding * 1.5),
                  // Grid or List based on screen size
                  if (r.isMobile || r.isSmallMobile)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: padding),
                          child: _buildCategoryCard(context, category, true),
                        );
                      },
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: padding,
                        mainAxisSpacing: padding,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _buildCategoryCard(context, category, false);
                      },
                    ),
                  SizedBox(height: padding * 2),
                ],
              ),
            ),
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
    bool isListView,
  ) {
    final r = AppResponsive.of(context);
    final padding = AppDimensions.padding(context);

    final cardHeight = r.value(
      smallMobile: 100.0,
      mobile: 100.0,
      tablet: 150.0,
      smallDesktop: 180.0,
      desktop: 200.0,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => category['widget'] as Widget),
          );
        },
        child: Container(
          height: isListView ? cardHeight : null,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: AppDimensions.bodyFont(context),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      'Tap to explore',
                      style: TextStyle(
                        fontSize: AppDimensions.smallFont(context),
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFFF97316),
                size: r.value(
                  smallMobile: 18.0,
                  mobile: 18.0,
                  tablet: 20.0,
                  smallDesktop: 22.0,
                  desktop: 24.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example data and filter variables (replace with your actual data sources)
final List<Map<String, Object>> _products = [
  {
    'price': 100.0,
    'brand': 'BrandA',
    'subCategory': 'Kitchen Appliances',
    'specs': ['Spec1', 'Spec2'],
  },
  {
    'price': 200.0,
    'brand': 'BrandB',
    'subCategory': 'Home Comfort & Utility',
    'specs': ['Spec2', 'Spec3'],
  },
];

final RangeValues _priceRange = const RangeValues(0, 500);
final List<String> _selectedBrands = [];
final List<String> _selectedCategories = [];
final List<String> _selectedSpecifications = [];

List<Map<String, Object>> _filteredProducts() {
  return _products.where((p) {
    final price = p['price'] as double;
    final brand = p['brand'] as String;
    final category =
        p['subCategory'] as String; // Add 'subCategory' to your product maps
    final specs = (p['specs'] as List<String>?) ?? const <String>[];

    final matchesPrice = price >= _priceRange.start && price <= _priceRange.end;
    final matchesBrand =
        _selectedBrands.isEmpty || _selectedBrands.contains(brand);
    final matchesCategory =
        _selectedCategories.isEmpty || _selectedCategories.contains(category);
    final matchesSpecs =
        _selectedSpecifications.isEmpty ||
        _selectedSpecifications.any(specs.contains);

    return matchesPrice && matchesBrand && matchesCategory && matchesSpecs;
  }).toList();
}
