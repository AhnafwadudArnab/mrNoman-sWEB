import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/Admin_product_provider.dart';
import '../utils/api_service.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminDealsTimerPage extends StatefulWidget {
  final bool embedded;
  const AdminDealsTimerPage({super.key, this.embedded = false});

  @override
  State<AdminDealsTimerPage> createState() => _AdminDealsTimerPageState();
}

class _AdminDealsTimerPageState extends State<AdminDealsTimerPage> {
  static const _cardBg = AdminTheme.surfaceAlt;
  static final _darkBg = AdminTheme.bg;
  static const _orange = Color(0xFF7C3AED);

  bool _loading = true;
  List<Map<String, dynamic>> _timers = [];
  String? _error;
  Timer? _tick;

  // Product management
  List<Map<String, dynamic>> _dealsProducts = [];
  bool _loadingProducts = false;
  String? _selectedTimer;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _productImageController = TextEditingController();
  final TextEditingController _productModelController = TextEditingController();
  String? _selectedCategory;
  String? _selectedBrand;
  int? _productStock = 10;

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _loadDealsProducts();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productImageController.dispose();
    _productDescriptionController.dispose();
    _productModelController.dispose();
    super.dispose();
  }

  Future<void> _loadTimers() async {
    setState(() {
      _loading = true;
      _error = null;
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
      setState(() {
        _timers = safeList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _timers = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDealsProducts() async {
    setState(() => _loadingProducts = true);
    try {
      // Get products from AdminProductProvider instead of API
      if (mounted) {
        final provider = context.read<AdminProductProvider>();
        final products = provider.getProductsBySection('Deals of the Day');
        setState(() {
          _dealsProducts = List<Map<String, dynamic>>.from(products);
          _loadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProduct() async {
    if (_productNameController.text.isEmpty ||
        _productPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in product name and price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ApiService.post('/products/create', {
        'name': _productNameController.text,
        'price': double.tryParse(_productPriceController.text) ?? 0,
        'description': _productDescriptionController.text,
        'image': _productImageController.text,
        'model': _productModelController.text,
        'category': _selectedCategory ?? '',
        'brand': _selectedBrand ?? '',
        'stock': _productStock ?? 10,
        'section': 'Deals of the Day',
      }, withAuth: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _productNameController.clear();
        _productPriceController.clear();
        _productDescriptionController.clear();
        _productImageController.clear();
        _productModelController.clear();
        _selectedCategory = null;
        _selectedBrand = null;
        _productStock = 10;
        _loadDealsProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _getId(Map<String, dynamic> t) {
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

  String _fmtDuration(Duration d) {
    final days = d.inDays;
    final h = d.inHours % 24;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (days > 0) return '${days}d ${_p(h)}:${_p(m)}:${_p(s)}';
    return '${_p(h)}:${_p(m)}:${_p(s)}';
  }

  String _p(int v) => v.toString().padLeft(2, '0');

  String _fmtDateTime(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';

  Future<DateTime?> _pickDt(BuildContext ctx, DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              onPrimary: Colors.black,
              surface: const Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !ctx.mounted) return null;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              onPrimary: Colors.black,
              surface: const Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showAddDialog() {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    DateTime? endDt;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) => AlertDialog(
          backgroundColor: _cardBg,
          title: const Text(
            'Add Timer',
            style: TextStyle(color: AdminTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(titleC, 'Title *'),
                const SizedBox(height: 12),
                _field(descC, 'Description'),
                const SizedBox(height: 12),
                _dtRow(
                  context,
                  label: endDt == null ? 'No end time' : _fmtDateTime(endDt!),
                  onPick: () async {
                    final dt = await _pickDt(context, endDt);
                    if (dt != null) setS(() => endDt = dt);
                  },
                  onClear: endDt != null
                      ? () => setS(() => endDt = null)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (titleC.text.trim().isEmpty) return;
                try {
                  await ApiService.post('/deals_timer', {
                    'title': titleC.text.trim(),
                    'description': descC.text.trim(),
                    'end_time': endDt?.toIso8601String() ?? '',
                  });
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer added'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadTimers();
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> timer) {
    final id = _getId(timer);
    final titleC = TextEditingController(text: timer['title'] ?? '');
    final descC = TextEditingController(text: timer['description'] ?? '');
    final rawEnd = timer['end_time']?.toString() ?? '';
    DateTime? endDt = rawEnd.isNotEmpty ? DateTime.tryParse(rawEnd) : null;
    bool isActive = timer['is_active'] == 1 || timer['is_active'] == true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setS) => AlertDialog(
          backgroundColor: _cardBg,
          title: const Text(
            'Edit Timer',
            style: TextStyle(color: AdminTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(titleC, 'Title *'),
                const SizedBox(height: 12),
                _field(descC, 'Description'),
                const SizedBox(height: 12),
                _dtRow(
                  context,
                  label: endDt == null ? 'No end time' : _fmtDateTime(endDt!),
                  onPick: () async {
                    final dt = await _pickDt(context, endDt);
                    if (dt != null) setS(() => endDt = dt);
                  },
                  onClear: endDt != null
                      ? () => setS(() => endDt = null)
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Active',
                      style: TextStyle(color: Color(0x8A000000)),
                    ),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: _orange,
                      onChanged: (v) => setS(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                try {
                  await ApiService.put('/deals_timer/$id', {
                    'title': titleC.text.trim(),
                    'description': descC.text.trim(),
                    'end_time': endDt?.toIso8601String() ?? '',
                    'is_active': isActive,
                  });
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Timer updated'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadTimers();
                  }
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTimer(Map<String, dynamic> timer) async {
    final id = _getId(timer);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text(
          'Delete Timer',
          style: TextStyle(color: AdminTheme.textPrimary),
        ),
        content: Text(
          'Delete "${timer['title'] ?? 'Timer'}"?',
          style: const TextStyle(color: AdminTheme.textMuted),
        ),
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
    if (ok != true) return;
    try {
      await ApiService.delete('/deals_timer/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadTimers();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Widget _field(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(color: AdminTheme.textPrimary),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdminTheme.textSecondary),
      filled: true,
      fillColor: _darkBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _dtRow(
    BuildContext ctx, {
    required String label,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _darkBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule, color: Color(0x42000000), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
          ),
        ),
        TextButton(onPressed: onPick, child: const Text('Pick')),
        if (onClear != null)
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0x42000000)),
            onPressed: onClear,
          ),
      ],
    ),
  );

  Widget _countdownChip(Duration d) {
    final expired = d == Duration.zero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: expired
            ? Colors.red.withOpacity(0.15)
            : _orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: expired
              ? Colors.red.withOpacity(0.4)
              : _orange.withOpacity(0.4),
        ),
      ),
      child: Text(
        expired ? 'Expired' : _fmtDuration(d),
        style: TextStyle(
          color: expired ? Colors.red : _orange,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildProductUploadSection() {
    const Color fieldBg = AdminTheme.surface;
    return Card(
      color: _cardBg,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload to: Deals of the Day',
                style: const TextStyle(
                  color: _orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: A maximum of 5 items can be displayed in this section',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Timer Selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Offer Timer',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedTimer,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Choose a timer for this offer',
                      hintStyle: const TextStyle(
                        color: AdminTheme.textSecondary,
                      ),
                      fillColor: fieldBg,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: const Text('No Timer'),
                      ),
                      ..._timers.map((timer) {
                        final timerId = _getId(timer);
                        final title = timer['title'] ?? 'Unnamed Timer';
                        return DropdownMenuItem(
                          value: timerId.toString(),
                          child: Text(title),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedTimer = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _productNameController,
                          style: const TextStyle(color: AdminTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Product Name',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _productPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(color: AdminTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Price (BDT)',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: '10',
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AdminTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Stock',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            _productStock = int.tryParse(v) ?? 10;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _productDescriptionController,
                          maxLines: 3,
                          style: const TextStyle(color: AdminTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Full Description',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Category',
                                    style: TextStyle(
                                      color: AdminTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String?>(
                                    value: _selectedCategory,
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      fillColor: fieldBg,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: const Text('Select Category'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Air Fryers',
                                        child: const Text('Air Fryers'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Mixers',
                                        child: const Text('Mixers'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Fans',
                                        child: const Text('Fans'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedCategory = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Brand',
                                    style: TextStyle(
                                      color: AdminTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String?>(
                                    value: _selectedBrand,
                                    style: const TextStyle(
                                      color: AdminTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      fillColor: fieldBg,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: const Text('Select Brand'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Samsung',
                                        child: const Text('Samsung'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'LG',
                                        child: const Text('LG'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'AV',
                                        child: const Text('AV'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedBrand = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _productModelController,
                          style: const TextStyle(color: AdminTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Model (optional)',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _productImageController.text.isNotEmpty
                              ? Image.network(
                                  _productImageController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                        size: 50,
                                      ),
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            // File picker would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image URL upload coming soon'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: AdminTheme.textPrimary,
                          ),
                          child: const Text('Upload Image'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _productImageController,
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'or paste Image URL',
                            hintStyle: const TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 11,
                            ),
                            fillColor: fieldBg,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Publish to Deals of the Day',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealsProductsList() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory, color: _orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Products in Deals of the Day',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0x73000000),
                  size: 20,
                ),
                onPressed: _loadDealsProducts,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingProducts)
            const Center(child: CircularProgressIndicator(color: _orange))
          else if (_dealsProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Colors.white12,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No products yet',
                      style: TextStyle(color: Color(0x73000000), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dealsProducts.length,
              itemBuilder: (context, index) {
                final product = _dealsProducts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (product['image'] != null &&
                          product['image'].toString().isNotEmpty)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(product['image'].toString()),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {},
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']?.toString() ?? 'N/A',
                              style: const TextStyle(
                                color: AdminTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Price: ৳${product['price']?.toString() ?? '0'}',
                              style: const TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: _orange, size: 18),
                        onPressed: () {},
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () {},
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, size: 72, color: Colors.white12),
        const SizedBox(height: 16),
        const Text(
          'No timers yet',
          style: TextStyle(
            color: Color(0x73000000),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add a countdown timer for your deals',
          style: TextStyle(color: Color(0x42000000), fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Timer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );

  Widget _timerCard(Map<String, dynamic> timer) {
    final remaining = _remaining(timer);
    final isActive = timer['is_active'] == 1 || timer['is_active'] == true;
    final rawEnd = timer['end_time']?.toString() ?? '';
    final endDt = rawEnd.isNotEmpty ? DateTime.tryParse(rawEnd) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _orange.withOpacity(0.35) : Color(0x0D000000),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _orange.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? _orange.withOpacity(0.15) : Color(0x0D000000),
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(color: _orange.withOpacity(0.3))
                    : null,
              ),
              child: Icon(
                Icons.timer,
                color: isActive ? _orange : Color(0x42000000),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          timer['title'] ?? 'Timer',
                          style: const TextStyle(
                            color: AdminTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((timer['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      timer['description'],
                      style: const TextStyle(
                        color: Color(0x73000000),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (endDt != null) ...[
                        const Icon(
                          Icons.event,
                          color: Color(0x42000000),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ends: ${_fmtDateTime(endDt)}',
                          style: const TextStyle(
                            color: Color(0x42000000),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (remaining != null) _countdownChip(remaining),
                      if (endDt == null)
                        const Text(
                          'No end time set',
                          style: TextStyle(
                            color: Color(0x1F000000),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  onPressed: () => _showEditDialog(timer),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _deleteTimer(timer),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Column(
        children: [
          AdminPageHeader(
            color: _cardBg,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: _orange, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Deals Timer',
                    style: TextStyle(
                      color: AdminTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _loadTimers,
                    icon: const Icon(Icons.refresh, color: Color(0x73000000)),
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Timer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Timers Section (Offer Time) - 2nd
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadTimers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _orange))
                : _timers.isEmpty
                ? _emptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _timers.length,
                    itemBuilder: (_, i) => _timerCard(_timers[i]),
                  ),
          ),
          // Product Upload Section - 3rd
          _buildProductUploadSection(),
          // Products List Section - Last
          _buildDealsProductsList(),
        ],
      ),
    );

    if (widget.embedded) {
      return Material(
        color: _darkBg,
        child: SizedBox.expand(child: content),
      );
    }
    return Scaffold(backgroundColor: _darkBg, body: content);
  }
}
