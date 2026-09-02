import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../utils/api_service.dart';
import 'A_customers.dart';
import 'Admin_sidebar.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminPromotionsPage extends StatefulWidget {
  final bool embedded;

  const AdminPromotionsPage({super.key, this.embedded = false});

  @override
  State<AdminPromotionsPage> createState() => _AdminPromotionsPageState();
}

class _AdminPromotionsPageState extends State<AdminPromotionsPage> {
  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandOrange = const Color(0xFF7C3AED);

  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _percentController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _active = true;
  DateTime? _pickedStart;
  DateTime? _pickedEnd;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _percentController.dispose();
    _startController.dispose();
    _endController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.get(
        '/promotions?all=1',
        withAuth: true,
      );
      final list = response is List
          ? response
          : (response['promotions'] as List? ?? []);
      if (mounted) {
        setState(() {
          _list = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Promotions load error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load promotions: ${e.toString()}')),
        );
      }
    }
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.promotions) return;
    AdminNav.go(context, item);
  }

  Future<void> _create() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter title')));
      return;
    }
    try {
      await ApiService.createPromotion({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'discount_percent': _percentController.text.trim().isEmpty
            ? null
            : double.tryParse(_percentController.text.trim()),
        'start_date': _startController.text.trim().isEmpty
            ? null
            : _startController.text.trim(),
        'end_date': _endController.text.trim().isEmpty
            ? null
            : _endController.text.trim(),
        'active': _active,
      });
      _titleController.clear();
      _descController.clear();
      _percentController.clear();
      _startController.clear();
      _endController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Promotion created'),
          ),
        );
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Failed')),
        );
    }
  }

  Future<void> _update(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.updatePromotion(id, data);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Updated'),
          ),
        );
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Update failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text('Are you sure you want to delete this promotion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deletePromotion(id);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Deleted'),
          ),
        );
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Delete failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  int _toId(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  String _fmt(dynamic v) => v?.toString() ?? '';

  Future<void> _pickDateTime(
    TextEditingController controller, {
    required bool isStart,
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

  String _two(int v) => v.toString().padLeft(2, '0');
  String _fmtDateTime(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

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

  Widget _buildContent() {
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Promotions – Title, Dates & Discount %',
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
                      'Promotions',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(
                        Icons.refresh,
                        color: AdminTheme.textPrimary,
                      ),
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
                            'All promotions',
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
                            _list.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No promotions. Create one.',
                                      style: TextStyle(
                                        color: AdminTheme.textSecondary,
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Table(
                                      defaultColumnWidth:
                                          const IntrinsicColumnWidth(),
                                      children: [
                                        const TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'ID',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'Title',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                '%',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'Start – End',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'Active',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        ..._list.map(
                                          (e) => TableRow(
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Color(0x0D000000),
                                                ),
                                              ),
                                            ),
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  '${e['promotion_id']}',
                                                  style: const TextStyle(
                                                    color:
                                                        AdminTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  _fmt(e['title']),
                                                  style: const TextStyle(
                                                    color:
                                                        AdminTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  '${e['discount_percent'] ?? ''}%',
                                                  style: const TextStyle(
                                                    color:
                                                        AdminTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${_fmt(e['start_date'])} – ${_fmt(e['end_date'])}',
                                                      style: const TextStyle(
                                                        color: AdminTheme
                                                            .textPrimary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _timeLeft(
                                                        e['start_date'],
                                                        e['end_date'],
                                                      ),
                                                      style: const TextStyle(
                                                        color: AdminTheme
                                                            .textSecondary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  (e['active'] == 1 ||
                                                          e['active'] == true)
                                                      ? 'Yes'
                                                      : 'No',
                                                  style: TextStyle(
                                                    color:
                                                        (e['active'] == 1 ||
                                                            e['active'] == true)
                                                        ? Colors.green
                                                        : Colors.red,
                                                  ),
                                                ),
                                              ),
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
                                                        _showEdit(e),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => _delete(
                                                      _toId(e['promotion_id']),
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
                        border: Border.all(color: Color(0x0D000000)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create promotion',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Title *',
                              hintStyle: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descController,
                            maxLines: 2,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Description',
                              hintStyle: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _percentController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Discount %',
                              hintStyle: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _startController,
                            readOnly: true,
                            onTap: () =>
                                _pickDateTime(_startController, isStart: true),
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start (YYYY-MM-DD HH:mm)',
                              hintStyle: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => _pickDateTime(
                                  _startController,
                                  isStart: true,
                                ),
                                icon: const Icon(
                                  Icons.schedule,
                                  color: AdminTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _endController,
                            readOnly: true,
                            onTap: () =>
                                _pickDateTime(_endController, isStart: false),
                            style: const TextStyle(
                              color: AdminTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'End (YYYY-MM-DD HH:mm)',
                              hintStyle: const TextStyle(
                                color: AdminTheme.textMuted,
                              ),
                              filled: true,
                              fillColor: darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => _pickDateTime(
                                  _endController,
                                  isStart: false,
                                ),
                                icon: const Icon(
                                  Icons.schedule,
                                  color: AdminTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'Active ',
                                style: TextStyle(color: AdminTheme.textPrimary),
                              ),
                              Switch(
                                value: _active,
                                onChanged: (v) => setState(() => _active = v),
                                activeColor: brandOrange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _create,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Create'),
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

  void _showEdit(Map<String, dynamic> e) {
    final titleC = TextEditingController(text: _fmt(e['title']));
    final descC = TextEditingController(text: _fmt(e['description']));
    final percentC = TextEditingController(
      text: e['discount_percent'] != null ? '${e['discount_percent']}' : '',
    );
    final startC = TextEditingController(text: _fmt(e['start_date']));
    final endC = TextEditingController(text: _fmt(e['end_date']));
    bool active = e['active'] == 1 || e['active'] == true;

    Future<void> pickDt(
      BuildContext ctx,
      TextEditingController controller,
      bool isStart,
      StateSetter setD,
    ) async {
      final now = DateTime.now();
      final existing = DateTime.tryParse(controller.text) ?? now;
      final date = await showDatePicker(
        context: ctx,
        initialDate: existing,
        firstDate: DateTime(now.year - 2),
        lastDate: DateTime(now.year + 5),
      );
      if (date == null) return;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(existing),
      );
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
      controller.text = _fmtDateTime(dt);
      setD(() {});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: cardBg,
          title: const Text(
            'Edit promotion',
            style: TextStyle(color: AdminTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                TextField(
                  controller: descC,
                  maxLines: 2,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                TextField(
                  controller: percentC,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Discount %',
                    labelStyle: TextStyle(color: AdminTheme.textSecondary),
                  ),
                ),
                TextField(
                  controller: startC,
                  readOnly: true,
                  onTap: () => pickDt(ctx, startC, true, setDialog),
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Start',
                    labelStyle: const TextStyle(
                      color: AdminTheme.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.schedule,
                        color: AdminTheme.textMuted,
                      ),
                      onPressed: () => pickDt(ctx, startC, true, setDialog),
                    ),
                  ),
                ),
                TextField(
                  controller: endC,
                  readOnly: true,
                  onTap: () => pickDt(ctx, endC, false, setDialog),
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'End',
                    labelStyle: const TextStyle(
                      color: AdminTheme.textSecondary,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.schedule,
                        color: AdminTheme.textMuted,
                      ),
                      onPressed: () => pickDt(ctx, endC, false, setDialog),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Active ',
                      style: TextStyle(color: AdminTheme.textPrimary),
                    ),
                    Switch(
                      value: active,
                      onChanged: (v) => setDialog(() => active = v),
                      activeColor: brandOrange,
                    ),
                  ],
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
                _update(_toId(e['promotion_id']), {
                  'title': titleC.text.trim(),
                  'description': descC.text.trim(),
                  'discount_percent': percentC.text.trim().isEmpty
                      ? null
                      : double.tryParse(percentC.text.trim()),
                  'start_date': startC.text.trim().isEmpty
                      ? null
                      : startC.text.trim(),
                  'end_date': endC.text.trim().isEmpty
                      ? null
                      : endC.text.trim(),
                  'active': active,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded)
      return Material(
        color: darkBg,
        child: SizedBox.expand(child: _buildContent()),
      );
    return AdminScaffold(
      selected: AdminSidebarItem.promotions,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildContent(),
    );
  }
}
