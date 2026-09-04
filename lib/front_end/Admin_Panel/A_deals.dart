import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:electrocitybd1/front_end/Provider/product_refresh_notifier.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
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

class _AdminDealsPageState extends State<AdminDealsPage> {
  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandOrange = const Color(0xFF7C3AED);

  List<Map<String, dynamic>> _deals = [];
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  DateTime? _pickedStart;
  DateTime? _pickedEnd;
  final _productIdController = TextEditingController();
  final _dealPriceController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _dealPriceController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

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

  Future<void> _load() async {
    setState(() => _loading = true);
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
      final products =
          (productsRes['products'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      if (mounted) {
        setState(() {
          _deals = deals
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Failed to load'),
          ),
        );
    }
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.deals) return;
    AdminNav.go(context, item);
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Deal added'),
          ),
        );
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed')),
        );
    }
  }

  Future<void> _updateDeal(int dealId, Map<String, dynamic> data) async {
    try {
      await ApiService.updateDeal(dealId, data);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Deal updated'),
          ),
        );
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed')),
        );
    }
  }

  Future<void> _deleteDeal(int dealId) async {
    try {
      await ApiService.deleteDeal(dealId);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Deal removed'),
          ),
        );
      if (mounted) context.read<ProductRefreshNotifier>().refresh();
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed')),
        );
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Deals of the Day ? Timing & Price',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox.shrink(),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Deals of the Day',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh, color: AdminTheme.textPrimary),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    final listPanel = Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current deals',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loading)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7C3AED),
                              ),
                            )
                          else
                            _deals.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No deals. Add one with the form.',
                                      style: TextStyle(color: AdminTheme.textSecondary),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Table(
                                      defaultColumnWidth:
                                          const IntrinsicColumnWidth(),
                                      columnWidths: const {
                                        0: FixedColumnWidth(180),
                                        1: FixedColumnWidth(110),
                                        2: FixedColumnWidth(140),
                                        3: FixedColumnWidth(140),
                                        4: FixedColumnWidth(90),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            _cell('Product', bold: true),
                                            _cell('Deal price', bold: true),
                                            _cell('Start', bold: true),
                                            _cell('End', bold: true),
                                            _cell('Action', bold: true),
                                          ],
                                        ),
                                        ..._deals.map(
                                          (d) => TableRow(
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: AdminTheme.border,
                                                ),
                                              ),
                                            ),
                                            children: [
                                              _cell(
                                                (d['product_name'] ?? '')
                                                    .toString(),
                                              ),
                                              _cell(
                                                '?${d['deal_price'] ?? d['original_price']}',
                                              ),
                                              _cell(
                                                _formatDate(d['start_date']),
                                              ),
                                              _cell(_formatDate(d['end_date'])),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Color(0xFF7C3AED),
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _showEditDealDialog(d),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () =>
                                                        _deleteDeal(
                                                          d['deal_id'] as int,
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
                            'Add deal',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _label('Product ID'),
                          TextField(
                            controller: _productIdController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: _inputDeco('e.g. 1'),
                          ),
                          const SizedBox(height: 12),
                          _label('Deal price (?)'),
                          TextField(
                            controller: _dealPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: _inputDeco('Optional'),
                          ),
                          const SizedBox(height: 12),
                          _label('Start (YYYY-MM-DD or YYYY-MM-DD HH:mm)'),
                          TextField(
                            controller: _startDateController,
                            readOnly: true,
                            onTap: () => _pickDateTime(
                              _startDateController,
                              isStart: true,
                            ),
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: _inputDeco('Optional').copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => _pickDateTime(
                                  _startDateController,
                                  isStart: true,
                                ),
                                icon: const Icon(
                                  Icons.schedule,
                                  color: Color(0x42000000),
                                ),
                                tooltip: 'Pick date & time',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _label('End (YYYY-MM-DD or YYYY-MM-DD HH:mm)'),
                          TextField(
                            controller: _endDateController,
                            readOnly: true,
                            onTap: () => _pickDateTime(
                              _endDateController,
                              isStart: false,
                            ),
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: _inputDeco('Optional').copyWith(
                              suffixIcon: IconButton(
                                onPressed: () => _pickDateTime(
                                  _endDateController,
                                  isStart: false,
                                ),
                                icon: const Icon(
                                  Icons.schedule,
                                  color: Color(0x42000000),
                                ),
                                tooltip: 'Pick date & time',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addDeal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Add deal'),
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
                              const SizedBox(height: 16),
                              formPanel,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: listPanel),
                              const SizedBox(width: 24),
                              Expanded(child: formPanel),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDealDialog(Map<String, dynamic> d) {
    final priceC = TextEditingController(
      text: '${d['deal_price'] ?? d['original_price'] ?? ''}',
    );
    final startC = TextEditingController(text: _formatDate(d['start_date']));
    final endC = TextEditingController(text: _formatDate(d['end_date']));
    try {
      if ((d['start_date'] ?? '').toString().isNotEmpty)
        _pickedStart = DateTime.tryParse((d['start_date']).toString());
      if ((d['end_date'] ?? '').toString().isNotEmpty)
        _pickedEnd = DateTime.tryParse((d['end_date']).toString());
    } catch (_) {}
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: const Text('Edit deal', style: TextStyle(color: AdminTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product: ${d['product_name']}',
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
                  labelText: 'Start',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  suffixIcon: Icon(Icons.schedule, color: Color(0x42000000)),
                ),
              ),
              TextField(
                controller: endC,
                readOnly: true,
                onTap: () => _pickDateTime(endC, isStart: false),
                style: const TextStyle(color: AdminTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'End',
                  labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  suffixIcon: Icon(Icons.schedule, color: Color(0x42000000)),
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
            style: ElevatedButton.styleFrom(backgroundColor: brandOrange),
            onPressed: () {
              Navigator.pop(ctx);
              _updateDeal(d['deal_id'] as int, {
                'deal_price': priceC.text.trim().isEmpty
                    ? null
                    : double.tryParse(priceC.text),
                'start_date': startC.text.trim().isEmpty
                    ? null
                    : startC.text.trim(),
                'end_date': endC.text.trim().isEmpty ? null : endC.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.length >= 10) return s.substring(0, s.length > 16 ? 16 : s.length);
    return s;
  }

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

  @override
  Widget build(BuildContext context) {
    if (widget.embedded)
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildContent()),
      );
    return AdminScaffold(
      selected: AdminSidebarItem.deals,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildContent(),
    );
  }
}






















