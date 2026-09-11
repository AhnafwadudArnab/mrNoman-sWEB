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
            if (stock <= 0 || stock >= 5) return false;
            break;
          case 'IN_STOCK':
            if (stock < 1) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  void _showStockUpdateDialog(Map<String, dynamic> product) {
    final int productId = int.tryParse(
      product['product_id']?.toString() ?? product['id']?.toString() ?? '',
    ) ?? 0;
    if (productId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid product ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Stock:',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '$currentStock units',
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
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
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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

      // Optimistic local state update
      setState(() {
        for (final p in _products) {
          final pid = int.tryParse(
            p['product_id']?.toString() ?? p['id']?.toString() ?? '',
          ) ?? 0;
          if (pid == productId) {
            p['stock_quantity'] = newStock;
            break;
          }
        }
        _applyFilters();
      });

      // Update product stock via API
      await ApiService.updateProduct(productId, {'stock_quantity': newStock});

      // Reload products with fresh data
      final response = await ApiService.getProducts(
        limit: 200,
        fresh: true,
        useCache: false,
      );
      final List<dynamic> productList = response is List
          ? response
          : (response is Map ? (response['products'] as List? ?? []) : []);

      if (mounted) {
        setState(() {
          _products = productList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _applyFilters();
        });
        context.read<ProductRefreshNotifier>().refresh();
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
    if (stock < 5) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(int stock) {
    if (stock <= 0) return 'OUT OF STOCK';
    if (stock < 5) return 'LOW STOCK';
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
                  icon: const Icon(Icons.refresh, color: AdminTheme.brand),
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
                    color: AdminTheme.brand,
                    size: 20,
                  ),
                  label: const Text(
                    "Back to Store",
                    style: TextStyle(
                      color: AdminTheme.brand,
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
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AdminTheme.textSecondary,
                  ),
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
                  child: CircularProgressIndicator(color: AdminTheme.brand),
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
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () => _showStockUpdateDialog(product),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 580;
                              final imageWidget = Container(
                                width: 64,
                                height: 64,
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
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image,
                                                color: Color(0x1F000000),
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        color: Color(0x1F000000),
                                      ),
                              );

                              final detailsWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['product_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Price: \u09F3${product['price'] ?? '0'}',
                                    style: const TextStyle(
                                      color: AdminTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$stock units',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );

                              final buttonWidget = ElevatedButton.icon(
                                onPressed: () =>
                                    _showStockUpdateDialog(product),
                                icon: const Icon(Icons.inventory, size: 18),
                                label: const Text('Update Stock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminTheme.brand,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        imageWidget,
                                        const SizedBox(width: 14),
                                        Expanded(child: detailsWidget),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: buttonWidget,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  imageWidget,
                                  const SizedBox(width: 14),
                                  Expanded(child: detailsWidget),
                                  const SizedBox(width: 12),
                                  buttonWidget,
                                ],
                              );
                            },
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
