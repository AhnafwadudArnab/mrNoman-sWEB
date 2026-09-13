import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electrocitybd1/front_end/Provider/product_refresh_notifier.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/utils/image_resolver.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminDealsPage extends StatefulWidget {
  final bool embedded;

  const AdminDealsPage({super.key, this.embedded = false});

  @override
  State<AdminDealsPage> createState() => _AdminDealsPageState();
}

class _AdminDealsPageState extends State<AdminDealsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandColor = AdminTheme.brand;

  // ── Deals State ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _deals = [];
  List<Map<String, dynamic>> _products = [];
  bool _loadingDeals = true;
  DateTime? _pickedStart;
  DateTime? _pickedEnd;
  final _productIdController = TextEditingController();
  final _dealPriceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // ── Timer State ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _timers = [];
  bool _loadingTimers = true;
  String? _timerError;

  bool get _isDealsActive {
    return _timers.any((t) => t['is_active'] == 1 || t['is_active'] == true || t['is_active'] == '1');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productIdController.dispose();
    _dealPriceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadDeals();
    _loadTimers();
  }

  // ── Deals API ──────────────────────────────────────────────────────────────
  int _getDealId(Map<String, dynamic> d) =>
      int.tryParse(d['deal_id']?.toString() ?? d['id']?.toString() ?? '') ?? 0;

  String _calculateDiscount(dynamic orig, dynamic deal) {
    final o = double.tryParse(orig?.toString() ?? '') ?? 0.0;
    final d = double.tryParse(deal?.toString() ?? '') ?? 0.0;
    if (o > 0 && d > 0 && o > d) {
      final pct = ((o - d) / o * 100).round();
      return '-$pct%';
    }
    return '';
  }

  bool _isDealActive(Map<String, dynamic> d) {
    final endStr = d['end_date']?.toString();
    if (endStr == null || endStr.isEmpty) return true;
    final end = DateTime.tryParse(endStr);
    if (end == null) return true;
    return end.isAfter(DateTime.now());
  }

  Future<void> _loadDeals() async {
    setState(() => _loadingDeals = true);
    try {
      final deals = await ApiService.getDeals(
        useCache: false,
        includeExpired: true,
        limit: 200,
      );
      final productsRes = await ApiService.getProducts(
        limit: 500,
        category: 'all',
      );
      List<Map<String, dynamic>> products = [];
      if (productsRes is List) {
        products = productsRes
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (productsRes is Map && productsRes['products'] is List) {
        products = (productsRes['products'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (mounted) {
        setState(() {
          _deals = deals
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _products = products;
          _loadingDeals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDeals = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Failed to load deals'),
          ),
        );
      }
    }
  }

  Future<void> _addDeal() async {
    final pid = int.tryParse(_productIdController.text.trim());
    if (pid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid product ID')));
      return;
    }
    try {
      await ApiService.createDeal({
        'product_id': pid,
        'deal_price': double.tryParse(_dealPriceController.text.trim()),
        'start_date': _startDateController.text.trim().isEmpty
            ? null
            : _startDateController.text.trim(),
        'end_date': _endDateController.text.trim().isEmpty
            ? null
            : _endDateController.text.trim(),
      });
      _productIdController.clear();
      _dealPriceController.clear();
      _startDateController.clear();
      _endDateController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Deal added successfully'),
          ),
        );
      }
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _loadDeals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed to add deal')),
        );
      }
    }
  }

  Future<void> _updateDeal(int dealId, Map<String, dynamic> data) async {
    try {
      await ApiService.updateDeal(dealId, data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Deal updated'),
          ),
        );
      }
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _loadDeals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed to update deal')),
        );
      }
    }
  }

  Future<void> _deleteDeal(int dealId) async {
    try {
      await ApiService.deleteDeal(dealId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Deal removed'),
          ),
        );
      }
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _loadDeals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed to remove deal')),
        );
      }
    }
  }

  // ── Timers API ─────────────────────────────────────────────────────────────
  int _getTimerId(Map<String, dynamic> t) {
    final v = t['timer_id'] ?? t['id'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Duration? _remaining(Map<String, dynamic> t) {
    final raw = t['end_time']?.toString() ?? '';
    if (raw.isEmpty) return null;
    final end = DateTime.tryParse(raw);
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _loadTimers() async {
    setState(() {
      _loadingTimers = true;
      _timerError = null;
    });
    try {
      final response = await ApiService.get('/deals_timer', withAuth: true);
      final list = response is List
          ? response
          : (response['timers'] as List? ?? response['data'] as List? ?? []);
      final safeList = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (mounted) {
        setState(() {
          _timers = safeList;
          _loadingTimers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timers = [];
          _loadingTimers = false;
          _timerError = e.toString();
        });
      }
    }
  }

  Future<void> _toggleMasterDeals(bool active) async {
    // Optimistically update all timers in memory
    setState(() {
      for (final t in _timers) {
        t['is_active'] = active ? 1 : 0;
      }
    });

    try {
      await ApiService.put('/deals_timer', {'is_active': active});
      ApiService.invalidateCache('/deals_timer');
      ApiService.invalidateCache('/deals');
      if (mounted) {
        context.read<ProductRefreshNotifier>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: active ? Colors.green : Colors.grey.shade800,
            content: Text(
              active
                  ? 'Deals of the Day enabled on storefront'
                  : 'Deals of the Day disabled on storefront',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        for (final t in _timers) {
          t['is_active'] = !active ? 1 : 0;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update deals status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleTimerActive(Map<String, dynamic> timer, bool active) async {
    final id = _getTimerId(timer);
    // Optimistically update local state immediately
    setState(() {
      timer['is_active'] = active ? 1 : 0;
    });

    try {
      await ApiService.put('/deals_timer/$id', {'is_active': active});
      ApiService.invalidateCache('/deals_timer');
      if (mounted) {
        context.read<ProductRefreshNotifier>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: active ? Colors.green : Colors.grey.shade800,
            content: Text(active ? 'Timer activated' : 'Timer paused'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        timer['is_active'] = !active ? 1 : 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTimer(Map<String, dynamic> timer) async {
    final id = _getTimerId(timer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Delete Timer', style: TextStyle(color: AdminTheme.textPrimary)),
        content: Text(
          'Delete timer "${timer['title'] ?? 'Timer'}"?',
          style: const TextStyle(color: AdminTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService.delete('/deals_timer/$id');
      ApiService.invalidateCache('/deals_timer');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timer deleted'), backgroundColor: Colors.green),
        );
        _loadTimers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Date Pickers ───────────────────────────────────────────────────────────
  Future<void> _pickDateTime(
    TextEditingController controller, {
    bool isStart = true,
  }) async {
    final now = DateTime.now();
    final initial = isStart ? (_pickedStart ?? now) : (_pickedEnd ?? now);
    final first = DateTime(now.year - 2);
    final last = DateTime(now.year + 5);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Select date',
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Select time',
    );
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
    if (isStart) {
      _pickedStart = dt;
    } else {
      _pickedEnd = dt;
    }
    controller.text = _fmtDateTime(dt);
    setState(() {});
  }

  String _fmtDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.length >= 10) return s.substring(0, s.length > 16 ? 16 : s.length);
    return s;
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.deals) return;
    AdminNav.go(context, item);
  }

  // ── Build Main View ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Header
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Deals & Countdown Timers',
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
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh, color: AdminTheme.textPrimary),
                  tooltip: 'Refresh all',
                ),
              ],
            ),
          ],
        ),

        // Master Deals of the Day Visibility Switch
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isDealsActive ? Colors.green.shade50 : AdminTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDealsActive ? Colors.green.shade300 : AdminTheme.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isDealsActive ? Icons.check_circle : Icons.pause_circle_outline,
                color: _isDealsActive ? Colors.green.shade700 : AdminTheme.textMuted,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Deals of the Day Section:',
                          style: TextStyle(
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _isDealsActive ? Colors.green.shade700 : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isDealsActive ? 'ON' : 'OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDealsActive
                          ? 'Section is active and visible on the storefront homepage'
                          : 'Section is hidden from the storefront homepage',
                      style: TextStyle(
                        color: _isDealsActive ? Colors.green.shade800 : AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isDealsActive,
                activeColor: Colors.green,
                onChanged: (v) => _toggleMasterDeals(v),
              ),
            ],
          ),
        ),

        // Tabs Bar
        Container(
          color: AdminTheme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: brandColor,
            indicatorWeight: 3,
            labelColor: brandColor,
            unselectedLabelColor: AdminTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.local_offer_outlined, size: 20),
                text: 'Deals of the Day',
              ),
              Tab(
                icon: Icon(Icons.timer_outlined, size: 20),
                text: 'Deals Countdown Timer',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDealsTabView(),
              _buildTimersTabView(),
            ],
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
      selected: AdminSidebarItem.deals,
      onItemSelected: (item) => _navigate(context, item),
      body: content,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: DEALS OF THE DAY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDealsTabView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 750;
              final listPanel = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Active Deals',
                          style: TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_deals.length} deals',
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loadingDeals)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_deals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No deals added yet. Use the form to add one.',
                            style: TextStyle(color: AdminTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _deals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final d = _deals[index];
                          final dealId = _getDealId(d);
                          final imgUrl = ImageResolver.resolveUrl(
                            (d['image_url'] ?? '').toString(),
                          );
                          final name = (d['product_name'] ?? 'Product #$dealId').toString();
                          final origPrice = d['price'] ?? d['original_price'];
                          final dealPrice = d['deal_price'] ?? origPrice;
                          final discountBadge = _calculateDiscount(origPrice, dealPrice);
                          final isActive = _isDealActive(d);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AdminTheme.border
                                    : Colors.red.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    color: AdminTheme.bg,
                                    child: imgUrl.isNotEmpty
                                        ? Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.image_outlined,
                                              color: AdminTheme.textMuted,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: AdminTheme.textMuted,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                color: AdminTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? 'Active Deal' : 'Expired',
                                              style: TextStyle(
                                                color: isActive ? Colors.green : Colors.red,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            '৳$dealPrice',
                                            style: TextStyle(
                                              color: brandColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (origPrice != null && origPrice != dealPrice) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '৳$origPrice',
                                              style: const TextStyle(
                                                color: AdminTheme.textMuted,
                                                decoration: TextDecoration.lineThrough,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                          if (discountBadge.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                discountBadge,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Valid: ${_formatDate(d['start_date'])} → ${_formatDate(d['end_date'])}',
                                        style: const TextStyle(
                                          color: AdminTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AdminTheme.brand,
                                        size: 20,
                                      ),
                                      onPressed: () => _showEditDealDialog(d),
                                      tooltip: 'Edit Deal',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteDeal(dealId),
                                      tooltip: 'Delete Deal',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );

              final formPanel = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Deal',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_products.isNotEmpty) ...[
                      _label('Select Product'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AdminTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            hint: const Text(
                              'Choose product...',
                              style: TextStyle(color: AdminTheme.textMuted, fontSize: 13),
                            ),
                            value: () {
                              final currentId = int.tryParse(_productIdController.text.trim());
                              if (currentId == null) return null;
                              final exists = _products.any((p) => (int.tryParse(p['product_id']?.toString() ?? p['id']?.toString() ?? '') ?? 0) == currentId);
                              return exists ? currentId : null;
                            }(),
                            items: _products.map((p) {
                              final pid = int.tryParse(p['product_id']?.toString() ?? p['id']?.toString() ?? '') ?? 0;
                              final pname = (p['product_name'] ?? 'Product #$pid').toString();
                              final pprice = p['price']?.toString() ?? '';
                              return DropdownMenuItem<int>(
                                value: pid,
                                child: Text(
                                  '$pname (৳$pprice)',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AdminTheme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _productIdController.text = val.toString();
                                  final match = _products.firstWhere(
                                    (p) => (int.tryParse(p['product_id']?.toString() ?? p['id']?.toString() ?? '') ?? 0) == val,
                                    orElse: () => {},
                                  );
                                  if (match.isNotEmpty) {
                                    final p = double.tryParse(match['price']?.toString() ?? '') ?? 0;
                                    if (p > 0) {
                                      _dealPriceController.text = (p * 0.85).round().toString();
                                    }
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _label('Product ID *'),
                    TextField(
                      controller: _productIdController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: _inputDeco('e.g. 1'),
                      onChanged: (val) {
                        final pid = int.tryParse(val.trim());
                        if (pid != null) {
                          final match = _products.firstWhere(
                            (p) => (int.tryParse(p['product_id']?.toString() ?? p['id']?.toString() ?? '') ?? 0) == pid,
                            orElse: () => {},
                          );
                          if (match.isNotEmpty && _dealPriceController.text.isEmpty) {
                            final p = double.tryParse(match['price']?.toString() ?? '') ?? 0;
                            if (p > 0) {
                              _dealPriceController.text = (p * 0.85).round().toString();
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _label('Deal Price (৳)'),
                    TextField(
                      controller: _dealPriceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: _inputDeco('Discounted price'),
                    ),
                    const SizedBox(height: 12),
                    _label('Start Date & Time'),
                    TextField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _pickDateTime(_startDateController, isStart: true),
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: _inputDeco('Optional').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => _pickDateTime(_startDateController, isStart: true),
                          icon: const Icon(Icons.schedule, color: Colors.black45),
                          tooltip: 'Pick start date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _label('End Date & Time'),
                    TextField(
                      controller: _endDateController,
                      readOnly: true,
                      onTap: () => _pickDateTime(_endDateController, isStart: false),
                      style: const TextStyle(color: AdminTheme.textPrimary),
                      decoration: _inputDeco('Optional').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => _pickDateTime(_endDateController, isStart: false),
                          icon: const Icon(Icons.schedule, color: Colors.black45),
                          tooltip: 'Pick end date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addDeal,
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: const Text('Add Deal'),
                      ),
                    ),
                  ],
                ),
              );

              return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        listPanel,
                        const SizedBox(height: 20),
                        formPanel,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: listPanel),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: formPanel),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  void _showEditDealDialog(Map<String, dynamic> d) {
    final priceC = TextEditingController(
      text: '${d['deal_price'] ?? d['original_price'] ?? ''}',
    );
    final startC = TextEditingController(text: _formatDate(d['start_date']));
    final endC = TextEditingController(text: _formatDate(d['end_date']));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Edit Deal', style: TextStyle(color: AdminTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product: ${d['product_name'] ?? 'ID: ${d['product_id']}'}',
                style: const TextStyle(color: AdminTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceC,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Deal price',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
              TextField(
                controller: startC,
                readOnly: true,
                onTap: () => _pickDateTime(startC, isStart: true),
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  suffixIcon: Icon(Icons.schedule, color: Colors.black45),
                ),
              ),
              TextField(
                controller: endC,
                readOnly: true,
                onTap: () => _pickDateTime(endC, isStart: false),
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  suffixIcon: Icon(Icons.schedule, color: Colors.black45),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _updateDeal(_getDealId(d), {
                'deal_price': priceC.text.trim().isEmpty
                    ? null
                    : double.tryParse(priceC.text),
                'start_date': startC.text.trim().isEmpty ? null : startC.text.trim(),
                'end_date': endC.text.trim().isEmpty ? null : endC.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: DEALS COUNTDOWN TIMER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTimersTabView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final pagePadding = isMobile ? 12.0 : 20.0;
        final isNarrow = constraints.maxWidth < 560;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pagePadding, vertical: isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deals Countdown Timers',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage flash deal countdown clocks shown on the homepage',
                      style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateTimerDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Timer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deals Countdown Timers',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage flash deal countdown clocks shown on the homepage',
                            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showCreateTimerDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Timer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

          if (_loadingTimers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_timerError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Error: $_timerError',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_timers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer_outlined, size: 54, color: AdminTheme.textMuted),
                  const SizedBox(height: 12),
                  const Text(
                    'No countdown timers found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create a new timer to show a deals countdown clock on your store',
                    style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showCreateTimerDialog,
                    style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                    child: const Text('Create First Timer', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final t = _timers[index];
                final isActive = t['is_active'] == 1 || t['is_active'] == true;
                final remaining = _remaining(t);
                final rawEnd = t['end_time']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? brandColor.withOpacity(0.4) : AdminTheme.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: isActive ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'ACTIVE' : 'PAUSED',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: AdminTheme.brand),
                            onPressed: () => _showEditTimerDialog(t),
                            tooltip: 'Edit timer',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            onPressed: () => _deleteTimer(t),
                            tooltip: 'Delete timer',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t['title'] ?? 'Deals Timer',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      if ((t['description'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          t['description'],
                          style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Isolated Countdown clock display
                      _TimerClockDisplay(
                        rawEnd: rawEnd,
                        formattedEnd: _formatDate(rawEnd),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          const Text(
                            'Enable on Storefront',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: isActive,
                            activeColor: brandColor,
                            onChanged: (v) => _toggleTimerActive(t, v),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
      },
    );
  }


  void _showCreateTimerDialog() {
    final titleC = TextEditingController(text: 'Special Deals');
    final descC = TextEditingController();
    DateTime? endDt = DateTime.now().add(const Duration(days: 3));
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: cardBg,
          title: const Text('Create Deals Timer', style: TextStyle(color: AdminTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Timer Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    endDt == null ? 'No end date' : 'End: ${_fmtDateTime(endDt!)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDt ?? now.add(const Duration(days: 3)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endDt ?? now),
                      );
                      setS(() {
                        endDt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? 23,
                          time?.minute ?? 59,
                        );
                      });
                    },
                    child: const Text('Pick End Time', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Active on Store', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: brandColor,
                      onChanged: (v) => setS(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                try {
                  await ApiService.post('/deals_timer', {
                    'title': titleC.text.trim(),
                    'description': descC.text.trim(),
                    'end_time': endDt?.toIso8601String(),
                    'is_active': isActive,
                  }, withAuth: true);
                  ApiService.invalidateCache('/deals_timer');
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadTimers();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTimerDialog(Map<String, dynamic> timer) {
    final id = _getTimerId(timer);
    final titleC = TextEditingController(text: timer['title'] ?? '');
    final descC = TextEditingController(text: timer['description'] ?? '');
    final rawEnd = timer['end_time']?.toString() ?? '';
    DateTime? endDt = rawEnd.isNotEmpty ? DateTime.tryParse(rawEnd) : null;
    bool isActive = timer['is_active'] == 1 || timer['is_active'] == true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: cardBg,
          title: const Text('Edit Deals Timer', style: TextStyle(color: AdminTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Timer Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    endDt == null ? 'No end date' : 'End: ${_fmtDateTime(endDt!)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: brandColor),
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDt ?? now.add(const Duration(days: 3)),
                        firstDate: now.subtract(const Duration(days: 30)),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endDt ?? now),
                      );
                      setS(() {
                        endDt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time?.hour ?? 23,
                          time?.minute ?? 59,
                        );
                      });
                    },
                    child: const Text('Change Time', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Active on Store', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: brandColor,
                      onChanged: (v) => setS(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await ApiService.put('/deals_timer/$id', {
                    'title': titleC.text.trim(),
                    'description': descC.text.trim(),
                    'end_time': endDt?.toIso8601String() ?? '',
                    'is_active': isActive,
                  });
                  ApiService.invalidateCache('/deals_timer');
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadTimers();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _cell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Text(
      text,
      style: TextStyle(
        color: AdminTheme.textPrimary,
        fontSize: 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AdminTheme.textMuted),
    filled: true,
    fillColor: darkBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _TimerClockDisplay extends StatefulWidget {
  final String rawEnd;
  final String formattedEnd;

  const _TimerClockDisplay({
    super.key,
    required this.rawEnd,
    required this.formattedEnd,
  });

  @override
  State<_TimerClockDisplay> createState() => _TimerClockDisplayState();
}

class _TimerClockDisplayState extends State<_TimerClockDisplay> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _calc();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_calc);
      }
    });
  }

  void _calc() {
    if (widget.rawEnd.isEmpty) {
      _remaining = null;
      return;
    }
    final end = DateTime.tryParse(widget.rawEnd);
    if (end == null) {
      _remaining = null;
      return;
    }
    final diff = end.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void didUpdateWidget(covariant _TimerClockDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawEnd != widget.rawEnd) {
      _calc();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    if (remaining == null) {
      return const Text(
        'No end date set for this timer',
        style: TextStyle(color: AdminTheme.textMuted, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildCountBox('DAYS', '${remaining.inDays}'),
            const SizedBox(width: 8),
            _buildCountBox('HOURS', '${remaining.inHours % 24}'.padLeft(2, '0')),
            const SizedBox(width: 8),
            _buildCountBox('MINS', '${remaining.inMinutes % 60}'.padLeft(2, '0')),
            const SizedBox(width: 8),
            _buildCountBox('SECS', '${remaining.inSeconds % 60}'.padLeft(2, '0')),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Ends at: ${widget.formattedEnd}',
          style: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCountBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}

