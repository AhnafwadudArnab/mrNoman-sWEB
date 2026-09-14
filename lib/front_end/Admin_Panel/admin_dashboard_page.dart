import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:electrocitybd1/front_end/All_Pages/Registrations/signup.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/auth_session.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';
import 'package:electrocitybd1/front_end/Provider/Orders_provider.dart';

class AdminDashboardPage extends StatefulWidget {
  /// When true, only the content is shown (no sidebar). Used inside AdminLayoutPage.
  final bool embedded;

  const AdminDashboardPage({super.key, this.embedded = false});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _dashboardStats;
  bool _statsLoading = true;
  String? _adminName;
  String _selectedPeriod = 'Last 7 Days';
  double? _customMonthlyTarget;

  @override
  void initState() {
    super.initState();
    _loadCustomTarget();
    _loadDashboardStats();
    _loadAdminName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrdersProvider>().refreshFromApi(admin: true);
      }
    });
  }

  Future<void> _loadCustomTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble('admin_monthly_target');
      if (val != null && val > 0 && mounted) {
        setState(() {
          _customMonthlyTarget = val;
        });
      }
    } catch (_) {}
  }

  void _showSetTargetDialog(double currentTarget) {
    final controller = TextEditingController(
      text: currentTarget > 0 ? currentTarget.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminTheme.brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.track_changes, color: AdminTheme.brand, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Set Monthly Target',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your monthly revenue target in ৳ (BDT). Progress will be calculated relative to this target.',
              style: TextStyle(fontSize: 13, color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Target Amount (৳)',
                prefixText: '৳ ',
                hintText: 'e.g. 500000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminTheme.brand, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AdminTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              final amount = double.tryParse(text);
              if (amount != null && amount > 0) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('admin_monthly_target', amount);
                if (mounted) {
                  setState(() {
                    _customMonthlyTarget = amount;
                  });
                }
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Target'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_monthly_target');
      if (mounted) {
        setState(() {
          _customMonthlyTarget = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Target reset to automatic calculation.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } catch (_) {}
  }

  String? _statsError;

  final List<String> _timePeriods = [
    'Last 7 Days',
    'Last 14 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  Future<void> _loadAdminName() async {
    try {
      // First try local cached user data
      final local = await AuthSession.getUserData();
      String? name = local?.fullName.trim().isNotEmpty == true
          ? local!.fullName.trim()
          : null;

      // If not found, fetch from profile API and cache
      if (name == null || name.isEmpty) {
        final profile = await ApiService.getProfile();
        final user = UserData.fromApiResponse(profile);
        await AuthSession.saveUserData(user);
        name = user.fullName.trim();
      }

      if (!mounted) return;
      setState(() {
        _adminName = name;
      });
    } catch (_) {
      // Ignore; fall back to generic label
    }
  }

  Future<void> _loadDashboardStats() async {
    if (mounted) {
      setState(() {
        _statsLoading = true;
        _statsError = null;
      });
    } else {
      _statsError = null;
    }

    try {
      // Extract days from selected period
      int days = 7; // default
      if (_selectedPeriod.contains('7')) days = 7;
      if (_selectedPeriod.contains('14')) days = 14;
      if (_selectedPeriod.contains('30')) days = 30;
      if (_selectedPeriod.contains('90')) days = 90;

      final stats = await ApiService.getDashboardStats(days: days, useCache: false);
      if (mounted) {
        setState(() {
          _dashboardStats = stats;
          _statsLoading = false;
          _statsError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _statsError = e is ApiException
              ? e.message
              : 'Failed to load dashboard.';
        });
      }
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        _buildTopBar(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 980;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildRevenueAnalytics(),
                    const SizedBox(height: 24),
                    if (isNarrow) ...[
                      _buildMonthlyTarget(),
                      const SizedBox(height: 16),
                      _buildConversionRate(),
                    ] else
                      Row(
                        children: [
                          Expanded(child: _buildMonthlyTarget()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildConversionRate()),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Material(
        color: AdminTheme.bg,
        child: SizedBox.expand(child: _buildDashboardContent()),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.dashboard,
      onItemSelected: (item) {
        if (item == AdminSidebarItem.dashboard) return;
        AdminNav.go(context, item);
      },
      body: _buildDashboardContent(),
    );
  }

  Widget _buildTopBar() {
    final isMobile = AdminScaffold.isMobileScreen(context);
    // On mobile the AppBar is already shown by AdminScaffold -> skip this bar
    if (isMobile) return const SizedBox.shrink();
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        border: Border(bottom: BorderSide(color: AdminTheme.border, width: 1)),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _adminName == null || _adminName!.isEmpty
                    ? 'Dashboard'
                    : '$_adminName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Consumer<OrdersProvider>(
            builder: (context, ordersProvider, _) {
              final pendingOrders = ordersProvider.orders.where((o) =>
                  o.status.toLowerCase() == 'pending' ||
                  o.status.toLowerCase() == 'new order').toList();
              final notificationCount = pendingOrders.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AdminTheme.textPrimary,
                    ),
                    tooltip: 'Order Notifications',
                    onPressed: () {
                      _showOrderNotifications(context);
                    },
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AdminTheme.error,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AdminTheme.error.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            notificationCount > 9 ? '9+' : '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showOrderNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<OrdersProvider>(
          builder: (context, ordersProvider, _) {
            final orders = ordersProvider.ordersNewestFirst;
            final pendingOrders = orders.where((o) =>
                o.status.toLowerCase() == 'pending' ||
                o.status.toLowerCase() == 'new order').toList();
            final displayOrders = orders.take(15).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                  maxHeight: 650,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AdminTheme.shadowLg,
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AdminTheme.brand.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: AdminTheme.brand,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AdminTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pendingOrders.isNotEmpty
                                        ? '${pendingOrders.length} pending order${pendingOrders.length > 1 ? 's' : ''} require attention'
                                        : 'All orders are up to date',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: pendingOrders.isNotEmpty
                                          ? AdminTheme.warning
                                          : AdminTheme.textSecondary,
                                      fontWeight: pendingOrders.isNotEmpty
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: ordersProvider.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 20),
                              tooltip: 'Refresh orders',
                              color: AdminTheme.textSecondary,
                              onPressed: ordersProvider.isLoading
                                  ? null
                                  : () => ordersProvider.refreshFromApi(admin: true),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              tooltip: 'Close',
                              color: AdminTheme.textSecondary,
                              onPressed: () => Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AdminTheme.divider),

                      // Notification list
                      Expanded(
                        child: ordersProvider.isLoading && orders.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text(
                                      'Loading order notifications...',
                                      style: TextStyle(color: AdminTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              )
                            : displayOrders.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.notifications_off_outlined,
                                            size: 48,
                                            color: AdminTheme.textMuted.withOpacity(0.6),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'No Order Notifications',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AdminTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'There are currently no orders placed.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AdminTheme.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    itemCount: displayOrders.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (ctx, index) {
                                      final order = displayOrders[index];
                                      final isPending = order.status.toLowerCase() == 'pending' ||
                                          order.status.toLowerCase() == 'new order';
                                      final statusColor = AdminTheme.statusColor(order.status);
                                      final customerTitle = (order.customerName != null && order.customerName!.trim().isNotEmpty)
                                          ? order.customerName!.trim()
                                          : 'Customer';

                                      return Material(
                                        color: isPending
                                            ? statusColor.withOpacity(0.06)
                                            : AdminTheme.surfaceAlt.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () {
                                            Navigator.of(dialogContext).pop();
                                            AdminNav.go(context, AdminSidebarItem.orders);
                                          },
                                          hoverColor: AdminTheme.brand.withOpacity(0.08),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isPending
                                                    ? statusColor.withOpacity(0.4)
                                                    : AdminTheme.border.withOpacity(0.6),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: statusColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              'Order #${order.orderId}',
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14,
                                                                color: AdminTheme.textPrimary,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: statusColor.withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Text(
                                                              order.status.toUpperCase(),
                                                              style: TextStyle(
                                                                color: statusColor,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '$customerTitle ${order.customerPhone != null && order.customerPhone!.isNotEmpty ? '• ${order.customerPhone}' : ''}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AdminTheme.textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            '৳${order.total.toStringAsFixed(0)}',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: AdminTheme.brand,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '• ${order.paymentMethod}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AdminTheme.textMuted,
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            order.createdAt,
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              color: AdminTheme.textMuted,
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
                                      );
                                    },
                                  ),
                      ),

                      const Divider(height: 1, color: AdminTheme.divider),

                      // Footer button
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Text(
                              'Total: ${orders.length} order${orders.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdminTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.brand,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text(
                                'View in Order List',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                AdminNav.go(context, AdminSidebarItem.orders);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCards() {
    if (_statsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_statsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _statsError!,
                style: const TextStyle(color: AdminTheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: _loadDashboardStats,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 12),
                  if (_statsError!.toLowerCase().contains(
                    'invalid or expired token',
                  ))
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ApiService.clearToken();
                        await AuthSession.clear();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const Signup()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: AdminTheme.error),
                      label: const Text(
                        'Login Again',
                        style: TextStyle(color: AdminTheme.error),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    final totalRevenue = _toDouble(_dashboardStats?['totalRevenue']);
    final totalOrders = _toInt(_dashboardStats?['totalOrders']);
    final totalCustomers = _toInt(_dashboardStats?['totalCustomers']);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildStatCard(
            'Total Sales',
            '৳${totalRevenue.toStringAsFixed(0)}',
            '',
            'from DB',
            AdminTheme.brand,
            Icons.attach_money,
            true,
          ),
          _buildStatCard(
            'Total Orders',
            '$totalOrders',
            '',
            'from DB',
            AdminTheme.success,
            Icons.shopping_cart,
            true,
          ),
          _buildStatCard(
            'Total Customers',
            '$totalCustomers',
            '',
            'from DB',
            AdminTheme.info,
            Icons.people,
            true,
          ),
        ];

        if (constraints.maxWidth < 980) {
          return Column(
            children: [
              for (int idx = 0; idx < cards.length; idx++) ...[
                cards[idx],
                if (idx != cards.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String percentage,
    String subtitle,
    Color color,
    IconData icon,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                percentage,
                style: TextStyle(
                  color: isPositive ? AdminTheme.success : AdminTheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueAnalytics() {
    // Build chart spots from real daily revenue data if available
    final dailyRevenue =
        (_dashboardStats?['dailyRevenue'] as List<dynamic>?) ?? [];
    final List<FlSpot> spots;
    if (dailyRevenue.isNotEmpty) {
      spots = List.generate(dailyRevenue.length, (i) {
        final v = dailyRevenue[i];
        final rev = _toDouble(v is Map ? v['revenue'] : v);
        return FlSpot(i.toDouble(), rev);
      });
    } else {
      spots = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    }

    double maxVal = 0;
    for (final s in spots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    final double maxY = maxVal > 0 ? (maxVal * 1.35) : 5000;
    final double maxX = spots.length > 1 ? (spots.length - 1).toDouble() : 1.0;

    String formatDayLabel(int index) {
      if (index >= 0 && index < dailyRevenue.length) {
        final item = dailyRevenue[index];
        if (item is Map && item['day'] != null) {
          final str = item['day'].toString();
          final parts = str.split('-');
          if (parts.length == 3) {
            const months = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            final mIdx = int.tryParse(parts[1]);
            final dNum = int.tryParse(parts[2]);
            if (mIdx != null && mIdx >= 1 && mIdx <= 12 && dNum != null) {
              return '${months[mIdx - 1]} $dNum';
            }
          }
        }
      }
      return 'D${index + 1}';
    }

    double bottomInterval = 1.0;
    if (spots.length > 30) {
      bottomInterval = (spots.length / 5).floorToDouble().clamp(1.0, 30.0);
    } else if (spots.length > 14) {
      bottomInterval = 5.0;
    } else if (spots.length > 7) {
      bottomInterval = 2.0;
    } else {
      bottomInterval = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimePeriodSelector(),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: const Color(0xFF2563EB),
                          strokeWidth: 2,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
                    tooltipBorder: const BorderSide(color: Colors.white38, width: 1),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final label = formatDayLabel(spot.x.toInt());
                        return LineTooltipItem(
                          '$label\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: '৳${spot.y.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).clamp(1.0, double.infinity),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AdminTheme.border.withOpacity(0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: (maxY / 4).clamp(1.0, double.infinity),
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        String text;
                        if (value >= 100000) {
                          text = '${(value / 1000).toStringAsFixed(0)}k';
                        } else if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1)}k';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return Text(
                          text,
                          style: TextStyle(
                            fontSize: 10,
                            color: AdminTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= spots.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            formatDayLabel(index),
                            style: TextStyle(
                              fontSize: 10,
                              color: AdminTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: AdminTheme.border,
                      width: 1,
                    ),
                    left: BorderSide.none,
                    right: BorderSide.none,
                    top: BorderSide.none,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    preventCurveOverShooting: true,
                    color: AdminTheme.brand,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 14,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AdminTheme.brand,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AdminTheme.brand.withOpacity(0.28),
                          AdminTheme.brand.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _timePeriods.length; i++) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = _timePeriods[i];
                });
                // Load new data when period changes
                _loadDashboardStats();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _selectedPeriod == _timePeriods[i]
                      ? AdminTheme.brand
                      : AdminTheme.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedPeriod == _timePeriods[i]
                        ? AdminTheme.brand
                        : AdminTheme.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _timePeriods[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedPeriod == _timePeriods[i]
                        ? AdminTheme.surface
                        : AdminTheme.textPrimary,
                  ),
                ),
              ),
            ),
            if (i != _timePeriods.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyTarget() {
    final double revenue = _toDouble(_dashboardStats?['totalRevenue']);
    final double target = _customMonthlyTarget != null && _customMonthlyTarget! > 0
        ? _customMonthlyTarget!
        : (_toDouble(_dashboardStats?['monthlyTarget']) > 0
            ? _toDouble(_dashboardStats?['monthlyTarget'])
            : (revenue > 0 ? revenue * 2 : 100000));
    final double percentage = target > 0
        ? ((revenue / target) * 100).clamp(0, 100).toDouble()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Monthly Target',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: AdminTheme.textSecondary),
                tooltip: 'Target Options',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (value) {
                  if (value == 'set') {
                    _showSetTargetDialog(target);
                  } else if (value == 'reset') {
                    _resetTarget();
                  } else if (value == 'refresh') {
                    _loadDashboardStats();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'set',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AdminTheme.brand),
                        SizedBox(width: 8),
                        Text('Set Target Amount'),
                      ],
                    ),
                  ),
                  if (_customMonthlyTarget != null)
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt, size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Reset Target'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: AdminTheme.textSecondary),
                        SizedBox(width: 8),
                        Text('Refresh Data'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 15,
                  backgroundColor: AdminTheme.brandDim,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AdminTheme.brand,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}% of monthly target',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTheme.brandDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Keep it up! 🎯',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  revenue > 0
                      ? 'Revenue: ৳${revenue.toStringAsFixed(0)} / Target: ৳${target.toStringAsFixed(0)}'
                      : 'No revenue data yet.',
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳${target.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '৳${revenue.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionRate() {
    final totalOrders = _toInt(_dashboardStats?['totalOrders']);
    final totalCustomers = _toInt(_dashboardStats?['totalCustomers']);
    final totalRevenue = _toDouble(_dashboardStats?['totalRevenue']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Store Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.brand,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'All Time',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final cards = [
                _buildConversionCard('Total Orders', '$totalOrders', '', true),
                _buildConversionCard(
                  'Total Customers',
                  '$totalCustomers',
                  '',
                  true,
                ),
                _buildConversionCard(
                  'Avg Order Value',
                  totalOrders > 0
                      ? '৳${(totalRevenue / totalOrders).toStringAsFixed(0)}'
                      : '৳0',
                  '',
                  true,
                ),
                _buildConversionCard(
                  'Total Revenue',
                  '৳${totalRevenue.toStringAsFixed(0)}',
                  '',
                  true,
                ),
              ];
              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: cards[2]),
                        const SizedBox(width: 12),
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConversionCard(
    String title,
    String value,
    String percentage,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percentage,
            style: TextStyle(
              color: isPositive ? AdminTheme.success : AdminTheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}



