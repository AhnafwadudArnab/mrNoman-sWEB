import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../All Pages/Registrations/login.dart';
import '../Provider/Admin_product_provider.dart';
import '../Provider/product_refresh_notifier.dart';
import '../pages/home_page.dart';
import '../utils/api_service.dart';
import '../utils/image_resolver.dart';
import 'A_customers.dart';
import 'Admin_sidebar.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';
import 'admin_update_product.dart';

class AdminProductUploadPage extends StatelessWidget {
  final bool embedded;
  final int? editProductId;

  const AdminProductUploadPage({
    super.key,
    this.embedded = false,
    this.editProductId,
  });

  static void _navigateFromSidebar(
    BuildContext context,
    AdminSidebarItem item,
  ) {
    if (item == AdminSidebarItem.products) return;
    AdminNav.go(context, item);
  }

  Widget _buildProductsContent(BuildContext context) {
    const Color cardBg = AdminTheme.surfaceAlt;
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              "Inventory Control & Upload",
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUpdateProductPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  label: const Text(
                    "Delete Products",
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.store,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  label: const Text(
                    "Back to Store",
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Expanded(child: _SectionSwitcherView()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBg = AdminTheme.bg;

    if (embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildProductsContent(context)),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.products,
      onItemSelected: (item) => _navigateFromSidebar(context, item),
      body: _buildProductsContent(context),
    );
  }
}

class _SectionSwitcherView extends StatefulWidget {
  const _SectionSwitcherView();

  @override
  State<_SectionSwitcherView> createState() => _SectionSwitcherViewState();
}

class _SectionSwitcherViewState extends State<_SectionSwitcherView> {
  static const List<String> _displayOptions = [
    'Best Selling',
    'Trendings',
    'Deals of the Day',
    'Flash Sale',
    'Tech Part',
    'Others',
    'Products List',
  ];

  static const Map<String, String> _displayToSection = {
    'Best Selling': 'Best Sellings',
    'Trendings': 'Trending Items',
    'Deals of the Day': 'Deals of the Day',
    'Flash Sale': 'Flash Sale',
    'Tech Part': 'Tech Part',
    'Others': 'Others',
  };

  String _selected = 'Best Selling';

  @override
  Widget build(BuildContext context) {
    const Color fieldBg = AdminTheme.surface;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Section',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _displayOptions.length,
            itemBuilder: (context, index) {
              final option = _displayOptions[index];
              final isSelected = _selected == option;
              final isProductsList = option == 'Products List';

              return GestureDetector(
                onTap: () {
                  if (isProductsList) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUpdateProductPage(),
                      ),
                    );
                  } else {
                    setState(() => _selected = option);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF7C3AED).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (isProductsList) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminUpdateProductPage(),
                            ),
                          );
                        } else {
                          setState(() => _selected = option);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isProductsList ? Icons.list : Icons.local_offer,
                              size: 28,
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : AdminTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (_selected != 'Products List')
            _SectionUploadCard(sectionTitle: _displayToSection[_selected]!),
        ],
      ),
    );
  }
}

class _SectionUploadCard extends StatefulWidget {
  final String sectionTitle;
  const _SectionUploadCard({required this.sectionTitle});

  @override
  State<_SectionUploadCard> createState() => _SectionUploadCardState();
}

class _SectionUploadCardState extends State<_SectionUploadCard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(
    text: '10',
  );
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(
    text: '20',
  );
  String _sort = 'newest';
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  int? _selectedCategoryId;
  int? _selectedBrandId;
  PlatformFile? _selectedFile;
  bool _loadingCategories = true;
  bool _publishing = false;
  bool _savingFilter = false;

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _powerWattController = TextEditingController();
  final TextEditingController _warrantyMonthsController =
      TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _lumensController = TextEditingController();
  final TextEditingController _colorTempController = TextEditingController();
  final TextEditingController _lengthMeterController = TextEditingController();
  final TextEditingController _gaugeAwgController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  bool _showInTechPart = true;

  static const Map<String, String> _sectionToApiKey = {
    'Best Sellings': 'best_sellers',
    'Flash Sale': 'flash_sale',
    'Trending Items': 'trending',
    'Deals of the Day': 'deals',
    'Tech Part': 'tech_part',
    // 'Others' intentionally unmapped; optional Tech Part assignment controlled by toggle
  };

  int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is Map && v.containsKey('brand_id')) return _intOrNull(v['brand_id']);
    if (v is Map && v.containsKey('category_id'))
      return _intOrNull(v['category_id']);
    return null;
  }

  int _toIntStrict(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return p;
    }
    throw FormatException('Invalid productId: $v');
  }

  int _extractProductIdFromResponse(Map<String, dynamic> res) {
    final productIdCandidate =
        res['productId'] ?? res['id'] ?? res['product_id'];
    try {
      return _toIntStrict(productIdCandidate);
    } catch (_) {
      // Try nested product object
      final prod = res['product'];
      if (prod is Map) {
        final nestedId = prod['product_id'] ?? prod['id'] ?? prod['productId'];
        return _toIntStrict(nestedId);
      }
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();
    // _loadSectionFilter();
    if (widget.sectionTitle != 'Others') _showInTechPart = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _limitController.dispose();
    _modelController.dispose();
    _powerWattController.dispose();
    _warrantyMonthsController.dispose();
    _colorController.dispose();
    _lumensController.dispose();
    _colorTempController.dispose();
    _lengthMeterController.dispose();
    _gaugeAwgController.dispose();
    _materialController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // Fetch categories from products endpoint (action=categories)
      final list =
          await ApiService.get('/products?action=categories', withAuth: false)
              as List;
      if (mounted) {
        setState(() {
          final raw = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final byName = <String, Map<String, dynamic>>{};
          for (final c in raw) {
            final id = _intOrNull(c['category_id']);
            final name = (c['category_name'] ?? '').toString().trim();
            if (id == null || id <= 0 || name.isEmpty) continue;
            final key = name.toLowerCase();
            final existing = byName[key];
            final existingId = _intOrNull(existing?['category_id']);
            if (existing == null || (existingId != null && existingId > id)) {
              byName[key] = {'category_id': id, 'category_name': name};
            }
          }
          final unique = byName.values.toList()
            ..sort(
              (a, b) =>
                  (a['category_name'] ?? '').toString().toLowerCase().compareTo(
                    (b['category_name'] ?? '').toString().toLowerCase(),
                  ),
            );
          _categories = unique;
          _loadingCategories = false;
          final stillExists = _categories.any(
            (c) => _intOrNull(c['category_id']) == _selectedCategoryId,
          );
          if (_categories.isNotEmpty &&
              (_selectedCategoryId == null || !stillExists)) {
            _selectedCategoryId = _intOrNull(_categories.first['category_id']);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadBrands() async {
    try {
      // Fetch brands from products endpoint (action=brands) and de-duplicate by name
      final list =
          await ApiService.get('/products?action=brands', withAuth: false)
              as List;
      if (mounted) {
        setState(() {
          final raw = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final byName = <String, Map<String, dynamic>>{};
          for (final b in raw) {
            final id = _intOrNull(b['brand_id']);
            final name = (b['brand_name'] ?? '').toString().trim();
            if (id == null || id <= 0 || name.isEmpty) continue;
            final key = name.toLowerCase();
            final existing = byName[key];
            final existingId = _intOrNull(existing?['brand_id']);
            if (existing == null || (existingId != null && existingId > id)) {
              byName[key] = {'brand_id': id, 'brand_name': name};
            }
          }
          final unique = byName.values.toList()
            ..sort(
              (a, b) => (a['brand_name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .compareTo((b['brand_name'] ?? '').toString().toLowerCase()),
            );
          _brands = unique;
          final stillExists = _brands.any(
            (b) => _intOrNull(b['brand_id']) == _selectedBrandId,
          );
          if (_brands.isNotEmpty &&
              (_selectedBrandId == null || !stillExists)) {
            _selectedBrandId = _intOrNull(_brands.first['brand_id']);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load brands: $e');
      // Non-critical — brands dropdown will be empty, user can still upload
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color fieldBg = AdminTheme.surface;
    const Color brandPurple = Color(0xFF7C3AED);

    // Provider Access
    final productProvider = Provider.of<AdminProductProvider>(context);
    final currentSectionProducts =
        productProvider.sectionProducts[widget.sectionTitle] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0x0D000000)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload to: ${widget.sectionTitle}",
            style: const TextStyle(
              color: brandPurple,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.sectionTitle == 'Best Sellings')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: A maximum of 4 items can be displayed in this section',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 14, 13, 13),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final formFields = Column(
                children: [
                  _customTextField(_nameController, "Product Name", fieldBg),
                  const SizedBox(height: 12),
                  _customTextField(
                    _priceController,
                    "Price (BDT)",
                    fieldBg,
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),
                  _customTextField(
                    _stockController,
                    "Stock Quantity",
                    fieldBg,
                    isNumber: true,
                  ),
                  const SizedBox(height: 12),
                  _customTextField(
                    _descController,
                    "Full Description",
                    fieldBg,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Product Details",
                      style: const TextStyle(color: AdminTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailsFields(fieldBg),
                ],
              );
              final imageAndDropdowns = Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0x0D000000)),
                      ),
                      child: _selectedFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FutureBuilder<Uint8List?>(
                                future: _selectedFile!.xFile
                                    .readAsBytes()
                                    .catchError((_) => Uint8List(0)),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6B7280),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo,
                              color: Color(0xFF6B7280),
                              size: 40,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    dropdownColor: fieldBg,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      border: InputBorder.none,
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    items: _loadingCategories
                        ? []
                        : _categories
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: _intOrNull(c['category_id']),
                                  child: Text(
                                    (c['category_name'] ?? '').toString(),
                                  ),
                                ),
                              )
                              .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: _selectedBrandId,
                    dropdownColor: fieldBg,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: fieldBg,
                      border: InputBorder.none,
                      labelText: 'Brand',
                      labelStyle: TextStyle(color: Color(0x73000000)),
                    ),
                    items: _brands
                        .map(
                          (b) => DropdownMenuItem<int>(
                            value: _intOrNull(b['brand_id']),
                            child: Text((b['brand_name'] ?? '').toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBrandId = v),
                  ),
                ],
              );
              return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageAndDropdowns,
                        const SizedBox(height: 16),
                        formFields,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: formFields),
                        const SizedBox(width: 20),
                        Expanded(child: imageAndDropdowns),
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          if (widget.sectionTitle == 'Others')
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Switch(
                    value: _showInTechPart,
                    onChanged: (v) => setState(() => _showInTechPart = v),
                    activeColor: brandPurple,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Show in Tech Part (home page section)',
                      style: TextStyle(color: Color(0x8A000000)),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: _publishing
                ? null
                : () => _handlePublish(productProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandPurple,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _publishing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AdminTheme.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    "Publish to ${widget.sectionTitle}",
                    style: const TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          // লাইভ প্রিভিউ সেকশন (নিচে দেখাবে কি কি আপলোড হয়েছে)
          if (currentSectionProducts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(color: Color(0x0D000000)),
            ),
            const Text(
              "Recently Published:",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentSectionProducts.length,
              itemBuilder: (context, index) {
                final p = currentSectionProducts[index];
                final hasBytes = p['image']?.bytes != null;
                final imageUrl = p['imageUrl'] as String?;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[700],
                    child: hasBytes
                        ? ClipOval(
                            child: Image.memory(
                              p['image'].bytes!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                color: Color(0x73000000),
                                size: 22,
                              ),
                            ),
                          )
                        : (imageUrl != null && imageUrl.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              ImageResolver.resolveUrl(imageUrl),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                color: Color(0x73000000),
                                size: 22,
                              ),
                            ),
                          )
                        : const Icon(Icons.image, color: Color(0x73000000)),
                  ),
                  title: Text(
                    p['name'],
                    style: const TextStyle(color: AdminTheme.textPrimary),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "৳ ${p['price']}",
                        style: const TextStyle(color: Colors.green),
                      ),
                      if ((p['category'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "Category: ${p['category']}",
                            style: const TextStyle(
                              color: Color(0x73000000),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if ((p['desc'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "${p['desc']}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showEditDialog(context, productProvider, index, p),
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF7C3AED),
                          size: 18,
                        ),
                        label: const Text(
                          'Update',
                          style: TextStyle(color: Color(0xFF7C3AED)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, productProvider, index),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AdminProductProvider provider,
    int index,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.surfaceAlt,
        title: const Text(
          'Remove product?',
          style: TextStyle(color: AdminTheme.textPrimary),
        ),
        content: const Text(
          'This will remove the product from this section.',
          style: TextStyle(color: Color(0x8A000000)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        provider.removeProduct(widget.sectionTitle, index);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text('Product removed'),
            ),
          );
        }
      }
    });
  }

  void _showEditDialog(
    BuildContext context,
    AdminProductProvider provider,
    int index,
    Map<String, dynamic> p,
  ) {
    final nameC = TextEditingController(text: '${p['name']}');
    final priceC = TextEditingController(text: '${p['price']}');
    final stockC = TextEditingController(text: '${p['stock'] ?? 0}');
    final descC = TextEditingController(text: '${p['desc']}');
    String category = p['category'] ?? 'Home Utility';
    PlatformFile? pickedFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminTheme.surfaceAlt,
              title: const Text(
                'Edit product',
                style: TextStyle(color: AdminTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameC,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Product name',
                          labelStyle: TextStyle(color: Color(0x73000000)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x1F000000)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceC,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Price (BDT)',
                          labelStyle: TextStyle(color: Color(0x73000000)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x1F000000)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: stockC,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          labelStyle: TextStyle(color: Color(0x73000000)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x1F000000)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descC,
                        maxLines: 2,
                        style: const TextStyle(color: AdminTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Color(0x73000000)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0x1F000000)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final List<String> catNames = _categories
                              .map((e) => (e['category_name'] ?? '').toString())
                              .where((e) => e.isNotEmpty)
                              .toSet()
                              .toList();
                          final String? selectedValue =
                              catNames.contains(category)
                              ? category
                              : (catNames.isNotEmpty ? catNames.first : null);
                          return DropdownButtonFormField<String>(
                            value: selectedValue,
                            dropdownColor: AdminTheme.surface,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              labelStyle: TextStyle(color: Color(0x73000000)),
                            ),
                            items: catNames
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => category = v ?? category),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final file = await FilePicker.pickFile(
                            type: FileType.image,
                          );
                          if (file != null) {
                            setDialogState(() => pickedFile = file);
                          }
                        },
                        icon: const Icon(
                          Icons.add_photo_alternate,
                          color: Color(0xFF7C3AED),
                        ),
                        label: const Text(
                          'Change image',
                          style: TextStyle(color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  onPressed: () {
                    if (nameC.text.trim().isEmpty ||
                        priceC.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and price required'),
                        ),
                      );
                      return;
                    }
                    final Map<String, dynamic> data = {
                      'name': nameC.text.trim(),
                      'price': priceC.text.trim(),
                      'stock': int.tryParse(stockC.text.trim()) ?? 0,
                      'stock_quantity': int.tryParse(stockC.text.trim()) ?? 0,
                      'desc': descC.text.trim(),
                      'category': category,
                      'imageUrl': pickedFile == null ? (p['imageUrl']) : null,
                    };
                    if (pickedFile != null) {
                      data['image'] = pickedFile;
                    } else if (p['image'] != null)
                      data['image'] = p['image'];
                    provider.updateProduct(widget.sectionTitle, index, data);
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('Product updated'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ইমেজ সিলেক্ট করার ফাংশন
  Future<void> _pickImage() async {
    PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
    if (file != null) setState(() => _selectedFile = file);
  }

  // পাবলিশ করার ফাংশন - API তে সেভ করে তারপর সেকশনে অ্যাসাইন করে
  Future<void> _handlePublish(AdminProductProvider provider) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AdminTheme.surfaceAlt,
          title: const Text(
            'Admin login required',
            style: TextStyle(color: AdminTheme.textPrimary),
          ),
          content: const Text(
            'Please login as admin to publish products.',
            style: TextStyle(color: Color(0x8A000000)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LogIn()),
                  (route) => false,
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product name and price required!")),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category.")),
      );
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add an image file!")));
      return;
    }
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter a valid price.")));
      return;
    }

    setState(() => _publishing = true);
    try {
      final specs = _buildSpecsForSelectedCategory();
      final stockQty = int.tryParse(_stockController.text.trim()) ?? 0;
      // Read bytes asynchronously from the selected file
      final imageBytes = _selectedFile != null
          ? await _selectedFile!.readAsBytes()
          : null;

      final res = await ApiService.createProductWithImage(
        product_name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        stock_quantity: stockQty,
        category_id: _intOrNull(_selectedCategoryId),
        brand_id: _intOrNull(_selectedBrandId),
        image_url: null,
        imageBytes: imageBytes,
        imageFileName: _selectedFile?.name,
        specs: specs.isEmpty ? null : specs,
      );
      final productId = _extractProductIdFromResponse(
        Map<String, dynamic>.from(res),
      );

      final sectionKey = _sectionToApiKey[widget.sectionTitle];
      try {
        if (sectionKey != null) {
          await ApiService.updateProductSections(productId, {sectionKey: true});
        } else if (widget.sectionTitle == 'Others' && _showInTechPart) {
          await ApiService.updateProductSections(productId, {
            'tech_part': true,
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange,
              content: Text(
                'Product created, but section assignment failed: $e',
              ),
            ),
          );
        }
      }

      final serverProduct = (res['product'] is Map)
          ? Map<String, dynamic>.from(res['product'])
          : null;

      // Get image URL from server response — check root level and nested product
      String? imageUrl;
      final rawImageUrl = (res['image_url'] ?? serverProduct?['image_url'])
          ?.toString();
      if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
        imageUrl = ImageResolver.resolveUrl(rawImageUrl);
      }

      final productData = serverProduct != null
          ? {
              "id": "server_$productId",
              "name": (serverProduct['product_name'] ?? '').toString(),
              "price": (serverProduct['price'] ?? '').toString(),
              "stock": serverProduct['stock_quantity'] ?? 0,
              "stock_quantity": serverProduct['stock_quantity'] ?? 0,
              "desc": (serverProduct['description'] ?? '').toString(),
              "category": (serverProduct['category_name'] ?? '').toString(),
              "imageUrl": imageUrl ?? '',
              "image": _selectedFile,
            }
          : {
              "name": _nameController.text.trim(),
              "price": _priceController.text.trim(),
              "stock": int.tryParse(_stockController.text.trim()) ?? 0,
              "stock_quantity": int.tryParse(_stockController.text.trim()) ?? 0,
              "desc": _descController.text.trim(),
              "category": () {
                for (final c in _categories) {
                  if (c['category_id'] == _selectedCategoryId) {
                    return (c['category_name'] ?? '').toString();
                  }
                }
                return '';
              }(),
              "image": _selectedFile,
              "imageUrl": imageUrl ?? '',
            };
      provider.addProduct(widget.sectionTitle, productData);

      // Notify all product section widgets to reload fresh data from server
      if (mounted) {
        context.read<ProductRefreshNotifier>().refresh();
      }

      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _descController.clear();
      _imageUrlController.clear();
      _modelController.clear();
      _powerWattController.clear();
      _warrantyMonthsController.clear();
      _colorController.clear();
      _lumensController.clear();
      _colorTempController.clear();
      _lengthMeterController.clear();
      _gaugeAwgController.clear();
      _materialController.clear();
      _sizeController.clear();
      setState(() => _selectedFile = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("${widget.sectionTitle}-এ আপলোড সফল হয়েছে!"),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Upload failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _saveSectionFilter() async {}

  Widget _customTextField(
    TextEditingController controller,
    String hint,
    Color bg, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AdminTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 14),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDetailsFields(Color bg) {
    final catName = () {
      for (final c in _categories) {
        if (c['category_id'] == _selectedCategoryId)
          return (c['category_name'] ?? '').toString();
      }
      return '';
    }().toLowerCase();
    final isKitchen = catName.contains('kitchen');
    final isPersonal = catName.contains('personal');
    final isHome = catName.contains('home');
    final isLighting = catName.contains('lighting');
    final isTools = catName.contains('tools');
    final isWiring = catName.contains('wiring');

    final List<Widget> fields = [];
    if (isKitchen || isHome) {
      fields.addAll([
        _customTextField(_modelController, "Model", bg),
        const SizedBox(height: 8),
        _customTextField(
          _powerWattController,
          "Power (Watt)",
          bg,
          isNumber: true,
        ),
        const SizedBox(height: 8),
        _customTextField(
          _warrantyMonthsController,
          "Warranty (months)",
          bg,
          isNumber: true,
        ),
      ]);
    }
    if (isPersonal || isHome || isTools) {
      if (fields.isNotEmpty) fields.add(const SizedBox(height: 8));
      fields.add(_customTextField(_colorController, "Color", bg));
    }
    if (isLighting) {
      if (fields.isNotEmpty) fields.add(const SizedBox(height: 8));
      fields.addAll([
        _customTextField(_lumensController, "Lumens", bg, isNumber: true),
        const SizedBox(height: 8),
        _customTextField(
          _colorTempController,
          "Color Temperature (K)",
          bg,
          isNumber: true,
        ),
        const SizedBox(height: 8),
        _customTextField(
          _powerWattController,
          "Power (Watt)",
          bg,
          isNumber: true,
        ),
      ]);
    }
    if (isTools) {
      if (fields.isNotEmpty) fields.add(const SizedBox(height: 8));
      fields.addAll([
        _customTextField(_materialController, "Material", bg),
        const SizedBox(height: 8),
        _customTextField(_sizeController, "Size", bg),
      ]);
    }
    if (isWiring) {
      if (fields.isNotEmpty) fields.add(const SizedBox(height: 8));
      fields.addAll([
        _customTextField(
          _lengthMeterController,
          "Length (meter)",
          bg,
          isNumber: true,
        ),
        const SizedBox(height: 8),
        _customTextField(
          _gaugeAwgController,
          "Gauge (AWG)",
          bg,
          isNumber: true,
        ),
        const SizedBox(height: 8),
        _customTextField(_materialController, "Material", bg),
      ]);
    }
    if (fields.isEmpty) {
      fields.addAll([
        _customTextField(_modelController, "Model (optional)", bg),
      ]);
    }
    return Column(children: fields);
  }

  Map<String, dynamic> _buildSpecsForSelectedCategory() {
    final Map<String, dynamic> m = {};
    void put(String k, TextEditingController c, {bool number = false}) {
      final t = c.text.trim();
      if (t.isEmpty) return;
      m[k] = number ? (double.tryParse(t) ?? t) : t;
    }

    put('model', _modelController);
    put('power_watt', _powerWattController, number: true);
    put('warranty_months', _warrantyMonthsController, number: true);
    put('color', _colorController);
    put('lumens', _lumensController, number: true);
    put('color_temperature_k', _colorTempController, number: true);
    put('length_meter', _lengthMeterController, number: true);
    put('gauge_awg', _gaugeAwgController, number: true);
    put('material', _materialController);
    put('size', _sizeController);

    // Return empty map if no specs are filled
    if (m.isEmpty) {
      return {};
    }

    return m;
  }
}
