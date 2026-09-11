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
          backgroundColor: Color(0xFF4D6787),
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
          color: AdminTheme.surface,
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
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    const Text(
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
                        color: const Color(0xFF4D6787).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4D6787).withAlpha(80),
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
                                  ? const Color(0xFF4D6787)
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
              final totalCartsCount = allCarts.length;
              final totalItemsCount = allCarts.values.fold<int>(
                0,
                (sum, list) =>
                    sum + list.fold<int>(0, (s, item) => s + item.quantity),
              );
              final totalCartValue = allCarts.values.fold<double>(
                0.0,
                (sum, list) =>
                    sum + list.fold<double>(0.0, (s, item) => s + item.itemTotal),
              );

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Informational banner clarifying Abandoned Carts
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Abandoned & Active Carts Explanation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'In e-commerce, abandoned carts represent products customers added to their cart or started checkout for, but have not yet completed the order. This live view tracks potential lost sales so you can analyze demand or initiate customer recovery.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF1E40AF),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Metrics summary row
                  Row(
                    children: [
                      _buildMetricBox('Active Carts', '$totalCartsCount', Icons.shopping_cart_outlined, Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricBox('Items in Carts', '$totalItemsCount', Icons.inventory_2_outlined, Colors.orange),
                      const SizedBox(width: 12),
                      _buildMetricBox('Potential Revenue', '৳${totalCartValue.toStringAsFixed(0)}', Icons.monetization_on_outlined, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (allCarts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
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
                              'No active customer carts currently.\nWhen visitors add items to cart, they will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...allCarts.entries.map((e) {
                      final userId = e.key;
                      final items = e.value;
                      final isGuest = userId.startsWith('guest_');
                      final label = isGuest ? 'Guest Session ($userId)' : 'User: $userId';
                      final total = items.fold<double>(
                        0.0,
                        (sum, item) => sum + item.itemTotal,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: isGuest
                                ? Colors.blue.shade50
                                : Colors.green.shade50,
                            child: Icon(
                              isGuest ? Icons.person_outline : Icons.person,
                              color: isGuest ? Colors.blue : Colors.green,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Pending Checkout',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${items.length} item(s) • Total Value: ৳${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
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
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.category} • Qty: ${item.quantity} × ৳${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AdminTheme.textSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  '৳${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
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

  Widget _buildMetricBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

