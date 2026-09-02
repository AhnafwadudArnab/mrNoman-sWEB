import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Admin Panel/A_customers.dart';
import '../../Provider/Banner_provider.dart';
import '../../Provider/api_ready_notifier.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/auth_session.dart';
import '../../utils/api_service.dart';
import '../Sections/Flash Sale/Flash_sale_all.dart';
import '../../pages/Templates/category_products_page.dart';

class Sidebar extends StatefulWidget {
  final double? width;
  const Sidebar({super.key, this.width});

  @override
  State<Sidebar> createState() => _SidebarState();
}

// Parent categories (marked in image) — child category names mapped under each parent
const Map<String, List<String>> _parentChildMap = {
  'Electronics & Gadgets': [],
  'Fan & Cooling': [],
  'Home Appliances': ['Air Fryers', 'Blenders & Mixers', 'Irons & Steamers', 'Rice Cookers', 'Home Comfort & Utility'],
  'Kitchen Appliances': [],
  'Personal Care & Lifestyle': ['Personal Care'],
  'Tools & Hardware': [],
  'Wiring & Cables': [],
};

class _SidebarState extends State<Sidebar> {
  bool _expanded = true;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  bool _loadTriggered = false;

  // Track which parent category is expanded
  String? _expandedParentName;
  // Track which category (parent or child) is expanded for brands
  int? _expandedCategoryId;
  // Cache brands per category: categoryId -> list of brands
  final Map<int, List<Map<String, dynamic>>> _brandsByCategory = {};
  final Map<int, bool> _loadingBrands = {};


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ready = context.watch<ApiReadyNotifier>().isReady;
    if (ready && !_loadTriggered) {
      _loadTriggered = true;
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories
              .map((c) => Map<String, dynamic>.from(c as Map))
              .toList();
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = _fallbackCategories;
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadBrandsForCategory(int categoryId) async {
    if (_brandsByCategory.containsKey(categoryId)) return; // already loaded
    setState(() => _loadingBrands[categoryId] = true);
    try {
      final res = await ApiService.get(
        '/brands?category_id=$categoryId',
        withAuth: false,
      );
      final list = res is List
          ? res.map((b) => Map<String, dynamic>.from(b as Map)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _brandsByCategory[categoryId] = list;
          _loadingBrands[categoryId] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBrands[categoryId] = false);
    }
  }

  final List<Map<String, dynamic>> _fallbackCategories = [
    {'category_id': 1, 'category_name': 'Kitchen Appliances'},
    {'category_id': 2, 'category_name': 'Personal Care & Lifestyle'},
    {'category_id': 3, 'category_name': 'Home Comfort & Utility'},
  ];

  IconData _getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.category;
    final name = categoryName.toLowerCase();
    if (name.contains('kitchen')) return Icons.kitchen;
    if (name.contains('personal') || name.contains('care')) return Icons.iron;
    if (name.contains('home') || name.contains('comfort')) return Icons.wash;
    if (name.contains('electronic')) return Icons.devices;
    if (name.contains('lighting') || name.contains('light')) return Icons.lightbulb;
    if (name.contains('tool')) return Icons.build;
    if (name.contains('wiring') || name.contains('wire')) return Icons.cable;
    if (name.contains('appliance')) return Icons.home_repair_service;
    return Icons.category;
  }

  void _onCategoryTap(BuildContext context, Map<String, dynamic> category) {
    _navigateToCategory(context, category, brandFilter: null);
  }

  void _navigateToCategory(
    BuildContext context,
    Map<String, dynamic> category, {
    String? brandFilter,
  }) {
    final raw = category['category_id'];
    final categoryId = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
    final categoryName = category['category_name']?.toString() ?? 'Products';

    // Close drawer on mobile
    if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(
          categoryId: categoryId > 0 ? categoryId : 0,
          categoryName: categoryName,
          categoryNameFallback: categoryId <= 0 ? categoryName : null,
          brandFilter: brandFilter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    const primaryRed = Colors.red;

    return Container(
      width:
          widget.width ??
          r.value(
            smallMobile: 0.0,
            mobile: 0.0,
            tablet: 260.0,
            smallDesktop: 280.0,
            desktop: 300.0,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🛡️ HEADER / CATEGORY TOGGLE
            _buildSectionHeader('CATEGORIES', canToggle: true),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildCategoryList(context),
              secondChild: const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // 🏷️ PROMO CARD
            _buildLivePromoCard(primaryRed),

            const SizedBox(height: 20),

            // ⚙️ SERVICE ASSURANCES (dark grey block)
            _buildTrustSection(),

            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: AuthSession.isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.data != true) return const SizedBox.shrink();
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminLayoutPage(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 20,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool canToggle = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.2,
          ),
        ),
        if (canToggle)
          IconButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.remove : Icons.add, size: 16),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    if (_loadingCategories) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No categories available', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      );
    }

    // Build a lookup: name -> category map
    final Map<String, Map<String, dynamic>> categoryByName = {
      for (final c in _categories)
        (c['category_name']?.toString() ?? ''): c,
    };

    // Collect all child category names
    final Set<String> allChildNames = _parentChildMap.values
        .expand((children) => children)
        .toSet();

    // Build ordered list: parents first (in _parentChildMap order), then orphans
    final List<Map<String, dynamic>> parents = [];
    for (final parentName in _parentChildMap.keys) {
      final cat = categoryByName[parentName];
      if (cat != null) parents.add(cat);
    }
    // Orphans: categories not in any parent list and not a parent themselves
    final Set<String> parentNames = _parentChildMap.keys.toSet();
    final List<Map<String, dynamic>> orphans = _categories
        .where((c) {
          final name = c['category_name']?.toString() ?? '';
          return !parentNames.contains(name) && !allChildNames.contains(name);
        })
        .toList();

    final List<Map<String, dynamic>> orderedCategories = [...parents, ...orphans];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: orderedCategories.asMap().entries.map((entry) {
          final idx = entry.key;
          final category = entry.value;
          final categoryName = category['category_name']?.toString() ?? 'Category';
          final isParent = _parentChildMap.containsKey(categoryName);
          final childNames = isParent ? (_parentChildMap[categoryName] ?? []) : <String>[];
          final childCategories = childNames
              .map((n) => categoryByName[n])
              .whereType<Map<String, dynamic>>()
              .toList();
          final isParentExpanded = _expandedParentName == categoryName;

          return Column(
            children: [
              _buildCategoryRow(context, category, isParent: isParent, hasChildren: childCategories.isNotEmpty),

              // If parent is expanded, show child categories
              if (isParent && isParentExpanded && childCategories.isNotEmpty)
                ...childCategories.map((child) => _buildChildCategoryRow(context, child)),

              if (idx < orderedCategories.length - 1)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    Map<String, dynamic> category, {
    required bool isParent,
    required bool hasChildren,
  }) {
    final categoryName = category['category_name']?.toString() ?? 'Category';
    final raw = category['category_id'];
    final categoryId = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
    final icon = _getCategoryIcon(categoryName);
    final isBrandExpanded = _expandedCategoryId == categoryId;
    final isParentExpanded = _expandedParentName == categoryName;
    final brands = _brandsByCategory[categoryId] ?? [];
    final loadingBrands = _loadingBrands[categoryId] == true;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (isParent && hasChildren) {
              setState(() {
                _expandedParentName = isParentExpanded ? null : categoryName;
              });
            } else {
              _navigateToCategory(context, category, brandFilter: null);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.blueGrey.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isParent ? FontWeight.w600 : FontWeight.w500,
                      color: isParent ? Colors.blueGrey.shade800 : Colors.black87,
                    ),
                  ),
                ),
                if (isParent && hasChildren)
                  Icon(
                    isParentExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey,
                  )
                else
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildChildCategoryRow(BuildContext context, Map<String, dynamic> category) {
    final categoryName = category['category_name']?.toString() ?? 'Category';
    final raw = category['category_id'];
    final categoryId = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
    final icon = _getCategoryIcon(categoryName);
    final isExpanded = _expandedCategoryId == categoryId;
    final brands = _brandsByCategory[categoryId] ?? [];
    final loadingBrands = _loadingBrands[categoryId] == true;

    return Column(
      children: [
        InkWell(
          onTap: () => _navigateToCategory(context, category, brandFilter: null),
          child: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.only(left: 28, right: 12, top: 9, bottom: 9),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 15, color: Colors.blueGrey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey.shade700),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLivePromoCard(Color accent) {
    return Consumer<BannerProvider>(
      builder: (context, bp, _) {
        final title = bp.sidebarTitle;
        final subtitle = bp.sidebarSubtitle;
        final buttonText = bp.sidebarButtonText;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, Colors.red.shade900]),
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: const AssetImage('assets/images/carbon-fibre.png'),
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FlashSaleAll()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF424242),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _trustItem(Icons.shield, 'Official Warranty'),
          Divider(height: 20, color: Colors.white.withValues(alpha: 0.12), thickness: 1),
          _trustItem(Icons.headset_mic, '24/7 Tech Support'),
          Divider(height: 20, color: Colors.white.withValues(alpha: 0.12), thickness: 1),
          _trustItem(Icons.local_shipping, 'Fast Island-wide Delivery'),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

