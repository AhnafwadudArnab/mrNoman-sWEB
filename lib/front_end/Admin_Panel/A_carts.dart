import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electrocitybd1/front_end/All_Pages/CART/Cart_provider.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminCartsPage extends StatefulWidget {
  final bool embedded;

  const AdminCartsPage({super.key, this.embedded = false});

  @override
  State<AdminCartsPage> createState() => _AdminCartsPageState();
}

class _AdminCartsPageState extends State<AdminCartsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshController.repeat();

    await context.read<CartProvider>().init();
    await Future.delayed(const Duration(milliseconds: 600));

    _refreshController.stop();
    _refreshController.reset();
    if (mounted) {
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carts refreshed!'),
          backgroundColor: Color(0xFF7C3AED),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _navigateFromSidebar(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.carts) return;
    AdminNav.go(context, item);
  }

  Widget _buildCartsContent(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AdminTheme.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Customer Carts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Live view of what users have in cart',
                      style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Refresh carts',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _handleRefresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotationTransition(
                            turns: _refreshController,
                            child: Icon(
                              Icons.refresh,
                              size: 20,
                              color: _isRefreshing
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isRefreshing ? 'Refreshing...' : 'Refresh',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final allCarts = cartProvider.getAllCartsForAdmin();
              if (allCarts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AdminTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No carts yet. When users add items to cart,\nthey will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: allCarts.entries.map((e) {
                  final userId = e.key;
                  final items = e.value;
                  final isGuest = userId.startsWith('guest_');
                  final label = isGuest ? 'Guest' : userId;
                  final total = items.fold<double>(
                    0.0,
                    (sum, item) => sum + item.itemTotal,
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(
                          isGuest ? Icons.person_outline : Icons.person,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${items.length} item(s) ? ?${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminTheme.textSecondary,
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        ...items.map(
                          (item) => ListTile(
                            leading: _buildThumb(item.imageUrl),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${item.category} ? Qty: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                            trailing: Text(
                              '?${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Material(
        color: const Color(0xFFF7F8FD),
        child: SizedBox.expand(child: _buildCartsContent(context)),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.carts,
      onItemSelected: (item) => _navigateFromSidebar(context, item),
      body: _buildCartsContent(context),
    );
  }

  Widget _buildThumb(String path) {
    if (path.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AdminTheme.textSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image_outlined, color: AdminTheme.textSecondary),
      );
    }
    final lower = path.toLowerCase();
    final isNetwork =
        lower.startsWith('http://') || lower.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: isNetwork
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
      ),
    );
  }
}

