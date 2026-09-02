import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/api_service.dart';
import 'A_customers.dart';
import 'Admin_sidebar.dart';
import 'admin_scaffold.dart';
import 'admin_theme.dart';

class AdminDeliverySettingsPage extends StatefulWidget {
  final bool embedded;

  const AdminDeliverySettingsPage({super.key, this.embedded = false});

  @override
  State<AdminDeliverySettingsPage> createState() =>
      _AdminDeliverySettingsPageState();
}

class _AdminDeliverySettingsPageState extends State<AdminDeliverySettingsPage> {
  static const _deliverySettingKey = 'delivery_provider_settings';
  static const _bkashSettingKey = 'bkash_merchant_settings';
  static const _brandOrange = Color(0xFF7C3AED);
  static const _cardBg = AdminTheme.surfaceAlt;
  static const _fieldBg = AdminTheme.surfaceAlt;

  bool _loading = true;
  bool _saving = false;
  List<_DeliveryProviderConfig> _providers = _defaultProviders();
  _BkashMerchantSettings _bkash = const _BkashMerchantSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final delivery = await ApiService.getSiteSetting(_deliverySettingKey);
      final deliveryRaw = _settingValue(delivery);
      if (deliveryRaw != null && deliveryRaw.isNotEmpty) {
        final decoded = jsonDecode(deliveryRaw);
        if (decoded is Map && decoded['providers'] is List) {
          _providers = (decoded['providers'] as List)
              .whereType<Map>()
              .map((e) => _DeliveryProviderConfig.fromJson(e))
              .toList();
        }
      }
    } catch (_) {
      _providers = _defaultProviders();
    }

    try {
      final bkash = await ApiService.getSiteSetting(_bkashSettingKey);
      final bkashRaw = _settingValue(bkash);
      if (bkashRaw != null && bkashRaw.isNotEmpty) {
        final decoded = jsonDecode(bkashRaw);
        if (decoded is Map) {
          _bkash = _BkashMerchantSettings.fromJson(decoded);
        }
      }
    } catch (_) {
      _bkash = const _BkashMerchantSettings();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await ApiService.saveSiteSetting({
        'setting_key': _deliverySettingKey,
        'setting_value': jsonEncode({
          'updatedAt': DateTime.now().toIso8601String(),
          'providers': _providers.map((e) => e.toJson()).toList(),
        }),
      });
      await ApiService.saveSiteSetting({
        'setting_key': _bkashSettingKey,
        'setting_value': jsonEncode(_bkash.toJson()),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery and merchant settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String? _settingValue(Map<String, dynamic> response) {
    final data = response['data'];
    final value =
        response['setting_value'] ??
        response['value'] ??
        (data is Map ? data['setting_value'] ?? data['value'] : null);
    return value?.toString();
  }

  void _navigate(BuildContext context, AdminSidebarItem item) {
    if (item == AdminSidebarItem.deliverySettings) return;
    AdminNav.go(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadSettings,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _introCard(),
                      const SizedBox(height: 18),
                      _sectionTitle(
                        icon: Icons.local_shipping_outlined,
                        title: 'Delivery Providers',
                        subtitle:
                            'Enable providers and keep delivery modes, COD fees, and API credentials ready.',
                      ),
                      const SizedBox(height: 12),
                      ..._providers.map(_providerCard),
                      const SizedBox(height: 18),
                      _bkashCard(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          );

    if (widget.embedded) {
      return Material(
        color: AdminTheme.bg,
        child: SizedBox.expand(child: content),
      );
    }

    return AdminScaffold(
      selected: AdminSidebarItem.deliverySettings,
      onItemSelected: (item) => _navigate(context, item),
      body: content,
    );
  }

  Widget _topBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final saveButton = ElevatedButton.icon(
          onPressed: _saving ? null : _saveSettings,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.save, size: 18),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandOrange,
            foregroundColor: Colors.black,
          ),
        );
        return Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            border: Border(bottom: BorderSide(color: Color(0x0D000000))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Management / Delivery & Merchant',
                      style: TextStyle(color: Color(0x73000000), fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: saveButton),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Management / Delivery & Merchant',
                        style: TextStyle(
                          color: Color(0x73000000),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    saveButton,
                  ],
                ),
        );
      },
    );
  }

  Widget _introCard() {
    final enabledProviders = _providers
        .where((provider) => provider.enabled)
        .length;
    final apiReady = _providers.where((provider) => provider.isApiReady).length;
    final bkashReady =
        _bkash.merchantNumber.isNotEmpty || _bkash.merchantCode.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AdminTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0x0D000000)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery & Merchant Hub',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Keep courier modes, API credentials, COD handling, and bKash merchant codes ready for admin-only delivery operations.',
                style: TextStyle(color: Colors.white60, height: 1.45),
              ),
            ],
          );
          final metrics = [
            _metricTile(
              'Enabled',
              '$enabledProviders',
              Icons.toggle_on_outlined,
            ),
            _metricTile('API ready', '$apiReady', Icons.cloud_done_outlined),
            _metricTile(
              'bKash',
              bkashReady ? 'Ready' : 'Not set',
              Icons.account_balance_wallet_outlined,
            ),
          ];
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                ...metrics.map(
                  (metric) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: metric,
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 18),
              ...metrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: SizedBox(width: 150, child: metric),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0x0D000000)),
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

  Widget _sectionTitle({
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
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AdminTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _providerCard(_DeliveryProviderConfig provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: provider.enabled
              ? _brandOrange.withOpacity(0.45)
              : Color(0x0D000000),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final icon = Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: provider.enabled
                  ? _brandOrange.withOpacity(0.16)
                  : Color(0x0D000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              provider.isApiReady ? Icons.cloud_done : Icons.local_shipping,
              color: provider.enabled ? _brandOrange : Color(0x42000000),
            ),
          );
          final title = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  provider.apiMode == 'live'
                      ? 'Live mode'
                      : provider.apiMode == 'sandbox'
                      ? 'Sandbox mode'
                      : 'Manual booking',
                  style: const TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          );
          final controls = Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Switch(
                value: provider.enabled,
                activeColor: _brandOrange,
                onChanged: (value) {
                  setState(() {
                    _providers = _providers
                        .map(
                          (e) => e.id == provider.id
                              ? e.copyWith(enabled: value)
                              : e,
                        )
                        .toList();
                  });
                },
              ),
              IconButton(
                onPressed: () => _showProviderDialog(provider),
                icon: const Icon(Icons.edit, color: Color(0x8A000000)),
                tooltip: 'Edit provider',
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                Row(children: [icon, const SizedBox(width: 12), title]),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: controls),
              ] else
                Row(
                  children: [icon, const SizedBox(width: 12), title, controls],
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.serviceModes
                    .map(
                      (mode) => Chip(
                        label: Text(mode),
                        backgroundColor: _fieldBg,
                        labelStyle: const TextStyle(
                          color: AdminTheme.textMuted,
                        ),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryPill(
                    'Base',
                    provider.baseCharge.isEmpty
                        ? ''
                        : 'BDT ${provider.baseCharge}',
                  ),
                  _summaryPill(
                    'COD',
                    provider.codCharge.isEmpty
                        ? ''
                        : 'BDT ${provider.codCharge}',
                  ),
                  _summaryPill('Merchant/Store', provider.merchantId),
                ],
              ),
              if (provider.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  provider.notes,
                  style: const TextStyle(color: AdminTheme.textSecondary),
                  softWrap: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _bkashCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0x0D000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              final title = const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _brandOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'bKash Merchant Settings',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
              final update = TextButton.icon(
                onPressed: _showBkashDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Update'),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: update),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  update,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryPill('Merchant no.', _bkash.merchantNumber),
              _summaryPill('Merchant code', _bkash.merchantCode),
              _summaryPill('App key', _bkash.appKey),
              _summaryPill('Mode', _bkash.sandbox ? 'Sandbox' : 'Live'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.isEmpty ? 'not set' : value}',
        style: const TextStyle(color: AdminTheme.textMuted, fontSize: 12),
      ),
    );
  }

  Future<void> _showProviderDialog(_DeliveryProviderConfig provider) async {
    final name = TextEditingController(text: provider.name);
    final baseCharge = TextEditingController(text: provider.baseCharge);
    final codCharge = TextEditingController(text: provider.codCharge);
    final merchantId = TextEditingController(text: provider.merchantId);
    final apiKey = TextEditingController(text: provider.apiKey);
    final apiSecret = TextEditingController(text: provider.apiSecret);
    final notes = TextEditingController(text: provider.notes);
    var enabled = provider.enabled;
    var apiMode = provider.apiMode;
    final selectedModes = provider.serviceModes.toSet();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${provider.name}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Enabled in admin delivery flow'),
                    value: enabled,
                    onChanged: (value) => setDialogState(() => enabled = value),
                  ),
                  _dialogField(name, 'Provider name'),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 420) {
                        return Column(
                          children: [
                            _dialogField(baseCharge, 'Base charge'),
                            _dialogField(codCharge, 'COD fee'),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _dialogField(baseCharge, 'Base charge'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _dialogField(codCharge, 'COD fee')),
                        ],
                      );
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: apiMode,
                    decoration: const InputDecoration(
                      labelText: 'Booking mode',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'manual', child: Text('Manual')),
                      DropdownMenuItem(
                        value: 'sandbox',
                        child: Text('Sandbox API'),
                      ),
                      DropdownMenuItem(value: 'live', child: Text('Live API')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => apiMode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Service modes',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _serviceModes.map((mode) {
                      final selected = selectedModes.contains(mode);
                      return FilterChip(
                        label: Text(mode),
                        selected: selected,
                        onSelected: (value) {
                          setDialogState(() {
                            if (value) {
                              selectedModes.add(mode);
                            } else {
                              selectedModes.remove(mode);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(merchantId, 'Merchant / store ID'),
                  _dialogField(apiKey, 'API key / client ID'),
                  _dialogField(apiSecret, 'API secret / client secret'),
                  _dialogField(notes, 'Notes', minLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updated = provider.copyWith(
                  name: name.text.trim(),
                  enabled: enabled,
                  serviceModes: selectedModes.toList(),
                  baseCharge: baseCharge.text.trim(),
                  codCharge: codCharge.text.trim(),
                  apiMode: apiMode,
                  merchantId: merchantId.text.trim(),
                  apiKey: apiKey.text.trim(),
                  apiSecret: apiSecret.text.trim(),
                  notes: notes.text.trim(),
                );
                setState(() {
                  _providers = _providers
                      .map((e) => e.id == provider.id ? updated : e)
                      .toList();
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    baseCharge.dispose();
    codCharge.dispose();
    merchantId.dispose();
    apiKey.dispose();
    apiSecret.dispose();
    notes.dispose();
  }

  Future<void> _showBkashDialog() async {
    final merchantNumber = TextEditingController(text: _bkash.merchantNumber);
    final merchantCode = TextEditingController(text: _bkash.merchantCode);
    final appKey = TextEditingController(text: _bkash.appKey);
    final appSecret = TextEditingController(text: _bkash.appSecret);
    final username = TextEditingController(text: _bkash.username);
    final password = TextEditingController(text: _bkash.password);
    final callbackUrl = TextEditingController(text: _bkash.callbackUrl);
    var sandbox = _bkash.sandbox;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('bKash Merchant Settings'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Sandbox mode'),
                    value: sandbox,
                    onChanged: (value) => setDialogState(() => sandbox = value),
                  ),
                  _dialogField(merchantNumber, 'Merchant number'),
                  _dialogField(merchantCode, 'Merchant code'),
                  _dialogField(appKey, 'App key'),
                  _dialogField(appSecret, 'App secret'),
                  _dialogField(username, 'Username'),
                  _dialogField(password, 'Password'),
                  _dialogField(callbackUrl, 'Callback URL'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _bkash = _BkashMerchantSettings(
                    sandbox: sandbox,
                    merchantNumber: merchantNumber.text.trim(),
                    merchantCode: merchantCode.text.trim(),
                    appKey: appKey.text.trim(),
                    appSecret: appSecret.text.trim(),
                    username: username.text.trim(),
                    password: password.text.trim(),
                    callbackUrl: callbackUrl.text.trim(),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    merchantNumber.dispose();
    merchantCode.dispose();
    appKey.dispose();
    appSecret.dispose();
    username.dispose();
    password.dispose();
    callbackUrl.dispose();
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int minLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 5,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

const _serviceModes = [
  'Home delivery',
  'Pickup point',
  'Inside Dhaka',
  'Outside Dhaka',
  'Same day',
  'Express',
  'Standard',
  'Cash on delivery',
  'Fragile parcel',
];

List<_DeliveryProviderConfig> _defaultProviders() {
  return const [
    _DeliveryProviderConfig(
      id: 'pathao',
      name: 'Pathao Courier',
      serviceModes: [
        'Home delivery',
        'Inside Dhaka',
        'Outside Dhaka',
        'Cash on delivery',
      ],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'redx',
      name: 'REDX',
      serviceModes: ['Home delivery', 'Outside Dhaka', 'Cash on delivery'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'steadfast',
      name: 'Steadfast Courier',
      serviceModes: ['Home delivery', 'Outside Dhaka', 'Cash on delivery'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'paperfly',
      name: 'Paperfly',
      serviceModes: ['Home delivery', 'Pickup point', 'Cash on delivery'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'ecourier',
      name: 'eCourier',
      serviceModes: ['Home delivery', 'Same day', 'Express'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'sundarban',
      name: 'Sundarban Courier',
      serviceModes: ['Pickup point', 'Outside Dhaka', 'Standard'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'sa_paribahan',
      name: 'SA Paribahan',
      serviceModes: ['Pickup point', 'Outside Dhaka', 'Standard'],
      apiMode: 'manual',
    ),
    _DeliveryProviderConfig(
      id: 'in_house',
      name: 'In-house Rider',
      serviceModes: ['Home delivery', 'Inside Dhaka', 'Cash on delivery'],
      apiMode: 'manual',
    ),
  ];
}

class _DeliveryProviderConfig {
  final String id;
  final String name;
  final bool enabled;
  final List<String> serviceModes;
  final String baseCharge;
  final String codCharge;
  final String apiMode;
  final String merchantId;
  final String apiKey;
  final String apiSecret;
  final String notes;

  const _DeliveryProviderConfig({
    required this.id,
    required this.name,
    this.enabled = false,
    this.serviceModes = const [],
    this.baseCharge = '',
    this.codCharge = '',
    this.apiMode = 'manual',
    this.merchantId = '',
    this.apiKey = '',
    this.apiSecret = '',
    this.notes = '',
  });

  bool get isApiReady =>
      apiMode != 'manual' && merchantId.isNotEmpty && apiKey.isNotEmpty;

  factory _DeliveryProviderConfig.fromJson(Map json) {
    return _DeliveryProviderConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Delivery Provider',
      enabled: json['enabled'] == true,
      serviceModes:
          (json['serviceModes'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      baseCharge: json['baseCharge']?.toString() ?? '',
      codCharge: json['codCharge']?.toString() ?? '',
      apiMode: json['apiMode']?.toString() ?? 'manual',
      merchantId: json['merchantId']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      apiSecret: json['apiSecret']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'serviceModes': serviceModes,
      'baseCharge': baseCharge,
      'codCharge': codCharge,
      'apiMode': apiMode,
      'merchantId': merchantId,
      'apiKey': apiKey,
      'apiSecret': apiSecret,
      'notes': notes,
    };
  }

  _DeliveryProviderConfig copyWith({
    String? name,
    bool? enabled,
    List<String>? serviceModes,
    String? baseCharge,
    String? codCharge,
    String? apiMode,
    String? merchantId,
    String? apiKey,
    String? apiSecret,
    String? notes,
  }) {
    return _DeliveryProviderConfig(
      id: id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      serviceModes: serviceModes ?? this.serviceModes,
      baseCharge: baseCharge ?? this.baseCharge,
      codCharge: codCharge ?? this.codCharge,
      apiMode: apiMode ?? this.apiMode,
      merchantId: merchantId ?? this.merchantId,
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      notes: notes ?? this.notes,
    );
  }
}

class _BkashMerchantSettings {
  final bool sandbox;
  final String merchantNumber;
  final String merchantCode;
  final String appKey;
  final String appSecret;
  final String username;
  final String password;
  final String callbackUrl;

  const _BkashMerchantSettings({
    this.sandbox = true,
    this.merchantNumber = '',
    this.merchantCode = '',
    this.appKey = '',
    this.appSecret = '',
    this.username = '',
    this.password = '',
    this.callbackUrl = '',
  });

  factory _BkashMerchantSettings.fromJson(Map json) {
    return _BkashMerchantSettings(
      sandbox: json['sandbox'] != false,
      merchantNumber: json['merchantNumber']?.toString() ?? '',
      merchantCode: json['merchantCode']?.toString() ?? '',
      appKey: json['appKey']?.toString() ?? '',
      appSecret: json['appSecret']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      callbackUrl: json['callbackUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sandbox': sandbox,
      'merchantNumber': merchantNumber,
      'merchantCode': merchantCode,
      'appKey': appKey,
      'appSecret': appSecret,
      'username': username,
      'password': password,
      'callbackUrl': callbackUrl,
    };
  }
}

