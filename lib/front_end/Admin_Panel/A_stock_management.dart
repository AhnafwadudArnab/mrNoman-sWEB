import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electrocitybd1/front_end/pages/home_page.dart';
import 'package:electrocitybd1/front_end/Provider/product_refresh_notifier.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/image_resolver.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminStockManagementPage extends StatefulWidget {
  final bool embedded;
  const AdminStockManagementPage({super.key, this.embedded = false});

  @override
  State<AdminStockManagementPage> createState() =>
      _AdminStockManagementPageState();
}

class _AdminStockManagementPageState extends State<AdminStockManagementPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'ALL'; // ALL, IN_STOCK, LOW_STOCK, OUT_OF_STOCK

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.getProducts(limit: 200);
      final List<dynamic> productList = response is List
          ? response
          : (response is Map ? (response['products'] as List? ?? []) : []);

      setState(() {
        _products = productList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredProducts = _products.where((p) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = (p['product_name'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      // Status filter
      if (_filterStatus != 'ALL') {
        final stock = int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;
        switch (_filterStatus) {
          case 'OUT_OF_STOCK':
            if (stock > 0) return false;
            break;
          case 'LOW_STOCK':
            if (stock <= 0 || stock > 5) return false;
            break;
          case 'IN_STOCK':
            if (stock <= 5) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  void _showStockUpdateDialog(Map<String, dynamic> product) {
    final productId = product['product_id'];
    final productName = product['product_name'] ?? 'Unknown';
    final currentStock =
        int.tryParse(product['stock_quantity']?.toString() ?? '0') ?? 0;

    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    String operationType = 'IN'; // IN or OUT

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.surfaceAlt,
          title: Text(
            'Update Stock: $productName',
            style: const TextStyle(color: AdminTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade700),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Current Stock:',
                          style: TextStyle(color: AppColors.grey300),
                        ),
                        Text(
                          '$currentStock units',
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Operation Type:',
                    style: TextStyle(color: AppColors.grey300, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Stock IN',
                            style: TextStyle(color: AdminTheme.textPrimary),
                          ),
                          value: 'IN',
                          groupValue: operationType,
                          activeColor: Colors.green,
                          onChanged: (v) =>
                              setDialogState(() => operationType = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Stock OUT',
                            style: TextStyle(color: AdminTheme.textPrimary),
                          ),
                          value: 'OUT',
                          groupValue: operationType,
                          activeColor: Colors.orange,
                          onChanged: (v) =>
                              setDialogState(() => operationType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: AdminTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: const TextStyle(
                        color: AdminTheme.textSecondary,
                      ),
                      hintText: 'Enter quantity',
                      hintStyle: TextStyle(color: AdminTheme.textMuted),
                      filled: true,
                      fillColor: AdminTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      labelStyle: const TextStyle(
                        color: AdminTheme.textSecondary,
                      ),
                      hintText: 'Add notes about this stock movement',
                      hintStyle: const TextStyle(color: AdminTheme.textMuted),
                      filled: true,
                      fillColor: AdminTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
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
                backgroundColor: operationType == 'IN'
                    ? Colors.green
                    : Colors.orange,
              ),
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (operationType == 'OUT' && quantity > currentStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cannot remove $quantity units. Only $currentStock available.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                await _updateStock(
                  productId,
                  operationType,
                  quantity,
                  currentStock,
                  notesController.text.trim(),
                );
              },
              child: Text(
                operationType == 'IN' ? 'Add Stock' : 'Remove Stock',
                style: const TextStyle(color: AdminTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStock(
    int productId,
    String operationType,
    int quantity,
    int currentStock,
    String notes,
  ) async {
    try {
      final newStock = operationType == 'IN'
          ? currentStock + quantity
          : currentStock - quantity;

      // Update product stock via API
      await ApiService.updateProduct(productId, {'stock_quantity': newStock});

      // Reload products
      await _loadProducts();
      if (mounted) context.read<ProductRefreshNotifier>().refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock ${operationType == 'IN' ? 'added' : 'removed'} successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStockStatusColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(int stock) {
    if (stock <= 0) return 'OUT OF STOCK';
    if (stock <= 5) return 'LOW STOCK';
    return 'IN STOCK';
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = AdminTheme.bg;
    const Color cardBg = AdminTheme.surfaceAlt;

    if (widget.embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildContent(cardBg)),
      );
    }
    return Scaffold(
      backgroundColor: darkBg,
      body: Row(
        children: [
          AdminSidebar(
            selected: AdminSidebarItem.products,
            onItemSelected: (item) {},
          ),
          Expanded(child: _buildContent(cardBg)),
        ],
      ),
    );
  }

  Widget _buildContent(Color cardBg) {
    return Column(
      children: [
        // Header
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              "Stock Management",
              style: TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh, color: Color(0xFF7C3AED)),
                  tooltip: 'Refresh',
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  ),
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

        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: cardBg,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              final searchField = TextField(
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: const TextStyle(color: AdminTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary),
                  filled: true,
                  fillColor: AdminTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
              );
              final dropdown = DropdownButtonFormField<String>(
                value: _filterStatus,
                dropdownColor: AdminTheme.surface,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AdminTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Products')),
                  DropdownMenuItem(value: 'IN_STOCK', child: Text('In Stock')),
                  DropdownMenuItem(
                    value: 'LOW_STOCK',
                    child: Text('Low Stock'),
                  ),
                  DropdownMenuItem(
                    value: 'OUT_OF_STOCK',
                    child: Text('Out of Stock'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                    _applyFilters();
                  });
                },
              );
              if (isMobile) {
                return Column(
                  children: [searchField, const SizedBox(height: 10), dropdown],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 180, child: dropdown),
                ],
              );
            },
          ),
        ),

        // Products List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                )
              : _filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(color: AdminTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final stock =
                        int.tryParse(
                          product['stock_quantity']?.toString() ?? '0',
                        ) ??
                        0;
                    final statusColor = _getStockStatusColor(stock);
                    final statusText = _getStockStatusText(stock);

                    return Card(
                      color: cardBg,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AdminTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product['image_url'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    ImageResolver.resolveUrl(
                                      product['image_url'].toString(),
                                    ),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image,
                                      color: Color(0x1F000000),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Color(0x1F000000),
                                ),
                        ),
                        title: Text(
                          product['product_name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Price: ?${product['price'] ?? '0'}',
                              style: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$stock units',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _showStockUpdateDialog(product),
                          icon: const Icon(Icons.inventory, size: 18),
                          label: const Text('Update Stock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: AdminTheme.textPrimary,
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
}
