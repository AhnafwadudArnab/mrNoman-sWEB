import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/product_refresh_notifier.dart';
import '../utils/api_service.dart';
import 'Admin_sidebar.dart';
import 'A_customers.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminFlashSalesPage extends StatefulWidget {
  final bool embedded;

  const AdminFlashSalesPage({super.key, this.embedded = false});

  @override
  State<AdminFlashSalesPage> createState() => _AdminFlashSalesPageState();
}

class _AdminFlashSalesPageState extends State<AdminFlashSalesPage> {
  final Color darkBg = AdminTheme.bg;
  final Color cardBg = AdminTheme.surfaceAlt;
  final Color brandOrange = const Color(0xFF7C3AED);

  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  final _titleController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _active = true;
  DateTime? _pickedStart;
  DateTime? _pickedEnd;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getFlashSales();
      if (mounted)
        setState(() {
          _list = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
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
    if (item == AdminSidebarItem.flashSales) return;
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
      await ApiService.createFlashSale({
        'title': _titleController.text.trim(),
        'start_time': _startController.text.trim().isEmpty
            ? null
            : _startController.text.trim(),
        'end_time': _endController.text.trim().isEmpty
            ? null
            : _endController.text.trim(),
        'active': _active,
      });
      _titleController.clear();
      _startController.clear();
      _endController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Flash sale created'),
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

  Future<void> _update(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateFlashSale(id, data);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Updated'),
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

  Future<void> _delete(int id) async {
    try {
      await ApiService.deleteFlashSale(id);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text('Deleted'),
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

  Widget _buildContent() {
    return Column(
      children: [
        AdminPageHeader(
          color: cardBg,
          children: [
            const Text(
              'Flash Sales – Start/End time & Active',
              style: TextStyle(color: Color(0x73000000), fontSize: 14),
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
                      'Flash Sales',
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
                            'All flash sales',
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
                                      'No flash sales. Create one.',
                                      style: TextStyle(color: Color(0x73000000)),
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
                                                  '${e['flash_sale_id']}',
                                                  style: const TextStyle(
                                                    color: AdminTheme.textPrimary,
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
                                                    color: AdminTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                child: Text(
                                                  '${_fmt(e['start_time'])} – ${_fmt(e['end_time'])}',
                                                  style: const TextStyle(
                                                    color: Color(0x8A000000),
                                                    fontSize: 12,
                                                  ),
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
                                                      e['flash_sale_id'] as int,
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
                            'Create flash sale',
                            style: TextStyle(
                              color: AdminTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Title',
                              hintStyle: const TextStyle(color: AdminTheme.textMuted),
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
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Start (YYYY-MM-DD HH:mm)',
                              hintStyle: const TextStyle(color: AdminTheme.textMuted),
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
                                  color: Color(0x42000000),
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
                            style: const TextStyle(color: AdminTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'End (YYYY-MM-DD HH:mm)',
                              hintStyle: const TextStyle(color: AdminTheme.textMuted),
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
                                  color: Color(0x42000000),
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
    final startC = TextEditingController(text: _fmt(e['start_time']));
    final endC = TextEditingController(text: _fmt(e['end_time']));
    bool active = e['active'] == 1 || e['active'] == true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: cardBg,
          title: const Text(
            'Edit flash sale',
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
                    labelStyle: TextStyle(color: Color(0x73000000)),
                  ),
                ),
                TextField(
                  controller: startC,
                  readOnly: true,
                  onTap: () => _pickDateTime(startC, isStart: true),
                  style: const TextStyle(color: AdminTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Start',
                    labelStyle: TextStyle(color: Color(0x73000000)),
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
                    labelStyle: TextStyle(color: Color(0x73000000)),
                    suffixIcon: Icon(Icons.schedule, color: Color(0x42000000)),
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
                _update(e['flash_sale_id'] as int, {
                  'title': titleC.text.trim(),
                  'start_time': startC.text.trim(),
                  'end_time': endC.text.trim(),
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
      selected: AdminSidebarItem.flashSales,
      onItemSelected: (item) => _navigate(context, item),
      body: _buildContent(),
    );
  }
}











