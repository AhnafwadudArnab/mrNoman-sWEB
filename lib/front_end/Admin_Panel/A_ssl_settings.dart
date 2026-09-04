import 'package:flutter/material.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminSslSettingsPage extends StatefulWidget {
  final bool embedded;
  const AdminSslSettingsPage({super.key, this.embedded = false});

  @override
  State<AdminSslSettingsPage> createState() => _AdminSslSettingsPageState();
}

class _AdminSslSettingsPageState extends State<AdminSslSettingsPage> {
  static const Color _cardBg = AdminTheme.surfaceAlt;
  static const Color _brandOrange = Color(0xFF7C3AED);
  static const Color _panelBg = AdminTheme.bg;
  static const Color _fieldBg = AdminTheme.surfaceAlt;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  // -- General Settings --
  final _storeTitleCtrl = TextEditingController();
  final _timerMinutesCtrl = TextEditingController();
  final _convenienceChargeCtrl = TextEditingController();
  final _termsTextCtrl = TextEditingController();
  final _offersTextCtrl = TextEditingController();
  final _noOffersTextCtrl = TextEditingController();

  // -- Tab visibility --
  bool _tabCardEnabled = true;
  bool _tabMobileBankingEnabled = true;
  bool _tabNetBankingEnabled = true;
  bool _tabMoreEnabled = true;

  // -- Tab labels --
  final _tabCardLabelCtrl = TextEditingController();
  final _tabMobileLabelCtrl = TextEditingController();
  final _tabNetBankingLabelCtrl = TextEditingController();
  final _tabMoreLabelCtrl = TextEditingController();

  // -- Coming soon texts --
  final _cardComingSoonCtrl = TextEditingController();
  final _netBankingComingSoonCtrl = TextEditingController();
  final _moreComingSoonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeTitleCtrl.dispose();
    _timerMinutesCtrl.dispose();
    _convenienceChargeCtrl.dispose();
    _termsTextCtrl.dispose();
    _offersTextCtrl.dispose();
    _noOffersTextCtrl.dispose();
    _tabCardLabelCtrl.dispose();
    _tabMobileLabelCtrl.dispose();
    _tabNetBankingLabelCtrl.dispose();
    _tabMoreLabelCtrl.dispose();
    _cardComingSoonCtrl.dispose();
    _netBankingComingSoonCtrl.dispose();
    _moreComingSoonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final keys = [
        'ssl_store_title',
        'ssl_timer_minutes',
        'ssl_convenience_charge',
        'ssl_terms_text',
        'ssl_offers_title',
        'ssl_no_offers_text',
        'ssl_tab_card_enabled',
        'ssl_tab_mobile_enabled',
        'ssl_tab_netbanking_enabled',
        'ssl_tab_more_enabled',
        'ssl_tab_card_label',
        'ssl_tab_mobile_label',
        'ssl_tab_netbanking_label',
        'ssl_tab_more_label',
        'ssl_card_coming_soon',
        'ssl_netbanking_coming_soon',
        'ssl_more_coming_soon',
      ];

      final Map<String, String> vals = {};
      for (final k in keys) {
        try {
          final res = await ApiService.getSiteSetting(k);
          vals[k] = res['setting_value']?.toString() ?? '';
        } catch (_) {
          vals[k] = '';
        }
      }

      if (!mounted) return;
      setState(() {
        _storeTitleCtrl.text = vals['ssl_store_title']!.isNotEmpty
            ? vals['ssl_store_title']!
            : 'ElectroZoneBD';
        _timerMinutesCtrl.text = vals['ssl_timer_minutes']!.isNotEmpty
            ? vals['ssl_timer_minutes']!
            : '5';
        _convenienceChargeCtrl.text = vals['ssl_convenience_charge']!.isNotEmpty
            ? vals['ssl_convenience_charge']!
            : '0';
        _termsTextCtrl.text = vals['ssl_terms_text']!.isNotEmpty
            ? vals['ssl_terms_text']!
            : 'By clicking the "Pay" button you agree to our Terms of Service which is limited to facilitating your payment to ElectroZoneBD.';
        _offersTextCtrl.text = vals['ssl_offers_title']!.isNotEmpty
            ? vals['ssl_offers_title']!
            : 'Special Offers and Savings';
        _noOffersTextCtrl.text = vals['ssl_no_offers_text']!.isNotEmpty
            ? vals['ssl_no_offers_text']!
            : 'No offers available for this transaction';
        _tabCardEnabled = vals['ssl_tab_card_enabled'] != '0';
        _tabMobileBankingEnabled = vals['ssl_tab_mobile_enabled'] != '0';
        _tabNetBankingEnabled = vals['ssl_tab_netbanking_enabled'] != '0';
        _tabMoreEnabled = vals['ssl_tab_more_enabled'] != '0';
        _tabCardLabelCtrl.text = vals['ssl_tab_card_label']!.isNotEmpty
            ? vals['ssl_tab_card_label']!
            : 'Card';
        _tabMobileLabelCtrl.text = vals['ssl_tab_mobile_label']!.isNotEmpty
            ? vals['ssl_tab_mobile_label']!
            : 'Mobile Ban...';
        _tabNetBankingLabelCtrl.text =
            vals['ssl_tab_netbanking_label']!.isNotEmpty
            ? vals['ssl_tab_netbanking_label']!
            : 'Net Banking';
        _tabMoreLabelCtrl.text = vals['ssl_tab_more_label']!.isNotEmpty
            ? vals['ssl_tab_more_label']!
            : 'More';
        _cardComingSoonCtrl.text = vals['ssl_card_coming_soon']!.isNotEmpty
            ? vals['ssl_card_coming_soon']!
            : 'Card payment coming soon';
        _netBankingComingSoonCtrl.text =
            vals['ssl_netbanking_coming_soon']!.isNotEmpty
            ? vals['ssl_netbanking_coming_soon']!
            : 'Net Banking coming soon';
        _moreComingSoonCtrl.text = vals['ssl_more_coming_soon']!.isNotEmpty
            ? vals['ssl_more_coming_soon']!
            : 'More options coming soon';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final entries = {
        'ssl_store_title': _storeTitleCtrl.text.trim(),
        'ssl_timer_minutes': _timerMinutesCtrl.text.trim(),
        'ssl_convenience_charge': _convenienceChargeCtrl.text.trim(),
        'ssl_terms_text': _termsTextCtrl.text.trim(),
        'ssl_offers_title': _offersTextCtrl.text.trim(),
        'ssl_no_offers_text': _noOffersTextCtrl.text.trim(),
        'ssl_tab_card_enabled': _tabCardEnabled ? '1' : '0',
        'ssl_tab_mobile_enabled': _tabMobileBankingEnabled ? '1' : '0',
        'ssl_tab_netbanking_enabled': _tabNetBankingEnabled ? '1' : '0',
        'ssl_tab_more_enabled': _tabMoreEnabled ? '1' : '0',
        'ssl_tab_card_label': _tabCardLabelCtrl.text.trim(),
        'ssl_tab_mobile_label': _tabMobileLabelCtrl.text.trim(),
        'ssl_tab_netbanking_label': _tabNetBankingLabelCtrl.text.trim(),
        'ssl_tab_more_label': _tabMoreLabelCtrl.text.trim(),
        'ssl_card_coming_soon': _cardComingSoonCtrl.text.trim(),
        'ssl_netbanking_coming_soon': _netBankingComingSoonCtrl.text.trim(),
        'ssl_more_coming_soon': _moreComingSoonCtrl.text.trim(),
      };

      for (final e in entries.entries) {
        await ApiService.saveSiteSetting({
          'setting_key': e.key,
          'setting_value': e.value,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SSL Commerz settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: _brandOrange),
      );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(),

        if (_error != null) _errorBanner(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCard(),
                const SizedBox(height: 20),
                // -- General --
                _sectionCard(
                  icon: Icons.tune,
                  title: 'General Settings',
                  subtitle: 'Store name, timer, convenience charge',
                  children: [
                    _row([
                      _field(
                        'Store Title',
                        _storeTitleCtrl,
                        hint: 'ElectroZoneBD',
                        icon: Icons.store_outlined,
                      ),
                      _field(
                        'Session Timer (minutes)',
                        _timerMinutesCtrl,
                        hint: '5',
                        icon: Icons.timer_outlined,
                        isNumber: true,
                      ),
                      _field(
                        'Convenience Charge (?)',
                        _convenienceChargeCtrl,
                        hint: '0',
                        icon: Icons.attach_money,
                        isNumber: true,
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 20),

                // -- Tabs --
                _sectionCard(
                  icon: Icons.tab_outlined,
                  title: 'Payment Tabs',
                  subtitle: 'Enable/disable tabs and customize labels',
                  children: [
                    _tabRow(
                      label: 'Card Tab',
                      enabled: _tabCardEnabled,
                      onToggle: (v) => setState(() => _tabCardEnabled = v),
                      labelCtrl: _tabCardLabelCtrl,
                    ),
                    const SizedBox(height: 12),
                    _tabRow(
                      label: 'Mobile Banking Tab',
                      enabled: _tabMobileBankingEnabled,
                      onToggle: (v) =>
                          setState(() => _tabMobileBankingEnabled = v),
                      labelCtrl: _tabMobileLabelCtrl,
                    ),
                    const SizedBox(height: 12),
                    _tabRow(
                      label: 'Net Banking Tab',
                      enabled: _tabNetBankingEnabled,
                      onToggle: (v) =>
                          setState(() => _tabNetBankingEnabled = v),
                      labelCtrl: _tabNetBankingLabelCtrl,
                    ),
                    const SizedBox(height: 12),
                    _tabRow(
                      label: 'More Tab',
                      enabled: _tabMoreEnabled,
                      onToggle: (v) => setState(() => _tabMoreEnabled = v),
                      labelCtrl: _tabMoreLabelCtrl,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // -- Coming Soon Texts --
                _sectionCard(
                  icon: Icons.hourglass_empty_outlined,
                  title: '"Coming Soon" Messages',
                  subtitle: 'Text shown when a tab has no content yet',
                  children: [
                    // List layout for coming soon messages
                    _field(
                      'Card Tab Message',
                      _cardComingSoonCtrl,
                      hint: 'Card payment coming soon',
                      icon: Icons.credit_card_outlined,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Net Banking Message',
                      _netBankingComingSoonCtrl,
                      hint: 'Net Banking coming soon',
                      icon: Icons.account_balance_outlined,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'More Tab Message',
                      _moreComingSoonCtrl,
                      hint: 'More options coming soon',
                      icon: Icons.grid_view_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // -- Offers & Terms --
                _sectionCard(
                  icon: Icons.local_offer_outlined,
                  title: 'Offers & Terms Text',
                  subtitle:
                      'Customize offers section and terms of service text',
                  children: [
                    // List layout for offers
                    _field(
                      'Offers Section Title',
                      _offersTextCtrl,
                      hint: 'Special Offers and Savings',
                      icon: Icons.card_giftcard_outlined,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'No Offers Message',
                      _noOffersTextCtrl,
                      hint: 'No offers available for this transaction',
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Terms of Service Text',
                      _termsTextCtrl,
                      hint: 'By clicking the "Pay" button...',
                      icon: Icons.gavel_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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
    return Scaffold(backgroundColor: AdminTheme.bg, body: content);
  }

  Widget _topBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Management / SSL Commerz Settings',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _saving ? null : _saveAll,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.save),
            label: const Text('Save All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    final enabledTabs = [
      _tabCardEnabled,
      _tabMobileBankingEnabled,
      _tabNetBankingEnabled,
      _tabMoreEnabled,
    ].where((enabled) => enabled).length;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SSL Checkout Experience',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tune payment tabs, timeout behavior, offer text, and terms copy for the hosted checkout screen.',
                style: TextStyle(color: AdminTheme.textSecondary, height: 1.45),
              ),
            ],
          );
          final metrics = [
            _metricTile('Enabled tabs', '$enabledTabs / 4', Icons.tab_outlined),
            _metricTile(
              'Timer',
              '${_timerMinutesCtrl.text} min',
              Icons.timer_outlined,
            ),
            _metricTile(
              'Charge',
              '?${_convenienceChargeCtrl.text}',
              Icons.payments_outlined,
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

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AdminTheme.textMuted),
            ),
          ),
          TextButton(onPressed: _loadSettings, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandOrange, width: 2),
        boxShadow: [
          BoxShadow(
            color: _brandOrange,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _brandOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: _brandOrange, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: c,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: children
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    IconData? icon,
    bool isNumber = false,
    int maxLines = 1,
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
          controller: ctrl,
          keyboardType: isNumber
              ? TextInputType.number
              : TextInputType.multiline,
          maxLines: maxLines,
          style: const TextStyle(color: AdminTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AdminTheme.textMuted),
            prefixIcon: icon != null
                ? Icon(icon, color: Color(0x42000000), size: 18)
                : null,
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
          ),
        ),
      ],
    );
  }

  Widget _gridField(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    IconData? icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandOrange, width: 1),
        boxShadow: [
          BoxShadow(
            color: _brandOrange,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _brandOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brandOrange),
              ),
              child: Icon(icon, color: _brandOrange, size: 20),
            ),
          if (icon != null) const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AdminTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: isNumber
                ? TextInputType.number
                : TextInputType.multiline,
            maxLines: maxLines,
            style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AdminTheme.textMuted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: _fieldBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _brandOrange),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _brandOrange, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabRow({
    required String label,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController labelCtrl,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    activeColor: _brandOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: enabled
                            ? AdminTheme.textPrimary
                            : AdminTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: labelCtrl,
                enabled: enabled,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Tab label',
                  hintStyle: const TextStyle(color: AdminTheme.textMuted),
                  filled: true,
                  fillColor: enabled
                      ? _fieldBg
                      : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _brandOrange),
                  ),
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: _brandOrange,
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? AdminTheme.textPrimary
                      : AdminTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: TextField(
                controller: labelCtrl,
                enabled: enabled,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Tab label',
                  hintStyle: const TextStyle(color: AdminTheme.textMuted),
                  filled: true,
                  fillColor: enabled
                      ? _fieldBg
                      : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _brandOrange),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}









