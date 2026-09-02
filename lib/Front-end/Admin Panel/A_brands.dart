import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/api_service.dart';
import '../utils/image_resolver.dart';
import 'Admin_sidebar.dart';
import 'A_customers.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminBrandsPage extends StatefulWidget {
  final bool embedded;
  const AdminBrandsPage({super.key, this.embedded = false});

  @override
  State<AdminBrandsPage> createState() => _AdminBrandsPageState();
}

class _AdminBrandsPageState extends State<AdminBrandsPage> {
  List<Map<String, dynamic>> _brands = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final brands = await ApiService.getBrands();
      setState(() {
        _brands = brands
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showBrandDialog({Map<String, dynamic>? brand}) async {
    final nameController = TextEditingController(
      text: brand?['brand_name'] ?? '',
    );
    Uint8List? pickedBytes;
    String? pickedFileName;
    // Keep existing logo path for display
    String existingLogo = brand?['brand_logo']?.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AdminTheme.surfaceAlt,
          title: Text(
            brand == null ? 'Add Brand' : 'Edit Brand',
            style: const TextStyle(color: AdminTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration:  InputDecoration(
                    labelText: 'Brand Name',
                    labelStyle: TextStyle(color: Color(0x8A000000)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0x1F000000)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Logo preview
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: pickedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            pickedBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : existingLogo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageResolver.image(
                            imageUrl: existingLogo,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.business,
                            color: AdminTheme.textMuted,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Pick image button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      pickedBytes != null
                          ? 'Change Image'
                          : 'Pick Logo from Device',
                    ),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        final bytes = await file.readAsBytes();
                        setS(() {
                          pickedBytes = bytes;
                          pickedFileName = file.name;
                        });
                      }
                    },
                  ),
                ),
                if (pickedBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      pickedFileName ?? '',
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final brandName = nameController.text.trim();
      if (brandName.isEmpty) return;

      var logoPath = existingLogo;
      if (pickedBytes != null && pickedFileName != null) {
        logoPath = await ApiService.uploadImage(pickedBytes!, pickedFileName!);
      }

      final data = {
        'brand_name': brandName,
        if (logoPath.isNotEmpty) 'brand_logo': logoPath,
      };
      if (brand == null) {
        await ApiService.createBrand(data);
      } else {
        await ApiService.updateBrand(brand['brand_id'], data);
      }
      ApiService.invalidateCache('/brands');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(brand == null ? 'Brand added' : 'Brand updated'),
          ),
        );
        _loadBrands();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteBrand(Map<String, dynamic> brand) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.surfaceAlt,
        title: const Text(
          'Delete Brand',
          style: TextStyle(color: AdminTheme.textPrimary),
        ),
        content: Text(
          'Delete "${brand['brand_name']}"? This will affect ${brand['product_count'] ?? 0} products.',
          style: const TextStyle(color: AdminTheme.textMuted),
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
    );

    if (confirm == true) {
      try {
        await ApiService.deleteBrand(brand['brand_id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Brand deleted'),
            ),
          );
          _loadBrands();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
          );
        }
      }
    }
  }

  static void _navigateFromSidebar(
    BuildContext context,
    AdminSidebarItem item,
  ) {
    AdminNav.go(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final Color darkBg = AdminTheme.bg;
    const Color cardBg = AdminTheme.surfaceAlt;
    const Color brandOrange = Color(0xFF7C3AED);

    final content = Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Brand Management',
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showBrandDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Brand'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: AdminTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, color: brandOrange),
                  onPressed: _loadBrands,
                ),
              ],
            ),
          ],
        ),
        if (AdminScaffold.isMobileScreen(context))
          _mobileBrandToolbar(brandOrange),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: brandOrange),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        color: AdminTheme.error,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AdminTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBrands,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _brands.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No brands yet',
                        style: TextStyle(color: AdminTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _showBrandDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Brand'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandOrange,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 400
                        ? 2
                        : constraints.maxWidth < 700
                        ? 3
                        : 4;
                    final aspectRatio = constraints.maxWidth < 500 ? 0.82 : 1.0;
                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: _brands.length,
                      itemBuilder: (context, index) {
                        final brand = _brands[index];
                        return _BrandCard(
                          brand: brand,
                          onEdit: () => _showBrandDialog(brand: brand),
                          onDelete: () => _deleteBrand(brand),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: content),
      );
    }

    return AdminScaffold(
      selected: AdminSidebarItem.brands,
      onItemSelected: (item) => _navigateFromSidebar(context, item),
      body: content,
    );
  }

  Widget _mobileBrandToolbar(Color brandOrange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration:  BoxDecoration(
        color: AdminTheme.surfaceAlt,
        border: Border(bottom: BorderSide(color: Color(0x0D000000))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final title = const Text(
            'Brand Management',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showBrandDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Brand'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: brandOrange),
                onPressed: _loadBrands,
                tooltip: 'Refresh',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 10), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  final Map<String, dynamic> brand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BrandCard({
    required this.brand,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color cardBg = AdminTheme.surfaceAlt;
    final logo = brand['brand_logo']?.toString() ?? '';
    final name = brand['brand_name']?.toString() ?? 'Unknown';
    final productCount = brand['product_count'] ?? 0;

    return Card(
      color: cardBg,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: logo.isNotEmpty
                  ? ImageResolver.image(
                      imageUrl: logo,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: const Icon(
                        Icons.business,
                        color: AdminTheme.textMuted,
                        size: 32,
                      ),
                    )
                  : const Icon(
                      Icons.business,
                      color: AdminTheme.textMuted,
                      size: 32,
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0x42000000),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$productCount products',
                  style: const TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      color: AdminTheme.info,
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      color: AdminTheme.error,
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}









