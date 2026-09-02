import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../utils/api_service.dart';
import 'Admin_sidebar.dart';
import 'A_customers.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminCollectionsPage extends StatefulWidget {
  final bool embedded;
  const AdminCollectionsPage({super.key, this.embedded = false});

  @override
  State<AdminCollectionsPage> createState() => _AdminCollectionsPageState();
}

class _AdminCollectionsPageState extends State<AdminCollectionsPage> {
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _selectedCollectionProducts = [];
  Map<String, dynamic>? _selectedCollection;
  bool _collectionsLoading = true;
  bool _productsLoading = false;
  String? _error;

  late TextEditingController _productNameController;
  late TextEditingController _productPriceController;
  late TextEditingController _productDescriptionController;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _productPriceController = TextEditingController();
    _productDescriptionController = TextEditingController();
    _loadCollections();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _collectionsLoading = true;
      _error = null;
    });
    try {
      final collections = await ApiService.getCollections();
      setState(() {
        _collections = collections
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _collectionsLoading = false;
        if (_collections.isNotEmpty && _selectedCollection == null) {
          _selectedCollection = _collections[0];
          _loadCollectionProducts(_collections[0]['id']);
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _collectionsLoading = false;
      });
    }
  }

  Future<void> _loadCollectionProducts(int collectionId) async {
    setState(() {
      _productsLoading = true;
    });
    try {
      final products = await ApiService.getCollectionProducts(collectionId);
      setState(() {
        _selectedCollectionProducts = products
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _productsLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _productsLoading = false;
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (_selectedCollection == null) {
      _showSnackBar('Please select a collection first', isError: true);
      return;
    }

    final name = _productNameController.text.trim();
    final price = _productPriceController.text.trim();
    final description = _productDescriptionController.text.trim();

    if (name.isEmpty || price.isEmpty) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    try {
      final productData = {
        'name': name,
        'price': double.parse(price),
        'description': description,
        'collection_id': _selectedCollection!['id'],
      };

      await ApiService.createProduct(productData);

      if (mounted) {
        _showSnackBar('Product uploaded successfully! 🎉', isError: false);
        _productNameController.clear();
        _productPriceController.clear();
        _productDescriptionController.clear();
        _clearImage();
        _loadCollectionProducts(_selectedCollection!['id']);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error uploading product: $e', isError: true);
      }
    }
  }

  void _selectCollection(Map<String, dynamic> collection) {
    setState(() {
      _selectedCollection = collection;
    });
    _loadCollectionProducts(collection['id']);
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

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _collectionsLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                )
              : _error != null
              ? _buildErrorState()
              : _buildMainContent(),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: AdminTheme.bg,
        child: SizedBox.expand(child: content),
      );
    }

    return AdminScaffold(
      selected: AdminSidebarItem.collections,
      onItemSelected: _onCollectionItemSelected,
      body: content,
    );
  }

  Widget _buildHeader() {
    const brandPurple = Color(0xFF7C3AED);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AdminTheme.surface, AdminTheme.surface.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: AdminTheme.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brandPurple.withOpacity(0.3), width: 1),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: brandPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collections Management',
                  style: GoogleFonts.hindSiliguri(
                    color: AdminTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload products and manage your collections',
                  style: GoogleFonts.hindSiliguri(
                    color: AdminTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AdminTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AdminTheme.border.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // ============ RED SECTION: UPLOAD PRODUCT ============
            _buildUploadSection(),

            // Divider
            Container(height: 2, color: Colors.red.withOpacity(0.3)),

            // ============ BLUE SECTION: COLLECTIONS TABS ============
            _buildCollectionsSection(),

            // Divider
            Container(height: 2, color: Colors.blue.withOpacity(0.3)),

            // ============ YELLOW SECTION: PRODUCTS LIST ============
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  // ============ UPLOAD SECTION: UPLOAD PRODUCT ============
  Widget _buildUploadSection() {
    const sectionColor = Color(0xFF7C3AED);
    return Container(
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: sectionColor.withOpacity(0.3), width: 2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: sectionColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Upload New Product',
                style: GoogleFonts.hindSiliguri(
                  color: AdminTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Form Fields
          Column(
            children: [
              // Row 1: Product Name & Price & Upload Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Product Name
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Name',
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _productNameController,
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Product name',
                            hintStyle: GoogleFonts.hindSiliguri(
                              color: AdminTheme.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.shopping_bag_rounded,
                              size: 18,
                              color: sectionColor,
                            ),
                            filled: true,
                            fillColor: AdminTheme.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AdminTheme.border.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AdminTheme.border.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: sectionColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price',
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _productPriceController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Price',
                            hintStyle: GoogleFonts.hindSiliguri(
                              color: AdminTheme.textMuted,
                            ),
                            prefixIcon: const Icon(
                              Icons.attach_money_rounded,
                              size: 18,
                              color: sectionColor,
                            ),
                            filled: true,
                            fillColor: AdminTheme.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AdminTheme.border.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AdminTheme.border.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: sectionColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Upload Button
                  ElevatedButton.icon(
                    onPressed: _uploadProduct,
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sectionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description (Optional)',
                    style: GoogleFonts.hindSiliguri(
                      color: AdminTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _productDescriptionController,
                    maxLines: 2,
                    style: GoogleFonts.hindSiliguri(
                      color: AdminTheme.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Product description',
                      hintStyle: GoogleFonts.hindSiliguri(
                        color: AdminTheme.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      filled: true,
                      fillColor: AdminTheme.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AdminTheme.border.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AdminTheme.border.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image Picker Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Image (Optional)',
                    style: GoogleFonts.hindSiliguri(
                      color: AdminTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Image Preview
                      if (_selectedImageBytes != null)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AdminTheme.border.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: MemoryImage(_selectedImageBytes!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AdminTheme.surfaceAlt,
                            border: Border.all(
                              color: AdminTheme.border.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Buttons Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedImageBytes != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected: $_selectedImageName',
                                    style: GoogleFonts.hindSiliguri(
                                      color: AdminTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(
                                    Icons.image_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Pick Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                if (_selectedImageBytes != null) ...[
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _clearImage,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Clear'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ BLUE SECTION: COLLECTIONS TABS ============
  Widget _buildCollectionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withOpacity(0.3), width: 2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
                      color: Colors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collections',
                        style: GoogleFonts.hindSiliguri(
                          color: AdminTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Click to select a collection',
                        style: GoogleFonts.hindSiliguri(
                          color: AdminTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_collections.length}',
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Collections Scroll
          SizedBox(
            height: 120,
            child: _collections.isEmpty
                ? Center(
                    child: Text(
                      'No collections available',
                      style: GoogleFonts.hindSiliguri(
                        color: AdminTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_collections.length, (index) {
                        final collection = _collections[index];
                        final isSelected =
                            _selectedCollection?['id'] == collection['id'];

                        // Different colors for each collection
                        final colors = [
                          const Color(0xFF7C3AED),
                          Colors.red,
                          Colors.green,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                        ];
                        final color = colors[index % colors.length];

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectCollection(collection),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -15,
                                      bottom: -15,
                                      child: Icon(
                                        Icons.category_rounded,
                                        size: 70,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.category_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                collection['name'] ?? 'Unknown',
                                                style: GoogleFonts.hindSiliguri(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${collection['product_count'] ?? 0} items',
                                                style: GoogleFonts.hindSiliguri(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============ YELLOW SECTION: PRODUCTS LIST ============
  Widget _buildProductsSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: GoogleFonts.hindSiliguri(
                          color: AdminTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (_selectedCollection != null)
                        Text(
                          'From: ${_selectedCollection!['name'] ?? 'Unknown'}',
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedCollectionProducts.length}',
                  style: GoogleFonts.hindSiliguri(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Products List
          SizedBox(
            height: 300,
            child: _productsLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  )
                : _selectedCollectionProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_rounded,
                          size: 48,
                          color: AdminTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Products in this Collection',
                          style: GoogleFonts.hindSiliguri(
                            color: AdminTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedCollectionProducts.length,
                    itemBuilder: (context, index) {
                      final product = _selectedCollectionProducts[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Unknown',
                                      style: GoogleFonts.hindSiliguri(
                                        color: AdminTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product['description'] ?? '',
                                      style: GoogleFonts.hindSiliguri(
                                        color: AdminTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Price
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '৳${product['price'] ?? '0'}',
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.green,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminTheme.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AdminTheme.error.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AdminTheme.error,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Collections',
            style: GoogleFonts.hindSiliguri(
              color: AdminTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.hindSiliguri(
              color: AdminTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCollections,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

