import 'dart:async';

import 'package:flutter/material.dart';

import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/A_customers.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/Admin_sidebar.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_scaffold.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminDiscountPage extends StatefulWidget {
  final bool embedded;

  const AdminDiscountPage({super.key, this.embedded = false});

  @override
  State<AdminDiscountPage> createState() => _AdminDiscountPageState();
}

class _AdminDiscountPageState extends State<AdminDiscountPage> {
  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandOrange = const Color(0xFF7C3AED);

  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _percentController = TextEditingController();
  final TextEditingController _validFromController = TextEditingController();
  final TextEditingController _validToController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  List<Map<String, dynamic>> _discounts = [];
  bool _loading = true;
  DateTime? _pickedFrom;
  DateTime? _pickedTo;
  Timer? _timer;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadDiscounts() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getDiscounts();
      if (mounted)
        setState(() {
          _discounts = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Failed to load discounts',
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _percentController.dispose();
    _validFromController.dispose();
    _validToController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.discounts) return;
    AdminNav.go(context, item);
  }

  Widget _buildDiscountContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopActionRow(),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    return isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDiscountList(),
                              const SizedBox(height: 16),
                              Container(
                                key: _formKey,
                                child: _buildCreateDiscountForm(),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildDiscountList()),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  key: _formKey,
                                  child: _buildCreateDiscountForm(),
                                ),
                              ),
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

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildDiscountContent()),
      );
    }
    return AdminScaffold(
      selected: AdminSidebarItem.discounts,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildDiscountContent(),
    );
  }

  Future<void> _pickDateTime(
    TextEditingController controller, {
    bool isFrom = true,
  }) async {
    final now = DateTime.now();
    final initial = isFrom ? (_pickedFrom ?? now) : (_pickedTo ?? now);
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
    if (isFrom) {
      _pickedFrom = dt;
    } else {
      _pickedTo = dt;
    }
    controller.text = _fmtDateTime(dt);
    setState(() {});
  }

  String _fmtDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _timeLeft(dynamic fromRaw, dynamic toRaw) {
    final now = DateTime.now();
    final from = DateTime.tryParse((fromRaw ?? '').toString());
    final to = DateTime.tryParse((toRaw ?? '').toString());
    if (to == null) return '';
    if (from != null && now.isBefore(from)) {
      final diff = from.difference(now);
      return 'Starts in ${_fmtDuration(diff)}';
    }
    if (now.isAfter(to)) {
      final diff = now.difference(to);
      return 'Expired ${_fmtDuration(diff)} ago';
    }
    final diff = to.difference(now);
    return 'Ends in ${_fmtDuration(diff)}';
  }

  String _fmtDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Widget _buildHeader() => AdminPageHeader(
    color: cardBg,
    children: [
      const Text(
        "Management / Discounts",
        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
      ),
      const SizedBox.shrink(),
    ],
  );

  Widget _buildTopActionRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Discounts & Coupons",
          style: TextStyle(
            color: AdminTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Scrollable.ensureVisible(
              _formKey.currentContext!,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          icon: const Icon(Icons.add, color: AdminTheme.textPrimary),
          label: const Text("New Campaign"),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: AdminTheme.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ],
    );
  }

  String _discountStatus(Map<String, dynamic> d) {
    final to = d['valid_to']?.toString();
    final from = d['valid_from']?.toString();
    if (to == null || to.isEmpty) return 'Active';
    final end = DateTime.tryParse(to);
    if (end != null && end.isBefore(DateTime.now())) return 'Expired';
    if (from != null && from.isNotEmpty) {
      final start = DateTime.tryParse(from);
      if (start != null && start.isAfter(DateTime.now())) return 'Scheduled';
    }
    return 'Active';
  }

  Widget _buildDiscountList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: brandOrange,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Product Discounts (with validity period)",
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 600),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(180),
                    1: FixedColumnWidth(70),
                    2: FixedColumnWidth(160),
                    3: FixedColumnWidth(160),
                    4: FixedColumnWidth(140),
                    5: FixedColumnWidth(50),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: [
                        _tableCell("PRODUCT", isBold: true, color: AdminTheme.textSecondary),
                        _tableCell("% OFF", isBold: true, color: AdminTheme.textSecondary),
                        _tableCell(
                          "VALID FROM",
                          isBold: true,
                          color: AdminTheme.textSecondary,
                        ),
                        _tableCell(
                          "VALID TO",
                          isBold: true,
                          color: AdminTheme.textSecondary,
                        ),
                        _tableCell("STATUS", isBold: true, color: AdminTheme.textSecondary),
                        _tableCell("", isBold: true, color: AdminTheme.textSecondary),
                      ],
                    ),
                    ..._discounts.map(
                      (d) => TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AdminTheme.border),
                          ),
                        ),
                        children: [
                          _tableCell(
                            ((d['scope']?.toString() ?? '').toLowerCase() ==
                                    'all')
                                ? 'All Products'
                                : (d['product_name'] ?? '').toString(),
                            isBold: false,
                          ),
                          _tableCell(
                            '${d['discount_percent'] ?? ''}%',
                            color: brandOrange,
                          ),
                          _tableCell((d['valid_from'] ?? '').toString()),
                          _tableCell((d['valid_to'] ?? '').toString()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statusBadge(_discountStatus(d)),
                                const SizedBox(height: 4),
                                Text(
                                  _timeLeft(d['valid_from'], d['valid_to']),
                                  style: TextStyle(
                                    color: AdminTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () =>
                                _deleteDiscount(d['discount_id'] as int),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ), // close SingleChildScrollView
        ],
      ),
    );
  }

  Future<void> _deleteDiscount(int id) async {
    try {
      await ApiService.deleteDiscount(id);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Discount removed'),
          ),
        );
      _loadDiscounts();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed')),
        );
    }
  }

  Widget _buildCreateDiscountForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: brandOrange,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add product discount",
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Switch(
                value: _applyToAll,
                onChanged: (v) => setState(() => _applyToAll = v),
                activeColor: brandOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Apply to all products",
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
            ],
          ),
          if (!_applyToAll) ...[
            const SizedBox(height: 12),
            _inputLabel("Product ID"),
          _darkField("e.g. 1", controller: _productIdController),
          ],
          const SizedBox(height: 20),
          _inputLabel("Discount %"),
          _darkField("e.g. 10", controller: _percentController),
          const SizedBox(height: 20),
          _inputLabel("Valid from (YYYY-MM-DD)"),
          TextField(
            controller: _validFromController,
            readOnly: true,
            onTap: () => _pickDateTime(_validFromController, isFrom: true),
            style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Optional",
              hintStyle: const TextStyle(
                color: AdminTheme.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: darkBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
              suffixIcon: IconButton(
                onPressed: () =>
                    _pickDateTime(_validFromController, isFrom: true),
                icon: const Icon(Icons.schedule, color: Color(0x42000000)),
                tooltip: 'Pick date & time',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _inputLabel("Valid to (YYYY-MM-DD)"),
          TextField(
            controller: _validToController,
            readOnly: true,
            onTap: () => _pickDateTime(_validToController, isFrom: false),
            style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Optional",
              hintStyle: const TextStyle(
                color: AdminTheme.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: darkBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
              suffixIcon: IconButton(
                onPressed: () =>
                    _pickDateTime(_validToController, isFrom: false),
                icon: const Icon(Icons.schedule, color: Color(0x42000000)),
                tooltip: 'Pick date & time',
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _createDiscount,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandOrange,
              side: BorderSide(color: brandOrange),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Create discount",
              style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDiscount() async {
    int? productId;
    if (!_applyToAll) {
      productId = int.tryParse(_productIdController.text.trim());
      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enter a valid product ID"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    final percent = double.tryParse(_percentController.text.trim());
    if (percent == null || percent <= 0 || percent > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter discount % between 1 and 100"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final payload = <String, dynamic>{
        'discount_percent': percent,
        'valid_from': _validFromController.text.trim().isEmpty
            ? null
            : _validFromController.text.trim(),
        'valid_to': _validToController.text.trim().isEmpty
            ? null
            : _validToController.text.trim(),
      };
      if (_applyToAll) {
        payload['scope'] = 'all';
      } else {
        payload['scope'] = 'product';
        payload['product_id'] = productId;
      }
      await ApiService.createDiscount(payload);
      _productIdController.clear();
      _percentController.clear();
      _validFromController.clear();
      _validToController.clear();
      setState(() => _applyToAll = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Discount created"),
            backgroundColor: Colors.green,
          ),
        );
        _loadDiscounts();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Widget _tableCell(
    String text, {
    bool isBold = false,
    Color color = Colors.white,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _statusBadge(String status) {
    Color sColor = status == "Active"
        ? Colors.green
        : (status == "Expired" ? Colors.red : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: sColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: sColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TextStyle(
        color: AdminTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _darkField(String hint, {TextEditingController? controller}) =>
      TextField(
        controller: controller,
        style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
          filled: true,
          fillColor: darkBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      );
}










