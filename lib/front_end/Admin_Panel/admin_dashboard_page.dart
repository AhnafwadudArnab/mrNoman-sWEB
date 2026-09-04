import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/All_Pages/Registrations/signup.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/auth_session.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

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
  String _selectedPeriod = 'Last 8 Days';

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _loadAdminName();
  }

  String? _statsError;

  final List<String> _timePeriods = [
    'Last 7 Days',
    'Last 8 Days',
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
      int days = 8; // default
      if (_selectedPeriod.contains('7')) days = 7;
      if (_selectedPeriod.contains('8')) days = 8;
      if (_selectedPeriod.contains('14')) days = 14;
      if (_selectedPeriod.contains('30')) days = 30;
      if (_selectedPeriod.contains('90')) days = 90;

      final stats = await ApiService.getDashboardStats(days: days);
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
    // On mobile the AppBar is already shown by AdminScaffold ? skip this bar
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AdminTheme.textPrimary,
                ),
                onPressed: () {
                  AdminNav.go(context, AdminSidebarItem.orders);
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
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
            '?${totalRevenue.toStringAsFixed(0)}',
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
    final spots = dailyRevenue.isNotEmpty
        ? List.generate(dailyRevenue.length, (i) {
            final v = dailyRevenue[i];
            return FlSpot(i.toDouble(), _toDouble(v is Map ? v['revenue'] : v));
          })
        : [
            const FlSpot(0, 0),
            const FlSpot(1, 0),
            const FlSpot(2, 0),
            const FlSpot(3, 0),
            const FlSpot(4, 0),
            const FlSpot(5, 0),
            const FlSpot(6, 0),
            const FlSpot(7, 0),
          ];

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
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt() + 1}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AdminTheme.brand,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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
    final double target = _toDouble(_dashboardStats?['monthlyTarget']) > 0
        ? _toDouble(_dashboardStats?['monthlyTarget'])
        : _toDouble(_dashboardStats?['totalRevenue']) *
              2; // default: 2x current revenue as target
    final double revenue = _toDouble(_dashboardStats?['totalRevenue']);
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
              Icon(Icons.more_horiz, color: AdminTheme.textSecondary),
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
                      'Keep it up! ??',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  revenue > 0
                      ? 'Revenue: ?${revenue.toStringAsFixed(0)} / Target: ?${target.toStringAsFixed(0)}'
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
                    target.toStringAsFixed(0),
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
                    revenue.toStringAsFixed(0),
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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                      ? '?${(totalRevenue / totalOrders).toStringAsFixed(0)}'
                      : '?0',
                  '',
                  true,
                ),
                _buildConversionCard(
                  'Total Revenue',
                  '?${totalRevenue.toStringAsFixed(0)}',
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



