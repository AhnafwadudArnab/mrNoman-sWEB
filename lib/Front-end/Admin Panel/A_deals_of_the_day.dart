import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../All Pages/Registrations/login.dart';
import '../Provider/Admin_product_provider.dart';
import '../Provider/product_refresh_notifier.dart';
import '../pages/home_page.dart';
import '../utils/api_service.dart';
import '../utils/image_resolver.dart';
import 'Admin_sidebar.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminDealsOfTheDayPage extends StatelessWidget {
  final bool embedded;

  const AdminDealsOfTheDayPage({super.key, this.embedded = false});

  static void _navigateFromSidebar(
    BuildContext context,
    AdminSidebarItem item,
  ) {
    if (item == AdminSidebarItem.deals) return;
    if (item == AdminSidebarItem.viewStore) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
      return;
    }
    // Add other navigation cases as needed
  }

  Widget _buildContent(BuildContext context) {
    const Color cardBg = AdminTheme.surfaceAlt;
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              "Deals of the Day Management",
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              ),
              icon: const Icon(Icons.store, color: Color(0xFF7C3AED), size: 20),
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
        const Expanded(child: _DealsManagementView()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = AdminTheme.bg;
    if (embedded) {
      return Container(color: darkBg, child: _buildContent(context));
    }
    return AdminScaffold(
      selected: AdminSidebarItem.deals,
      onItemSelected: (item) => _navigateFromSidebar(context, item),
      body: _buildContent(context),
    );
  }
}

class _DealsManagementView extends StatefulWidget {
  const _DealsManagementView();

  @override
  State<_DealsManagementView> createState() => _DealsManagementViewState();
}

class _DealsManagementViewState extends State<_DealsManagementView> {
  int _selectedTab = 0; // 0 = Timer, 1 = Products

  @override
  Widget build(BuildContext context) {
    const Color fieldBg = AdminTheme.surface;
    const Color brandOrange = Color(0xFF7C3AED);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Selector
          Container(
            decoration: BoxDecoration(
              color: AdminTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0x0D000000)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Timer Settings',
                    Icons.timer,
                    0,
                    brandOrange,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Upload Products',
                    Icons.add_shopping_cart,
                    1,
                    brandOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content based on selected tab
          if (_selectedTab == 0)
            const _TimerSettingsCard()
          else
            const _ProductUploadCard(),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    IconData icon,
    int index,
    Color activeColor,
  ) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: activeColor, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Color(0x73000000),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Color(0x73000000),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Timer Settings Card
class _TimerSettingsCard extends StatefulWidget {
  const _TimerSettingsCard();

  @override
  State<_TimerSettingsCard> createState() => _TimerSettingsCardState();
}

class _TimerSettingsCardState extends State<_TimerSettingsCard> {
  final TextEditingController _daysController = TextEditingController(
    text: '3',
  );
  final TextEditingController _hoursController = TextEditingController(
    text: '11',
  );
  final TextEditingController _minutesController = TextEditingController(
    text: '15',
  );
  final TextEditingController _secondsController = TextEditingController(
    text: '0',
  );
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTimer();
  }

  Future<void> _loadCurrentTimer() async {
    try {
      final data = await ApiService.get('/deals_timer', withAuth: false);
      if (mounted) {
        final timer = data is Map
            ? (data['timer'] ?? data['data'] ?? data)
            : null;
        if (timer is Map) {
          setState(() {
            _daysController.text = '${timer['days'] ?? 3}';
            _hoursController.text = '${timer['hours'] ?? 11}';
            _minutesController.text = '${timer['minutes'] ?? 15}';
            _secondsController.text = '${timer['seconds'] ?? 0}';
            _isActive = timer['is_active'] == true || timer['is_active'] == 1;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTimer() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin login required')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.post('/deals_timer', {
        'days': int.tryParse(_daysController.text) ?? 3,
        'hours': int.tryParse(_hoursController.text) ?? 11,
        'minutes': int.tryParse(_minutesController.text) ?? 15,
        'seconds': int.tryParse(_secondsController.text) ?? 0,
        'is_active': _isActive,
      }, withAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Timer updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color fieldBg = AdminTheme.surface;
    const Color brandOrange = Color(0xFF7C3AED);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          Row(
            children: [
              const Icon(Icons.timer, color: brandOrange, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Countdown Timer Settings",
                style: TextStyle(
                  color: brandOrange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Set the countdown timer for Deals of the Day section",
            style: TextStyle(color: Color(0x73000000), fontSize: 14),
          ),
          const SizedBox(height: 24),
          // Timer Input Fields
          Row(
            children: [
              Expanded(
                child: _buildTimerField(_daysController, "Days", fieldBg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimerField(_hoursController, "Hours", fieldBg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimerField(_minutesController, "Minutes", fieldBg),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimerField(_secondsController, "Seconds", fieldBg),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0x0D000000)),
            ),
            child: Row(
              children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: brandOrange,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timer Active',
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Off করলে homepage থেকে Deals section hide হবে',
                        style: TextStyle(color: Color(0x73000000), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Save Button
          ElevatedButton(
            onPressed: _saving ? null : _saveTimer,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _saving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: AdminTheme.textPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Save Timer Settings",
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),

          // Preview
          const SizedBox(height: 24),
          const Divider(color: Color(0x0D000000)),
          const SizedBox(height: 16),
          const Text(
            "Timer Preview:",
            style: TextStyle(color: Color(0x8A000000), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPreviewBox(_daysController.text, 'Days'),
                const SizedBox(width: 12),
                _buildPreviewBox(_hoursController.text, 'Hours'),
                const SizedBox(width: 12),
                _buildPreviewBox(_minutesController.text, 'Min'),
                const SizedBox(width: 12),
                _buildPreviewBox(_secondsController.text, 'Sec'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerField(
    TextEditingController controller,
    String label,
    Color bg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0x8A000000),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: AdminTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              color: AdminTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// Product Upload Card
class _ProductUploadCard extends StatefulWidget {
  const _ProductUploadCard();

  @override
  State<_ProductUploadCard> createState() => _ProductUploadCardState();
}

class _ProductUploadCardState extends State<_ProductUploadCard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(
    text: '0',
  );
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  int? _selectedCategoryId;
  int? _selectedBrandId;
  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  bool _loadingCategories = true;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();
  }

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
      final prod = res['product'];
      if (prod is Map) {
        final nestedId = prod['product_id'] ?? prod['id'] ?? prod['productId'];
        return _toIntStrict(nestedId);
      }
      rethrow;
    }
  }

  Future<void> _loadCategories() async {
    try {
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
          if (_categories.isNotEmpty && _selectedCategoryId == null) {
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
          if (_brands.isNotEmpty && _selectedBrandId == null) {
            _selectedBrandId = _intOrNull(_brands.first['brand_id']);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedFile = file;
        _selectedFileBytes = bytes;
      });
    }
  }

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
        specs: null,
      );

      final productId = _extractProductIdFromResponse(
        Map<String, dynamic>.from(res),
      );

      // Assign to Deals of the Day section
      try {
        await ApiService.updateProductSections(productId, {'deals': true});
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
      String? imageUrl;
      if (serverProduct != null && serverProduct['image_url'] != null) {
        imageUrl = ImageResolver.resolveUrl(
          serverProduct['image_url'].toString(),
        );
      }

      final productData = serverProduct != null
          ? {
              "id": "server_$productId",
              "name": (serverProduct['product_name'] ?? '').toString(),
              "price": (serverProduct['price'] ?? '').toString(),
              "stock": serverProduct['stock_quantity'] ?? 0,
              "desc": (serverProduct['description'] ?? '').toString(),
              "category": (serverProduct['category_name'] ?? '').toString(),
              "imageUrl": imageUrl ?? '',
              "image": _selectedFile,
            }
          : {
              "name": _nameController.text.trim(),
              "price": _priceController.text.trim(),
              "stock": int.tryParse(_stockController.text.trim()) ?? 0,
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

      provider.addProduct('Deals of the Day', productData);

      // Notify all product section widgets to reload fresh data from server
      if (mounted) {
        context.read<ProductRefreshNotifier>().refresh();
      }

      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _descController.clear();
      setState(() {
        _selectedFile = null;
        _selectedFileBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Product uploaded to Deals of the Day successfully!"),
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

  @override
  Widget build(BuildContext context) {
    const Color fieldBg = AdminTheme.surface;
    const Color brandOrange = Color(0xFF7C3AED);

    final productProvider = Provider.of<AdminProductProvider>(context);
    final currentSectionProducts =
        productProvider.sectionProducts['Deals of the Day'] ?? [];

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
          Row(
            children: [
              const Icon(Icons.local_offer, color: brandOrange, size: 28),
              const SizedBox(width: 12),
              const Text(
                "Upload Products to Deals of the Day",
                style: TextStyle(
                  color: brandOrange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Fields
              Expanded(
                flex: 2,
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Image & Category
              Expanded(
                child: Column(
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
                                child: Image.memory(
                                  _selectedFileBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            :  Icon(
                                Icons.add_a_photo,
                                color: Color(0x1F000000),
                                size: 40,
                              ),
                      ),
                    ),
                     SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      dropdownColor: fieldBg,
                      style:  TextStyle(color: AdminTheme.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldBg,
                        border: InputBorder.none,
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: AdminTheme.textSecondary),
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
                        labelStyle: const TextStyle(color: AdminTheme.textSecondary),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _publishing
                ? null
                : () => _handlePublish(productProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
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
                : const Text(
                    "Publish to Deals of the Day",
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          // Recently Published Products
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
                  subtitle: Text(
                    "৳ ${p['price']}",
                    style: const TextStyle(color: Colors.green),
                  ),
                  trailing: TextButton.icon(
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
          'This will remove the product from Deals of the Day section.',
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
        provider.removeProduct('Deals of the Day', index);
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
}











