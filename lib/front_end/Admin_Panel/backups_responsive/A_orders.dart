import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:electrocitybd1/front_end/utils/web_download.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:electrocitybd1/front_end/Provider/Orders_provider.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//  DESIGN TOKENS  (match reference screenshot)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _C {
  static const bg = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF1A1D23);
  static const textSub = Color(0xFF374151);
  static const textMuted = Color(0xFF6B7280);
  static const brand = Colors.black; // purple
  static const brandLight = Color(0xFFE9EEF3);

  // Stat card colours (order: new, awaiting, on-way, delivered)
  static const statNew = Color(0xFFE7EDF4); // indigo tint
  static const statNewAccent = Colors.black;
  static const statAwait = Color(0xFFFFF7ED); // orange tint
  static const statAwaitAccent = Color(0xFFF97316);
  static const statOnWay = Color(0xFFEFF6FF); // blue tint
  static const statOnWayAccent = Color(0xFF3B82F6);
  static const statDone = Color(0xFFF0FDF4); // green tint
  static const statDoneAccent = Color(0xFF22C55E);

  // Status chip colours
  static Color chipBg(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFF7ED);
      case 'processing':
        return const Color(0xFFEFF6FF);
      case 'shipped':
        return const Color(0xFFE9EEF3);
      case 'delivered':
        return const Color(0xFFF0FDF4);
      case 'cancelled':
        return const Color(0xFFFFF1F2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color chipFg(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return const Color(0xFFEA580C);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'shipped':
        return AdminTheme.brand;
      case 'delivered':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFE11D48);
      default:
        return Colors.black;
    }
  }
}

class AdminOrdersPage extends StatefulWidget {
  final bool embedded;
  const AdminOrdersPage({super.key, this.embedded = false});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String? _filterStatus;
  String _searchQuery = '';
  bool _autoRefresh = false;
  Timer? _autoTimer;
  DateTime? _lastUpdated;
  static const int _refreshIntervalSeconds = 8;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<OrdersProvider>();
      provider.clearForLogout();
      await provider.refreshFromApi(admin: true);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ auto-refresh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _startAutoRefresh(OrdersProvider p) {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) async {
        await p.refreshFromApi(admin: true);
        if (!mounted) return;
        setState(() => _lastUpdated = DateTime.now());
      },
    );
    setState(() {
      _autoRefresh = true;
      _lastUpdated = DateTime.now();
    });
  }

  void _stopAutoRefresh() {
    _autoTimer?.cancel();
    setState(() => _autoRefresh = false);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  // â”€â”€ stat helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int _count(List<Map<String, String>> all, String status) =>
      all.where((o) => (o['status'] ?? '').toLowerCase() == status).length;

  // â”€â”€ filtered list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<Map<String, String>> _filtered(List<Map<String, String>> all) {
    var list = List<Map<String, String>>.from(all);
    if (_filterStatus != null) {
      list = list.where((o) => o['status'] == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) {
        return (o['orderCode'] ?? o['id'] ?? '').toLowerCase().contains(q) ||
            (o['method'] ?? '').toLowerCase().contains(q) ||
            (o['status'] ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Container(color: _C.bg, child: _buildContent());
    }
    return AdminScaffold(
      selected: AdminSidebarItem.orders,
      onItemSelected: (item) {
        if (item == AdminSidebarItem.orders) return;
        AdminNav.go(context, item);
      },
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<OrdersProvider>(
      builder: (context, p, _) {
        final allRows = p.ordersNewestFirst.map((o) => o.toAdminRow()).toList();
        final filtered = _filtered(allRows);

        return Container(
          color: _C.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(allRows, p),
              Expanded(child: _buildBody(allRows, filtered, p)),
            ],
          ),
        );
      },
    );
  }

  // â”€â”€â”€ Page header (title + refresh controls) â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPageHeader(List<Map<String, String>> allRows, OrdersProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          // Title
          const Text(
            'Order list',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const Spacer(),
          // Auto-refresh toggle
          _iconBtn(
            icon: _autoRefresh ? Icons.pause_circle_outline : Icons.refresh,
            tooltip: _autoRefresh
                ? 'Stop auto-refresh'
                : 'Auto-refresh (${_refreshIntervalSeconds}s)',
            color: _autoRefresh ? _C.statDoneAccent : _C.textSub,
            onTap: () =>
                _autoRefresh ? _stopAutoRefresh() : _startAutoRefresh(p),
          ),
          if (_lastUpdated != null) ...[
            const SizedBox(width: 6),
            Text(
              _fmt(_lastUpdated!),
              style: const TextStyle(fontSize: 11, color: _C.textMuted),
            ),
          ],
          const SizedBox(width: 8),
          // Manual refresh
          _iconBtn(
            icon: Icons.sync,
            tooltip: 'Refresh now',
            color: _C.textSub,
            onTap: () => p.refreshFromApi(admin: true),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Main scrollable body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildBody(
    List<Map<String, String>> allRows,
    List<Map<String, String>> filtered,
    OrdersProvider p,
  ) {
    if (p.isLoading && p.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _C.brand));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Stat cards
          _buildStatCards(allRows),
          const SizedBox(height: 20),

          // â”€â”€ Error banner
          if (p.error != null) _buildErrorBanner(p),

          // â”€â”€ Toolbar (search + filters + export + add)
          _buildToolbar(allRows, filtered, p),
          const SizedBox(height: 16),

          // â”€â”€ Table
          _buildTable(filtered, allRows, p),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  STAT CARDS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildStatCards(List<Map<String, String>> all) {
    final newCount = _count(all, 'pending');
    final processingCount = _count(all, 'processing');
    final shippedCount = _count(all, 'shipped');
    final deliveredCount = _count(all, 'delivered');

    // weekly delta helpers (approximate â€” based on createdAtMillis)
    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    int weeklyNew = 0,
        weeklyProcessing = 0,
        weeklyShipped = 0,
        weeklyDelivered = 0;
    for (final o in all) {
      final ms = int.tryParse(o['createdAtMillis'] ?? '') ?? 0;
      if (ms < weekAgo) continue;
      final s = (o['status'] ?? '').toLowerCase();
      if (s == 'pending') weeklyNew++;
      if (s == 'processing') weeklyProcessing++;
      if (s == 'shipped') weeklyShipped++;
      if (s == 'delivered') weeklyDelivered++;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth < 520 ? 2 : 4;
        final isNarrow = constraints.maxWidth < 520;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard(
              label: 'New orders (Pending)  ',
              count: newCount,
              weeklyCount: weeklyNew,
              bg: _C.statNew,
              accent: _C.statNewAccent,
              icon: Icons.fiber_new_rounded,
              onTap: () => setState(
                () => _filterStatus = _filterStatus == 'pending'
                    ? null
                    : 'pending',
              ),
              active: _filterStatus == 'pending',
              width: isNarrow
                  ? (constraints.maxWidth / 2 - 8).clamp(0.0, double.infinity)
                  : (constraints.maxWidth / 4 - 12).clamp(0.0, double.infinity),
            ),
            _statCard(
              label: 'Await accepting (Processing)',
              count: processingCount,
              weeklyCount: weeklyProcessing,
              bg: _C.statAwait,
              accent: _C.statAwaitAccent,
              icon: Icons.hourglass_top_rounded,
              onTap: () => setState(
                () => _filterStatus = _filterStatus == 'processing'
                    ? null
                    : 'processing',
              ),
              active: _filterStatus == 'processing',
              width: isNarrow
                  ? (constraints.maxWidth / 2 - 8).clamp(0.0, double.infinity)
                  : (constraints.maxWidth / 4 - 12).clamp(0.0, double.infinity),
            ),
            _statCard(
              label: 'On way orders (Shipped)',
              count: shippedCount,
              weeklyCount: weeklyShipped,
              bg: _C.statOnWay,
              accent: _C.statOnWayAccent,
              icon: Icons.local_shipping_outlined,
              onTap: () => setState(
                () => _filterStatus = _filterStatus == 'shipped'
                    ? null
                    : 'shipped',
              ),
              active: _filterStatus == 'shipped',
              width: isNarrow
                  ? (constraints.maxWidth / 2 - 8).clamp(0.0, double.infinity)
                  : (constraints.maxWidth / 4 - 12).clamp(0.0, double.infinity),
            ),
            _statCard(
              label: 'Delivered orders',
              count: deliveredCount,
              weeklyCount: weeklyDelivered,
              bg: _C.statDone,
              accent: _C.statDoneAccent,
              icon: Icons.check_circle_outline_rounded,
              onTap: () => setState(
                () => _filterStatus = _filterStatus == 'delivered'
                    ? null
                    : 'delivered',
              ),
              active: _filterStatus == 'delivered',
              width: isNarrow
                  ? (constraints.maxWidth / 2 - 8).clamp(0.0, double.infinity)
                  : (constraints.maxWidth / 4 - 12).clamp(0.0, double.infinity),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required int weeklyCount,
    required Color bg,
    required Color accent,
    required IconData icon,
    required VoidCallback onTap,
    required bool active,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? accent : bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent : bg,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: active ? Colors.white : accent, size: 20),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.2)
                        : accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$weeklyCount this week',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : _C.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white.withOpacity(0.85) : _C.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  TOOLBAR
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildToolbar(
    List<Map<String, String>> allRows,
    List<Map<String, String>> filtered,
    OrdersProvider p,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: search + right-side actions
            Row(
              children: [
                // Search
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      border: Border.all(color: _C.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _C.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search ordersâ€¦',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _C.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: _C.textMuted,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _C.textMuted,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Total count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    border: Border.all(color: _C.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filtered.length} orders',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _C.textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Export CSV
                _outlineBtn(
                  icon: Icons.download_outlined,
                  label: 'Export',
                  onTap: () => _exportCsv(filtered, context),
                ),
                const SizedBox(width: 10),
                // Sort / Add order (decorative for now)
                _outlineBtn(icon: Icons.sort, label: 'Sort', onTap: () {}),
                const SizedBox(width: 10),
                // Add order button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: active filter chips
            if (_filterStatus != null || _searchQuery.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_filterStatus != null)
                    _filterChip(
                      label: _filterStatus!,
                      color: _C.chipFg(_filterStatus!),
                      bg: _C.chipBg(_filterStatus!),
                      onRemove: () => setState(() => _filterStatus = null),
                    ),
                  if (_searchQuery.isNotEmpty)
                    _filterChip(
                      label: '"$_searchQuery"',
                      color: _C.brand,
                      bg: _C.brandLight,
                      onRemove: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _filterStatus = null;
                        _searchQuery = '';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _C.textSub,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _filterChip({
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  TABLE
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildTable(
    List<Map<String, String>> filtered,
    List<Map<String, String>> allRows,
    OrdersProvider p,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 36), // checkbox placeholder
                _TH('ORDER NUMBER', flex: 3),
                _TH('CUSTOMER', flex: 3),
                _TH('CATEGORY', flex: 2),
                _TH('PRICE', flex: 2),
                _TH('DATE', flex: 2),
                _TH('PAYMENT', flex: 2),
                _TH('STATUS', flex: 2),
                SizedBox(width: 40), // actions column
              ],
            ),
          ),

          // â”€â”€ Empty state
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 52,
                    color: _C.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    allRows.isEmpty
                        ? 'No orders yet.'
                        : 'No orders match your filters.',
                    style: const TextStyle(fontSize: 14, color: _C.textSub),
                  ),
                ],
              ),
            )
          else
            // â”€â”€ Rows
            ...filtered.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              final all = p.ordersNewestFirst;
              final full = all.firstWhere(
                (o) => o.orderId == row['id'],
                orElse: () => all.isNotEmpty
                    ? all.first
                    : PlacedOrder(
                        orderId: row['id'] ?? '',
                        transactionId: row['transactionId'] ?? '',
                        paymentMethod: row['method'] ?? '',
                        total: double.tryParse(row['total'] ?? '0') ?? 0,
                        createdAt: row['created'] ?? '',
                        status: row['status'] ?? '',
                      ),
              );
              return _buildRow(context, row, full, p, isAlt: idx.isOdd);
            }),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Map<String, String> row,
    PlacedOrder full,
    OrdersProvider p, {
    required bool isAlt,
  }) {
    final customerName =
        '${full.customerName ?? ''} ${full.customerLastName ?? ''}'.trim();

    return InkWell(
      onTap: () => _showOrderDetailsDialog(context, full, p),
      hoverColor: _C.brandLight.withOpacity(0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isAlt ? const Color(0xFFFAFBFC) : _C.surface,
          border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6))),
        ),
        child: Row(
          children: [
            // Checkbox placeholder
            SizedBox(
              width: 36,
              child: Checkbox(
                value: false,
                onChanged: (_) {},
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: _C.border),
              ),
            ),
            // Order number + sub-id
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['orderCode'] ?? row['id'] ?? 'â€”',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#${row['id'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: _C.textMuted),
                  ),
                ],
              ),
            ),
            // Customer
            Expanded(
              flex: 3,
              child: Text(
                customerName.isEmpty ? 'N/A' : customerName,
                style: const TextStyle(fontSize: 13, color: _C.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Category (store / type)
            Expanded(
              flex: 2,
              child: Text(
                row['store'] ?? row['category'] ?? 'â€”',
                style: const TextStyle(fontSize: 13, color: _C.textSub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Price
            Expanded(
              flex: 2,
              child: Text(
                'à§³${row['total'] ?? '0'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.textPrimary,
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Text(
                row['created'] ?? 'â€”',
                style: const TextStyle(fontSize: 12, color: _C.textSub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Payment method
            Expanded(
              flex: 2,
              child: Text(
                row['method'] ?? 'â€”',
                style: const TextStyle(fontSize: 13, color: _C.textSub),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status chip
            Expanded(flex: 2, child: _statusChip(row['status'] ?? 'pending')),
            // More actions
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: Icon(Icons.more_vert, size: 18, color: _C.textSub),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onSelected: (value) async {
                  if (value == '__view__') {
                    _showOrderDetailsDialog(context, full, p);
                    return;
                  }
                  try {
                    await p.updateOrderStatus(row['id']!, value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order updated to $value'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: '__view__', child: Text('View details')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'pending', child: Text('Mark Pending')),
                  PopupMenuItem(
                    value: 'processing',
                    child: Text('Mark Processing'),
                  ),
                  PopupMenuItem(value: 'shipped', child: Text('Mark Shipped')),
                  PopupMenuItem(
                    value: 'delivered',
                    child: Text('Mark Delivered'),
                  ),
                  PopupMenuItem(
                    value: 'cancelled',
                    child: Text('Mark Cancelled'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  STATUS CHIP
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _statusChip(String status) {
    final bg = _C.chipBg(status);
    final fg = _C.chipFg(status);
    final label = status.isEmpty ? 'unknown' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  ERROR BANNER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _buildErrorBanner(OrdersProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFBD38D)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB45309),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.error!,
              style: const TextStyle(color: Color(0xFFB45309), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => p.refreshFromApi(admin: true),
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  SMALL HELPERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _C.textSub),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _C.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv(List<Map<String, String>> rows, BuildContext context) {
    String csv = 'Order ID,Customer,Category,Price,Date,Payment,Status\n';
    for (final o in rows) {
      csv +=
          '${o['orderCode'] ?? o['id'] ?? ''},${o['store'] ?? ''},${o['method'] ?? ''},${o['total'] ?? ''},${o['created'] ?? ''},${o['method'] ?? ''},${o['status'] ?? ''}\n';
    }
    if (kIsWeb) downloadCsvOnWeb(csv, 'orders.csv');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kIsWeb ? 'CSV downloaded!' : 'Export available on web only.',
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  ORDER DETAIL DIALOG  (unchanged logic, fixed colours)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _showOrderDetailsDialog(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider p,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width > 640
              ? 600
              : MediaQuery.of(context).size.width * 0.95,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _C.surface,
                  border: Border(bottom: BorderSide(color: _C.border)),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _C.brandLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: _C.brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _C.textPrimary,
                            ),
                          ),
                          Text(
                            'Order #${order.orderId}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _C.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _C.textSub),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: Container(
                  color: _C.bg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dlCard(
                          icon: Icons.qr_code,
                          title: 'Order Code',
                          content:
                              order.toAdminRow()['orderCode'] ?? order.orderId,
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Customer Information'),
                        _dlCard(
                          icon: Icons.person_outline,
                          title: 'Name',
                          content:
                              '${order.customerName ?? ''}${order.customerLastName != null && order.customerLastName!.isNotEmpty ? ' ${order.customerLastName}' : ''}'
                                  .trim()
                                  .isEmpty
                              ? 'Not provided'
                              : '${order.customerName ?? ''} ${order.customerLastName ?? ''}'
                                    .trim(),
                        ),
                        _dlCard(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          content: order.customerEmail ?? 'Not provided',
                        ),
                        _dlCard(
                          icon: Icons.phone_outlined,
                          title: 'Phone',
                          content: order.customerPhone ?? 'Not provided',
                        ),
                        _dlCard(
                          icon: Icons.home_outlined,
                          title: 'Address',
                          content: order.customerAddress ?? 'Not provided',
                        ),
                        if (order.shippingAddress != null) ...[
                          const SizedBox(height: 14),
                          _sectionLabel('Delivery Address'),
                          _dlCard(
                            icon: Icons.local_shipping_outlined,
                            title: 'Shipping Address',
                            content: _formatAddress(order.shippingAddress!),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _sectionLabel('Payment Information'),
                        _dlCard(
                          icon: Icons.payment_outlined,
                          title: 'Method',
                          content: order.paymentMethod,
                        ),
                        _dlCard(
                          icon: Icons.receipt_outlined,
                          title: 'Transaction ID',
                          content: order.transactionId.isNotEmpty
                              ? order.transactionId
                              : 'Not available',
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Order Summary'),
                        _dlCard(
                          icon: Icons.access_time_outlined,
                          title: 'Placed',
                          content: order.createdAt,
                        ),
                        _dlCard(
                          icon: Icons.info_outline,
                          title: 'Status',
                          content: order.status.toUpperCase(),
                        ),
                        if (order.estimatedDelivery?.isNotEmpty == true)
                          _dlCard(
                            icon: Icons.local_shipping_outlined,
                            title: 'Est. Delivery',
                            content: order.estimatedDelivery!,
                          ),
                        _dlCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Subtotal',
                          content:
                              'à§³${order.effectiveSubtotal.toStringAsFixed(2)}',
                        ),
                        _dlCard(
                          icon: Icons.local_shipping_outlined,
                          title: order.deliveryLabel,
                          content:
                              'à§³${order.effectiveDeliveryCharge.toStringAsFixed(2)}',
                        ),
                        if (order.couponDiscount > 0)
                          _dlCard(
                            icon: Icons.discount_outlined,
                            title: 'Discount',
                            content:
                                '-à§³${order.couponDiscount.toStringAsFixed(2)}',
                          ),
                        _dlCard(
                          icon: Icons.attach_money,
                          title: 'Grand Total',
                          content: 'à§³${order.total.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Order Items'),
                        if (order.items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _C.border),
                            ),
                            child: const Center(
                              child: Text(
                                'No items available',
                                style: TextStyle(color: _C.textSub),
                              ),
                            ),
                          )
                        else
                          ...order.items.map((item) => _buildOrderItem(item)),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _C.surface,
                  border: Border(top: BorderSide(color: _C.border)),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: _buildOrderDialogActions(context, order, p),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _C.textPrimary,
      ),
    ),
  );

  Widget _dlCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface, // white, matching the page cards
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEFF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: _C.brandLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _C.brand, size: 16),
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
                    color: _C.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _C.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDialogActions(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider p,
  ) {
    final actions = [
      _actionBtn(
        label: 'Memo',
        icon: Icons.receipt_long,
        bg: Colors.green[700]!,
        fg: Colors.white,
        onTap: () => _downloadOrderMemo(context, order),
      ),
      _actionBtn(
        label: 'Delivery',
        icon: Icons.local_shipping_outlined,
        bg: _C.brand,
        fg: Colors.white,
        onTap: () => _showDeliveryRequestDialog(context, order, p),
      ),
      _actionBtn(
        label: 'Status',
        icon: Icons.edit_outlined,
        bg: Colors.blue[600]!,
        fg: Colors.white,
        onTap: () => _handleUpdateOrderStatus(context, order, p),
      ),
      _actionBtn(
        label: 'Delete',
        icon: Icons.delete_outline,
        bg: Colors.red[600]!,
        fg: Colors.white,
        onTap: () => _handleDeleteOrder(context, order, p),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final cols = constraints.maxWidth < 480 ? 2 : 4;
        final btnW = ((constraints.maxWidth - spacing * (cols - 1)) / cols)
            .clamp(80.0, 180.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: _C.textSub)),
              ),
            ),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions
                  .map((b) => SizedBox(width: btnW, child: b))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name =
        item['product_name']?.toString() ??
        item['name']?.toString() ??
        'Unknown';
    final qty = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
    final unitPrice =
        double.tryParse(
          (item['price_at_purchase'] ?? item['price'] ?? item['unit_price'])
                  ?.toString() ??
              '0',
        ) ??
        0.0;
    final lineTotal = unitPrice * qty;
    final imageUrl =
        item['image_url']?.toString() ??
        item['product_image']?.toString() ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEFF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl.startsWith('http')
                          ? imageUrl
                          : '${_apiBase()}/$imageUrl'
                                .replaceAll('//', '/')
                                .replaceAll(':/', '://'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _C.border,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: _C.textMuted,
                          size: 22,
                        ),
                      ),
                    )
                  : Container(
                      color: _C.border,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: _C.textMuted,
                        size: 22,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: $qty Ã— à§³${unitPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: _C.textSub),
                ),
              ],
            ),
          ),
          Text(
            'à§³${lineTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  DIALOGS: delete / update status
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _handleDeleteOrder(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Delete order #${order.orderId}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await p.deleteOrder(order.orderId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleUpdateOrderStatus(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider p,
  ) async {
    final s = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Update Status'),
        children: ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
            .map(
              (st) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, st),
                child: Text(st[0].toUpperCase() + st.substring(1)),
              ),
            )
            .toList(),
      ),
    );
    if (s == null) return;
    try {
      await p.updateOrderStatus(order.orderId, s);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status â†’ $s'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  DELIVERY REQUEST DIALOG
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  Future<void> _showDeliveryRequestDialog(
    BuildContext context,
    PlacedOrder order,
    OrdersProvider p,
  ) async {
    final providers = await _loadEnabledDeliveryProviders();
    if (!context.mounted) return;
    if (providers.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delivery setup needed'),
          content: const Text(
            'No enabled delivery provider found. Enable one from admin Delivery settings first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    var selProv = providers.first;
    var selMode = _deliveryModes(selProv).first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, ss) => AlertDialog(
          title: const Text('Request Delivery'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Order: ${_memoOrderCode(order)}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selProv,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: providers
                      .map(
                        (pr) => DropdownMenuItem(
                          value: pr,
                          child: Text(_deliveryProviderName(pr)),
                        ),
                      )
                      .toList(),
                  onChanged: (pr) {
                    if (pr != null)
                      ss(() {
                        selProv = pr;
                        selMode = _deliveryModes(pr).first;
                      });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selMode,
                  decoration: const InputDecoration(labelText: 'Service mode'),
                  items: _deliveryModes(selProv)
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (m) {
                    if (m != null) ss(() => selMode = m);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await p.updateOrderStatus(order.orderId, 'shipped');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery requested via ${_deliveryProviderName(selProv)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadEnabledDeliveryProviders() async {
    try {
      final r = await ApiService.getSiteSetting('delivery_provider_settings');
      final raw =
          r['setting_value'] ??
          r['value'] ??
          (r['data'] is Map
              ? r['data']['setting_value'] ?? r['data']['value']
              : null);
      if (raw == null || raw.toString().trim().isEmpty) return [];
      final decoded = jsonDecode(raw.toString());
      if (decoded is! Map || decoded['providers'] is! List) return [];
      return (decoded['providers'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['enabled'] == true)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _deliveryProviderName(Map<String, dynamic> p) =>
      p['name']?.toString() ?? 'Delivery Provider';
  List<String> _deliveryModes(Map<String, dynamic> p) {
    final m = p['serviceModes'];
    if (m is List && m.isNotEmpty) return m.map((e) => e.toString()).toList();
    return const ['Home delivery'];
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  ORDER MEMO (HTML download)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  void _downloadOrderMemo(BuildContext context, PlacedOrder order) {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memo download is web only.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final code = _memoOrderCode(order);
    downloadTextOnWeb(
      _buildOrderMemoHtml(order),
      'order-memo-$code.html',
      mimeType: 'text/html;charset=utf-8',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memo downloaded for $code'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  String _buildOrderMemoHtml(PlacedOrder order) {
    final escape = const HtmlEscape().convert;
    final code = _memoOrderCode(order);
    final cust = _memoCustomerName(order);
    final addr = order.shippingAddress == null
        ? (order.customerAddress ?? 'Not provided')
        : _formatAddress(order.shippingAddress!);
    final gen = DateTime.now().toIso8601String().split('.').first;
    final sub = order.effectiveSubtotal;
    final del = order.effectiveDeliveryCharge;
    final disc = order.couponDiscount;
    final delLbl = order.deliveryLabel;
    final itemsHtml = order.items.isEmpty
        ? '<tr><td colspan="4" class="empty">No item information</td></tr>'
        : order.items.map((item) {
            final n = _memoItemName(item);
            final sku =
                item['sku']?.toString() ?? item['product_id']?.toString() ?? '';
            final q = _memoItemQuantity(item);
            final up = _memoItemPrice(item);
            return '<tr><td><strong>${escape(n)}</strong>${sku.isEmpty ? '' : '<span>SKU: ${escape(sku)}</span>'}</td><td>$q</td><td>BDT ${up.toStringAsFixed(2)}</td><td>BDT ${(up * q).toStringAsFixed(2)}</td></tr>';
          }).join();

    return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><title>Order Memo $code</title>
<style>
* { box-sizing:border-box; } body { margin:0; background:#f3f5f9; font-family:Inter,Arial,sans-serif; color:#111827; }
.memo { width:min(900px,calc(100% - 32px)); margin:24px auto; background:#fff; border:1px solid #e5e7eb; border-radius:18px; overflow:hidden; box-shadow:0 12px 40px rgba(0,0,0,.10); }
.top { display:flex; justify-content:space-between; gap:20px; padding:28px 32px; background:linear-gradient(135deg,#111827,#1f2937 60%,#7c3aed); color:#fff; }
h1,h2,h3,p{margin:0;} .brand h1{font-size:26px;} .brand p,.meta p{color:rgba(255,255,255,.75);margin-top:5px;}
.badge{display:inline-block;margin-top:12px;padding:5px 12px;border-radius:999px;background:#a78bfa;color:#1e1b4b;font-weight:700;font-size:11px;text-transform:uppercase;}
.meta{text-align:right;} .meta h2{font-size:18px;}
.section{padding:24px 32px;border-bottom:1px solid #eef0f4;}
.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:16px;}
.box{border:1px solid #e5e7eb;border-radius:12px;padding:14px;background:#f9fafb;}
.box h3{font-size:11px;color:#6b7280;text-transform:uppercase;margin-bottom:8px;}
table{width:100%;border-collapse:collapse;} th{text-align:left;padding:10px 8px;color:#6b7280;font-size:11px;text-transform:uppercase;border-bottom:1px solid #e5e7eb;}
td{padding:12px 8px;border-bottom:1px solid #f0f2f5;vertical-align:top;} td span{display:block;color:#6b7280;font-size:11px;margin-top:3px;}
.summary{display:flex;justify-content:flex-end;padding:20px 32px 28px;}
.total{width:min(340px,100%);border:1px solid #e5e7eb;border-radius:12px;padding:16px;background:#111827;color:#fff;}
.row{display:flex;justify-content:space-between;padding:5px 0;} .row strong{font-size:20px;color:#a78bfa;}
.note{padding:14px 32px 24px;color:#6b7280;font-size:11px;}
</style>
</head>
<body>
<main class="memo">
  <section class="top">
    <div class="brand"><h1>ElectroZoneBD</h1><p>Order Receipt / Memo</p><span class="badge">${escape(order.status)}</span></div>
    <div class="meta"><h2>${escape(code)}</h2><p>${escape(order.createdAt)}</p><p>Generated: ${escape(gen)}</p></div>
  </section>
  <section class="section grid">
    <div class="box"><h3>Customer</h3><p><strong>${escape(cust)}</strong></p><p>${escape(order.customerPhone ?? '')}</p><p>${escape(order.customerEmail ?? '')}</p></div>
    <div class="box"><h3>Delivery Address</h3><p>${escape(addr)}</p></div>
    <div class="box"><h3>Payment</h3><p><strong>${escape(order.paymentMethod)}</strong></p><p>Txn: ${escape(order.transactionId.isEmpty ? 'N/A' : order.transactionId)}</p></div>
    <div class="box"><h3>Delivery</h3><p>${escape(order.status.toUpperCase())}</p><p>Est: ${escape(order.estimatedDelivery ?? 'N/A')}</p></div>
  </section>
  <section class="section">
    <table><thead><tr><th>Item</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead><tbody>$itemsHtml</tbody></table>
  </section>
  <div class="summary">
    <div class="total">
      <div class="row"><span>Subtotal</span><span>BDT ${sub.toStringAsFixed(2)}</span></div>
      <div class="row"><span>${escape(delLbl)}</span><span>BDT ${del.toStringAsFixed(2)}</span></div>
      ${disc > 0 ? '<div class="row"><span>Discount</span><span>-BDT ${disc.toStringAsFixed(2)}</span></div>' : ''}
      <div class="row"><span>Grand Total</span><strong>BDT ${order.total.toStringAsFixed(2)}</strong></div>
    </div>
  </div>
  <p class="note">Generated from ElectroZoneBD Admin Panel.</p>
</main>
</body>
</html>''';
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  MEMO HELPERS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  String _memoOrderCode(PlacedOrder order) {
    final id = order.orderId;
    if (id.startsWith('EC-') || int.tryParse(id) == null) return id;
    final d = DateTime.fromMillisecondsSinceEpoch(order.createdAtMillis);
    return 'EC-${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}-$id';
  }

  String _memoCustomerName(PlacedOrder order) {
    final p = [
      order.customerName,
      order.customerLastName,
    ].where((e) => e != null && e.trim().isNotEmpty).join(' ');
    return p.isEmpty ? 'Customer' : p;
  }

  String _memoItemName(Map<String, dynamic> item) =>
      item['product_name']?.toString() ??
      item['name']?.toString() ??
      item['title']?.toString() ??
      'Unknown';
  int _memoItemQuantity(Map<String, dynamic> item) =>
      int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
  double _memoItemPrice(Map<String, dynamic> item) =>
      double.tryParse(
        (item['price_at_purchase'] ?? item['price'] ?? item['unit_price'])
                ?.toString() ??
            '0',
      ) ??
      0;

  String _apiBase() {
    try {
      return ApiService.overrideBaseUrl ?? 'https://electrozonebd.com';
    } catch (_) {
      return 'https://electrozonebd.com';
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    if (address.containsKey('address') && address.length == 1)
      return address['address'].toString();
    final parts = <String>[];
    for (final k in ['street', 'city', 'state', 'zip', 'country']) {
      final v = address[k]?.toString();
      if (v != null && v.isNotEmpty) parts.add(v);
    }
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  TABLE HEADER CELL
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH(this.label, {this.flex = 1, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

