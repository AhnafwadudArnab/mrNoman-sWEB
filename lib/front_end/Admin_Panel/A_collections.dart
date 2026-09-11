import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/image_resolver.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

// ============================================================
// DESIGN TOKENS - Collections Page
// ============================================================
class _C {
  static const bg = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF1A1D23);
  static const textSub = Color(0xFF374151);
  static const textMuted = Color(0xFF6B7280);
  static const brand = AdminTheme.brand;

  // Collection card colors (4-color palette, indexed)
  static const List<Color> collectionBgs = [
    Color(0xFFE7EDF4), // Light blue
    Color(0xFFF0FDF4), // Light green
    Color(0xFFFFF7ED), // Light orange
    Color(0xFFF3F4F6), // Light gray
  ];

  static const List<Color> collectionAccents = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF97316), // Orange
    Color(0xFF6B7280), // Gray
  ];

  static Color collectionBg(int index) =>
      collectionBgs[index % collectionBgs.length];
  static Color collectionAccent(int index) =>
      collectionAccents[index % collectionAccents.length];
}

class AdminCollectionsPage extends StatefulWidget {
  final bool embedded;
  const AdminCollectionsPage({super.key, this.embedded = false});

  @override
  State<AdminCollectionsPage> createState() => _AdminCollectionsPageState();
}

class _AdminCollectionsPageState extends State<AdminCollectionsPage> {
  // ========== STATE ==========
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _selectedCollectionProducts = [];
  Map<String, dynamic>? _selectedCollection;
  bool _collectionsLoading = true;
  bool _productsLoading = false;
  String? _error;

  late TextEditingController _productNameController;
  late TextEditingController _productPriceController;
  late TextEditingController _productRegularPriceController;
  late TextEditingController _productStockController;
  late TextEditingController _productDescriptionController;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  int? _selectedCategoryId;
  int? _selectedBrandId;

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productPriceController = TextEditingController();
    _productRegularPriceController = TextEditingController();
    _productStockController = TextEditingController(text: '10');
    _productDescriptionController = TextEditingController();
    _loadCollections();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final cats = await ApiService.getCategories();
      final brs = await ApiService.getBrands();
      if (mounted) {
        setState(() {
          _categories = cats
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _brands = brs
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_categories.isNotEmpty && _selectedCategoryId == null) {
            _selectedCategoryId = _categories.first['category_id'] as int?;
          }
          if (_brands.isNotEmpty && _selectedBrandId == null) {
            _selectedBrandId = _brands.first['brand_id'] as int?;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories/brands: $e');
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productRegularPriceController.dispose();
    _productStockController.dispose();
    _productDescriptionController.dispose();
    super.dispose();
  }

  int _getCollectionId(dynamic item) {
    if (item == null) return 0;
    if (item is int) return item;
    if (item is String) return int.tryParse(item) ?? 0;
    if (item is Map) {
      final v = item['collection_id'] ?? item['id'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  // ========== DATA LOADING ==========
  Future<void> _loadCollections() async {
    if (!mounted) return;
    setState(() {
      _collectionsLoading = true;
      _error = null;
    });
    try {
      final collections = await ApiService.getCollections();
      if (!mounted) return;

      setState(() {
        _collections = collections
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _collectionsLoading = false;
        if (_collections.isNotEmpty && _selectedCollection == null) {
          _selectedCollection = _collections[0];
        }
      });

      // Load products for the first collection after setState completes
      if (_collections.isNotEmpty && mounted) {
        final collectionId = _getCollectionId(_collections[0]);
        if (collectionId != 0) {
          await _loadCollectionProducts(collectionId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _collectionsLoading = false;
      });
    }
  }

  Future<void> _loadCollectionProducts(int collectionId) async {
    setState(() {
      _productsLoading = true;
      _error = null; // Clear any previous errors
    });
    try {
      final products = await ApiService.getCollectionProducts(collectionId);
      if (mounted) {
        setState(() {
          _selectedCollectionProducts = products
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _productsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Don't show error in main UI, just show empty products
          _selectedCollectionProducts = [];
          _productsLoading = false;
          _showSnackBar('Error loading products: $e', isError: true);
        });
      }
    }
  }

  Future<void> _uploadProduct() async {
    final collectionId = _getCollectionId(_selectedCollection);
    if (collectionId == 0) {
      _showSnackBar('Please select a collection first', isError: true);
      return;
    }

    final name = _productNameController.text.trim();
    final price = _productPriceController.text.trim();
    final regularPrice = double.tryParse(_productRegularPriceController.text.trim());
    final stock = int.tryParse(_productStockController.text.trim()) ?? 10;
    final description = _productDescriptionController.text.trim();

    if (name.isEmpty || price.isEmpty) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    try {
      String imageUrl = 'assets/prod/09.png';
      if (_selectedImageBytes != null && _selectedImageName != null) {
        try {
          imageUrl = await ApiService.uploadImage(
            _selectedImageBytes!,
            _selectedImageName!,
          );
        } catch (uploadErr) {
          debugPrint('Image upload failed, fallback to default: $uploadErr');
        }
      }

      final productData = <String, dynamic>{
        'product_name': name,
        'price': double.tryParse(price) ?? 0.0,
        if (regularPrice != null && regularPrice > 0) 'regular_price': regularPrice,
        'stock_quantity': stock,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedBrandId != null) 'brand_id': _selectedBrandId,
        'description': description,
        'image_url': imageUrl,
      };

      final created = await ApiService.post('/products', productData, withAuth: true);
      int? productId;
      if (created is Map) {
        final rawId = created['product_id'] ?? created['productId'] ?? created['id'];
        if (rawId is int) {
          productId = rawId;
        } else if (rawId is String) {
          productId = int.tryParse(rawId);
        }
      }

      if (productId != null && productId > 0) {
        await ApiService.linkCollectionProduct(collectionId, productId);
      }

      // Invalidate collection products cache for this collection
      ApiService.invalidateCache('/products');
      ApiService.invalidateCache('/collection-products');
      ApiService.invalidateCache('/collection_products');
      ApiService.invalidateCache('/collections');

      if (mounted) {
        _showSnackBar('Product uploaded & added to collection! ✓', isError: false);
        _productNameController.clear();
        _productPriceController.clear();
        _productRegularPriceController.clear();
        _productStockController.text = '10';
        _productDescriptionController.clear();
        _clearImage();
        _loadCollectionProducts(collectionId);
        _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error uploading product: $e', isError: true);
      }
    }
  }

  Future<void> _removeProductFromCollection(Map<String, dynamic> product) async {
    final collectionId = _getCollectionId(_selectedCollection);
    final rawProdId = product['product_id'] ?? product['id'];
    final productId = rawProdId is int ? rawProdId : int.tryParse(rawProdId?.toString() ?? '') ?? 0;
    if (collectionId == 0 || productId == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Product'),
        content: Text('Remove "${product['name'] ?? product['product_name'] ?? 'Product'}" from this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.unlinkCollectionProduct(collectionId, productId);
      if (mounted) {
        _showSnackBar('Product removed from collection', isError: false);
        _loadCollectionProducts(collectionId);
        _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to remove: $e', isError: true);
      }
    }
  }

  void _showAddCollectionDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.surface,
        title: const Text('Add Collection', style: TextStyle(color: _C.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Collection Name *',
                hintText: 'e.g. Summer Essentials',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Our hottest picks for this season',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.brand,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              try {
                await ApiService.createCollection({
                  'name': name,
                  'description': descCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  _showSnackBar('Collection created successfully! ✓', isError: false);
                  _loadCollections();
                }
              } catch (e) {
                if (mounted) {
                  _showSnackBar('Failed to create collection: $e', isError: true);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _selectCollection(Map<String, dynamic> collection) {
    setState(() {
      _selectedCollection = collection;
    });
    final collectionId = _getCollectionId(collection);
    if (collectionId != 0) {
      _loadCollectionProducts(collectionId);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
        _showSnackBar('Image selected: ${pickedFile.name}', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminTheme.error : Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onCollectionItemSelected(AdminSidebarItem item) {
    AdminNav.go(context, item);
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(color: _C.bg, child: _buildContent());
    }
    return AdminScaffold(
      selected: AdminSidebarItem.collections,
      onItemSelected: _onCollectionItemSelected,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      color: _C.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          Expanded(
            child: _collectionsLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _C.brand),
                  )
                : _error != null
                ? _buildErrorState()
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Collections',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _showAddCollectionDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.brand,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.brand.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border),
            ),
            child: Text(
              '${_collections.length} collections',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collections cards grid
          _buildCollectionsGrid(),
          const SizedBox(height: 24),

          // Upload section
          _buildUploadCard(),
          const SizedBox(height: 24),

          // Products section
          _buildProductsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ========== COLLECTIONS GRID ==========
  Widget _buildCollectionsGrid() {
    if (_collections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 48, color: _C.textMuted),
            const SizedBox(height: 16),
            Text(
              'No collections found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first collection to get started',
              style: TextStyle(fontSize: 13, color: _C.textMuted),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _collections.length,
        itemBuilder: (context, index) {
          final collection = _collections[index];
          final isSelected =
              _selectedCollection?['collection_id'] ==
              collection['collection_id'];
          final accent = _C.collectionAccent(index);
          final bg = _C.collectionBg(index);

          return Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: SizedBox(
              width: 140,
              child: _buildCollectionCard(
                collection: collection,
                isSelected: isSelected,
                accent: accent,
                bg: bg,
                onTap: () => _selectCollection(collection),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionCard({
    required Map<String, dynamic> collection,
    required bool isSelected,
    required Color accent,
    required Color bg,
    required VoidCallback onTap,
  }) {
    final productCount = collection['product_count'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? accent : bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : _C.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header row: icon + count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          size: 16,
                          color: isSelected ? Colors.white : accent,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$productCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : accent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Collection name
                  Text(
                    collection['name'] ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _C.textPrimary,
                    ),
                  ),

                  // Footer: item count label
                  Text(
                    productCount == 1 ? '1 item' : '$productCount items',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.75)
                          : _C.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== UPLOAD CARD ==========
  Widget _buildUploadCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.brand.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: 20,
                  color: _C.brand,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Responsive form layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 640;

              // Form fields list
              final formFields = [
                _buildFormField(
                  label: 'Product Name *',
                  controller: _productNameController,
                  hint: 'Enter product name',
                  icon: Icons.shopping_bag_rounded,
                  keyboardType: TextInputType.text,
                ),
                _buildFormField(
                  label: 'Price (BDT) *',
                  controller: _productPriceController,
                  hint: 'Sale price',
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                _buildFormField(
                  label: 'Previous Price (BDT - optional)',
                  controller: _productRegularPriceController,
                  hint: 'Regular price before discount',
                  icon: Icons.price_change_outlined,
                  keyboardType: TextInputType.number,
                ),
                _buildFormField(
                  label: 'Stock Quantity *',
                  controller: _productStockController,
                  hint: 'e.g. 10',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: TextInputType.number,
                ),
                _buildDropdownField<int>(
                  label: 'Category',
                  value: _selectedCategoryId,
                  icon: Icons.keyboard_arrow_down_rounded,
                  items: _categories.map((c) {
                    final id = c['category_id'] is int ? c['category_id'] as int : int.tryParse(c['category_id']?.toString() ?? '');
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(c['category_name']?.toString() ?? 'Category'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                _buildDropdownField<int>(
                  label: 'Brand',
                  value: _selectedBrandId,
                  icon: Icons.keyboard_arrow_down_rounded,
                  items: _brands.map((b) {
                    final id = b['brand_id'] is int ? b['brand_id'] as int : int.tryParse(b['brand_id']?.toString() ?? '');
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(b['brand_name']?.toString() ?? 'Brand'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedBrandId = v),
                ),
                _buildFormField(
                  label: 'Description (Optional)',
                  controller: _productDescriptionController,
                  hint: 'Enter product description',
                  icon: Icons.description_rounded,
                  keyboardType: TextInputType.text,
                  maxLines: 2,
                ),
              ];

              if (isMobile) {
                // Stack vertically on mobile
                return Column(
                  children: [
                    ...formFields,
                    const SizedBox(height: 16),
                    _buildImagePickerSection(fullWidth: true),
                  ],
                );
              } else {
                // 2-column layout on desktop
                return Column(
                  children: [
                    // Row 1: Name + Category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: formFields[0]),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: formFields[4]),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 2: Price + Previous Price + Stock + Brand
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: formFields[1]),
                        const SizedBox(width: 12),
                        Expanded(child: formFields[2]),
                        const SizedBox(width: 12),
                        Expanded(child: formFields[3]),
                        const SizedBox(width: 12),
                        Expanded(child: formFields[5]),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Row 3: Description
                    formFields[6],
                    const SizedBox(height: 16),

                    // Row 4: Image picker
                    _buildImagePickerSection(fullWidth: false),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: _C.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: _C.textMuted),
            filled: true,
            fillColor: _C.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _C.brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              items: items,
              onChanged: onChanged,
              icon: Icon(icon, size: 18, color: _C.textMuted),
              style: const TextStyle(fontSize: 13, color: _C.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSection({required bool fullWidth}) {
    if (!fullWidth) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Large image preview container (yellow box on left)
          Expanded(
            flex: 5,
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.5),
                color: _C.bg,
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 54,
                            color: _C.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No image selected',
                            style: TextStyle(
                              fontSize: 13,
                              color: _C.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),

          // Right: Upload control box matching left container (soman hobe)
          Expanded(
            flex: 6,
            child: Container(
              height: 230,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border, width: 1.5),
                color: _C.bg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Pick Image & Clear buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_rounded, size: 18),
                            label: const Text('Pick Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (_selectedImageBytes != null) ...[
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: _clearImage,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Clear'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _C.textMuted,
                                side: const BorderSide(color: _C.border),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImageBytes != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Selected: $_selectedImageName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'Supported formats: JPG, PNG, WEBP (Max 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _C.textMuted,
                          ),
                        ),
                    ],
                  ),

                  // Bottom: Upload Product button inside purple box area
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _uploadProduct,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: const Text(
                        'Upload Product',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border, width: 1.5),
            color: _C.bg,
          ),
          child: _selectedImageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.memory(
                    _selectedImageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 48, color: _C.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: _C.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_rounded, size: 18),
                label: const Text('Pick Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_selectedImageBytes != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.textMuted,
                  side: const BorderSide(color: _C.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_selectedImageBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected: $_selectedImageName',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: _C.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _buildUploadButton(),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _uploadProduct,
      icon: const Icon(Icons.upload_rounded, size: 18),
      label: const Text('Upload Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _C.brand,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  // ========== PRODUCTS CARD ==========
  Widget _buildProductsCard() {
    if (_selectedCollection == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: _C.textMuted),
            const SizedBox(height: 16),
            Text(
              'Select a collection to view products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_productsLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: const Center(child: CircularProgressIndicator(color: _C.brand)),
      );
    }

    if (_selectedCollectionProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: _C.textMuted),
            const SizedBox(height: 16),
            Text(
              'No products in this collection yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first product using the form above',
              style: TextStyle(fontSize: 13, color: _C.textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.list_rounded, size: 20, color: _C.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.brand.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_selectedCollectionProducts.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedCollectionProducts.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: _C.border.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final product = _selectedCollectionProducts[index];
              return _buildProductRow(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    final name = product['name'] ?? product['product_name'] ?? 'Unknown';
    final price = product['price'] ?? 0;
    final description = product['description'] ?? '';
    final rawImg = product['image_url'] ?? product['image'] ?? '';
    final imgUrl = ImageResolver.resolveUrl(rawImg.toString());

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Product icon / image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _C.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_rounded,
                        size: 24,
                        color: _C.textMuted,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_rounded,
                      size: 24,
                      color: _C.textMuted,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: _C.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Price badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              '৳$price',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Remove from collection',
            onPressed: () => _removeProductFromCollection(product),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AdminTheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading collections',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _C.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCollections,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
