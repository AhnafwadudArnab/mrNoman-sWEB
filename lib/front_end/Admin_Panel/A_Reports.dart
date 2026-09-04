import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminReportsPage extends StatefulWidget {
  final bool embedded;
  const AdminReportsPage({super.key, this.embedded = false});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  static final _darkBg = AdminTheme.bg;
  static final _cardBg = AdminTheme.surfaceAlt;
  static final _orange = Color(0xFF7C3AED);

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final from = _range.start.toIso8601String().substring(0, 10);
      final to = _range.end.toIso8601String().substring(0, 10);
      final res = await ApiService.getReports(from: from, to: to);
      setState(() {
        _data = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AdminTheme.brand,
            onPrimary: Colors.white,
            surface: AdminTheme.surface,
            onSurface: AdminTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      _load();
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.reports) return;
    AdminNav.go(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded)
      return Material(
        color: _darkBg,
        child: SizedBox.expand(child: content),
      );
    return AdminScaffold(
      selected: AdminSidebarItem.reports,
      onItemSelected: (item) => _navigate(context, item),
      body: content,
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: _orange))
              : _error != null
              ? _buildError()
              : _buildBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() => AdminPageHeader(
    color: _cardBg,
    children: [
      const Text(
        'Management / Reports',
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
      ),
      Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            onPressed: _pickRange,
            icon: Icon(Icons.date_range, color: _orange, size: 18),
            label: Text(
              '${_range.start.toString().substring(0, 10)} - ${_range.end.toString().substring(0, 10)}',
              style: TextStyle(color: _orange, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: AdminTheme.textSecondary),
            tooltip: 'Refresh',
          ),
        ],
      ),
    ],
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0x1F000000)),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: TextStyle(color: AdminTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );

  Widget _buildBody() {
    final summary = _data['summary'] as Map<String, dynamic>? ?? {};
    final byStatus = (_data['by_status'] as List<dynamic>?) ?? [];
    final topProducts = (_data['top_products'] as List<dynamic>?) ?? [];
    final daily = (_data['daily'] as List<dynamic>?) ?? [];
    final newCustomers = _toInt(_data['new_customers']);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final stats = [
          _statCard(
            'Total Revenue',
            '?${_toDouble(summary['total_revenue']).toStringAsFixed(0)}',
            Icons.attach_money,
            Colors.green,
            fullWidth: isMobile,
          ),
          _statCard(
            'Total Orders',
            '${_toInt(summary['total_orders'])}',
            Icons.receipt_long,
            Colors.blue,
            fullWidth: isMobile,
          ),
          _statCard(
            'Avg Order Value',
            '?${_toDouble(summary['avg_order_value']).toStringAsFixed(0)}',
            Icons.trending_up,
            _orange,
            fullWidth: isMobile,
          ),
          _statCard(
            'New Customers',
            '$newCustomers',
            Icons.person_add,
            Colors.purple,
            fullWidth: isMobile,
          ),
        ];

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Summary'),
              const SizedBox(height: 12),
              if (isMobile)
                Column(
                  children: stats
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: card,
                        ),
                      )
                      .toList(),
                )
              else
                Wrap(spacing: 16, runSpacing: 16, children: stats),

              const SizedBox(height: 32),

              isMobile
                  ? Column(
                      children: [
                        _buildStatusBreakdown(byStatus),
                        const SizedBox(height: 16),
                        _buildTopProducts(topProducts),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStatusBreakdown(byStatus)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTopProducts(topProducts)),
                      ],
                    ),

              const SizedBox(height: 32),

              if (daily.isNotEmpty) ...[
                _sectionTitle('Daily Revenue (${daily.length} days)'),
                const SizedBox(height: 12),
                _buildDailyTable(daily),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      color: AdminTheme.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) => SizedBox(
    width: fullWidth ? double.infinity : null,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStatusBreakdown(List<dynamic> byStatus) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Orders by Status'),
        const SizedBox(height: 16),
        if (byStatus.isEmpty)
          const Text(
            'No orders in this period',
            style: TextStyle(color: Color(0x42000000)),
          )
        else
          ...byStatus.map((s) {
            final status = s['order_status']?.toString() ?? '';
            final count = _toInt(s['count']);
            final total = _toDouble(s['total']);
            final color = _statusColor(status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '$count orders',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '?${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Widget _buildTopProducts(List<dynamic> products) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Top Products'),
        const SizedBox(height: 16),
        if (products.isEmpty)
          const Text(
            'No sales in this period',
            style: TextStyle(color: Color(0x42000000)),
          )
        else
          ...products.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: _orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      p['product_name']?.toString() ?? '',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_toInt(p['units_sold'])} sold',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '?${_toDouble(p['revenue']).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Widget _buildDailyTable(List<dynamic> daily) => Container(
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminTheme.border)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Orders',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Revenue',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            ...daily.map(
              (d) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdminTheme.border)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        d['day']?.toString() ?? '',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${_toInt(d['orders'])}',
                        style: const TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        '?${_toDouble(d['revenue']).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: _orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return _orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }
}
