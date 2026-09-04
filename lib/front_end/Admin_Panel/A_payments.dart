import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminPaymentsPage extends StatefulWidget {
  final bool embedded;
  const AdminPaymentsPage({super.key, this.embedded = false});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  static const Color _brandOrange = Color(0xFF7C3AED);
  static const Color _cardBg = AdminTheme.surfaceAlt;
  static const Color _panelBg = AdminTheme.bg;
  static const Color _fieldBg = AdminTheme.surfaceAlt;

  bool _loading = true;
  List<Map<String, dynamic>> _paymentMethods = [];
  String? _error;

  // Delivery charge controllers
  final _insideDhakaCtrl = TextEditingController();
  final _outsideDhakaCtrl = TextEditingController();
  bool _savingCharges = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadDeliveryCharges();
  }

  @override
  void dispose() {
    _insideDhakaCtrl.dispose();
    _outsideDhakaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveryCharges() async {
    try {
      final inside = await ApiService.getSiteSetting(
        'delivery_charge_inside_dhaka',
      );
      final outside = await ApiService.getSiteSetting(
        'delivery_charge_outside_dhaka',
      );
      if (mounted) {
        _insideDhakaCtrl.text = inside['setting_value']?.toString() ?? '60';
        _outsideDhakaCtrl.text = outside['setting_value']?.toString() ?? '120';
      }
    } catch (_) {
      _insideDhakaCtrl.text = '60';
      _outsideDhakaCtrl.text = '120';
    }
  }

  Future<void> _saveDeliveryCharges() async {
    final inside = double.tryParse(_insideDhakaCtrl.text.trim());
    final outside = double.tryParse(_outsideDhakaCtrl.text.trim());
    if (inside == null || outside == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _savingCharges = true);
    try {
      await ApiService.saveSiteSetting({
        'setting_key': 'delivery_charge_inside_dhaka',
        'setting_value': inside.toString(),
      });
      await ApiService.saveSiteSetting({
        'setting_key': 'delivery_charge_outside_dhaka',
        'setting_value': outside.toString(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery charges updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _savingCharges = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/payment_methods', withAuth: true);
      final methods = response is List
          ? response
          : (response['payment_methods'] as List? ??
                response['data'] as List? ??
                []);

      setState(() {
        _paymentMethods = methods
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Payment methods load error: $e');
      setState(() {
        _error = 'Error loading payment methods: ${e.toString()}';
        _loading = false;
      });
    }
  }

  bool _isMethodEnabled(dynamic rawValue) {
    if (rawValue is bool) return rawValue;
    if (rawValue is num) return rawValue == 1;
    if (rawValue is String) {
      final value = rawValue.trim().toLowerCase();
      return value == '1' || value == 'true' || value == 'yes';
    }
    return false;
  }

  int _methodId(Map<String, dynamic> method) {
    final raw =
        method['method_id'] ??
        method['payment_method_id'] ??
        method['payment_id'] ??
        method['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<void> _toggleStatus(int methodId, bool nextStatus) async {
    if (methodId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment method ID missing. Refresh and try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final response = await ApiService.put('/payment_methods/$methodId', {
        'method_id': methodId,
        'toggle_status': true,
        'is_enabled': nextStatus ? 1 : 0,
      });

      if (response['success'] == true) {
        await _loadPaymentMethods();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment method ${nextStatus ? 'enabled' : 'disabled'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Failed to update status',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? method}) async {
    final isEdit = method != null;
    final nameController = TextEditingController(
      text: method?['method_name'] ?? '',
    );
    final accountController = TextEditingController(
      text: method?['account_number'] ?? '',
    );
    String selectedType = method?['method_type'] ?? 'mobile_banking';
    bool isEnabled = _isMethodEnabled(method?['is_enabled']);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Method Name',
                    hintText: 'e.g., bKash, Nagad, Rocket',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Method Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'mobile_banking',
                      child: Text('Mobile Banking'),
                    ),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Bank Transfer'),
                    ),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                      value: 'card',
                      child: Text('Card Payment'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                // Account number only for non-cash methods
                if (selectedType != 'cash') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: accountController,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      hintText: '01XXXXXXXXX',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('Show this method in checkout'),
                  value: isEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      isEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter method name')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final data = {
                    'method_name': name,
                    'method_type': selectedType,
                    'account_number': selectedType == 'cash'
                        ? ''
                        : accountController.text.trim(),
                    'is_enabled': isEnabled ? 1 : 0,
                    'display_order': method?['display_order'] ?? 0,
                  };

                  final response = isEdit
                      ? await ApiService.put(
                          '/payment_methods/${_methodId(method)}',
                          data,
                        )
                      : await ApiService.post('/payment_methods', data);

                  if (response['success'] == true) {
                    await _loadPaymentMethods();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Payment method updated'
                              : 'Payment method added',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response['message']?.toString() ?? 'Operation failed',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMethod(int methodId, String methodName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "$methodName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete('/payment_methods/$methodId');
      if (response['success'] == true) {
        await _loadPaymentMethods();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment method deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _brandOrange),
      );
    }

    final enabledCount = _paymentMethods
        .where((method) => _isMethodEnabled(method['is_enabled']))
        .length;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            if (_error != null) _errorBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPaymentMethods,
                child: ListView(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  children: [
                    _hero(enabledCount),
                    const SizedBox(height: 18),
                    _deliveryChargeCard(),
                    const SizedBox(height: 18),
                    _methodsHeader(enabledCount),
                    const SizedBox(height: 12),
                    if (_paymentMethods.isEmpty)
                      _emptyState()
                    else
                      ..._paymentMethods.map(_methodCard),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return Material(
        color: AdminTheme.bg,
        child: SizedBox.expand(child: content),
      );
    }
    return Scaffold(backgroundColor: AdminTheme.bg, body: content);
  }

  Widget _topBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final addButton = ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          );
          const title = Text(
            'Management / Payments',
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [title, const SizedBox(height: 10), addButton],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _metricsGrid(List<Widget> metrics, double maxWidth) {
    final columns = maxWidth < 430 ? 1 : 3;
    final spacing = 10.0;
    final tileWidth = columns == 1
        ? maxWidth
        : (maxWidth - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: metrics
          .map((metric) => SizedBox(width: tileWidth, child: metric))
          .toList(),
    );
  }

  Widget _hero(int enabledCount) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 740;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Operations',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage checkout methods, COD visibility, and delivery fees from one admin-only control surface.',
                style: TextStyle(color: AdminTheme.textSecondary, height: 1.45),
              ),
            ],
          );
          final metrics = [
            _metricTile('Methods', '${_paymentMethods.length}', Icons.payments),
            _metricTile('Enabled', '$enabledCount', Icons.verified_outlined),
            _metricTile(
              'Inside Dhaka',
              '?${_insideDhakaCtrl.text}',
              Icons.location_city,
            ),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                _metricsGrid(metrics, constraints.maxWidth),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 18),
              ...metrics.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: SizedBox(width: 150, child: e),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricTile(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _brandOrange, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AdminTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryChargeCard() {
    return _modernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.local_shipping,
            title: 'COD Delivery Charges',
            subtitle:
                'Customer-facing delivery fee for cash-on-delivery orders.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final fields = [
                _chargeField(
                  label: 'Inside Dhaka',
                  controller: _insideDhakaCtrl,
                  icon: Icons.location_city,
                  hint: '60',
                ),
                _chargeField(
                  label: 'Outside Dhaka',
                  controller: _outsideDhakaCtrl,
                  icon: Icons.map_outlined,
                  hint: '120',
                ),
              ];
              final save = ElevatedButton.icon(
                onPressed: _savingCharges ? null : _saveDeliveryCharges,
                icon: _savingCharges
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Charges'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandOrange,
                  foregroundColor: const Color.fromARGB(255, 228, 220, 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...fields.map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: field,
                      ),
                    ),
                    save,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 14),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 14),
                  save,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chargeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AdminTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AdminTheme.textPrimary),
          decoration: _fieldDecoration(hint: hint, icon: icon, prefix: '?'),
        ),
      ],
    );
  }

  Widget _methodsHeader(int enabledCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final title = _cardTitle(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Payment Methods',
          subtitle: '$enabledCount enabled of ${_paymentMethods.length} total',
        );
        final refresh = TextButton.icon(
          onPressed: _loadPaymentMethods,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: refresh),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            refresh,
          ],
        );
      },
    );
  }

  Widget _methodCard(Map<String, dynamic> method) {
    final isEnabled = _isMethodEnabled(method['is_enabled']);
    final account = method['account_number']?.toString() ?? '';
    final leading = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isEnabled ? _brandOrange : _fieldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getMethodIcon(method['method_type']),
        color: isEnabled ? _brandOrange : Color(0x42000000),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          method['method_name']?.toString() ?? 'Unknown',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AdminTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _pill(_formatMethodType(method['method_type'])),
            if (account.isNotEmpty) _pill(account),
            _pill(
              isEnabled ? 'Enabled' : 'Disabled',
              color: isEnabled ? Colors.greenAccent : Colors.redAccent,
            ),
          ],
        ),
      ],
    );
    final toggle = Switch(
      value: isEnabled,
      onChanged: (value) => _toggleStatus(_methodId(method), value),
      activeColor: _brandOrange,
    );
    final actions = Wrap(
      spacing: 2,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          onPressed: () => _showAddEditDialog(method: method),
          icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
          tooltip: 'Edit',
        ),
        IconButton(
          onPressed: () =>
              _deleteMethod(_methodId(method), method['method_name']),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Delete',
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isEnabled ? _brandOrange : AdminTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          if (compact) {
            return Column(
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [toggle, actions],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(child: details),
              toggle,
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return _modernCard(
      child: Column(
        children: [
          const Icon(Icons.payment, color: Color(0x42000000), size: 54),
          const SizedBox(height: 12),
          const Text(
            'No payment methods found',
            style: TextStyle(
              color: AdminTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.border),
      ),
      child: child,
    );
  }

  Widget _cardTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _brandOrange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AdminTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, {Color color = AdminTheme.textSecondary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final message = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: AdminTheme.textMuted),
                ),
              ),
            ],
          );
          final retry = TextButton(
            onPressed: _loadPaymentMethods,
            child: const Text('Retry'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                message,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: retry),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: message),
              retry,
            ],
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      hintStyle: const TextStyle(color: AdminTheme.textSecondary),
      prefixIcon: Icon(icon, color: AdminTheme.textSecondary, size: 18),
      filled: true,
      fillColor: _fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _brandOrange),
      ),
    );
  }

  IconData _getMethodIcon(String? type) {
    switch (type) {
      case 'mobile_banking':
        return Icons.phone_android;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _formatMethodType(String? type) {
    switch (type) {
      case 'mobile_banking':
        return 'Mobile Banking';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card Payment';
      default:
        return type ?? 'Unknown';
    }
  }
}
