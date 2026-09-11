import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:electrocitybd1/front_end/utils/api_service.dart';
import 'package:electrocitybd1/front_end/Admin_Panel/admin_theme.dart';

class AdminSslSettingsPage extends StatefulWidget {
  final bool embedded;
  const AdminSslSettingsPage({super.key, this.embedded = false});

  @override
  State<AdminSslSettingsPage> createState() => _AdminSslSettingsPageState();
}

class _AdminSslSettingsPageState extends State<AdminSslSettingsPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _obscurePasswd = true;

  // -- Gateway Credentials & Environment --
  final _storeIdCtrl = TextEditingController();
  final _storePasswdCtrl = TextEditingController();
  bool _isSandbox = true;

  // -- General Parameters --
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

  // Preview state
  int _previewActiveTab = 1; // 0: Card, 1: Mobile Banking, 2: Net Banking, 3: More

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeIdCtrl.dispose();
    _storePasswdCtrl.dispose();
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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final keys = [
        'ssl_store_id',
        'ssl_store_passwd',
        'ssl_sandbox_mode',
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
        if (!mounted) return;
        try {
          final res = await ApiService.getSiteSetting(k);
          vals[k] = res['setting_value']?.toString() ?? '';
        } catch (_) {
          vals[k] = '';
        }
      }

      if (!mounted) return;
      setState(() {
        _storeIdCtrl.text = vals['ssl_store_id']?.isNotEmpty == true
            ? vals['ssl_store_id']!
            : 'electrozonebd_live';
        _storePasswdCtrl.text = vals['ssl_store_passwd']?.isNotEmpty == true
            ? vals['ssl_store_passwd']!
            : '';
        _isSandbox = vals['ssl_sandbox_mode'] != '0';

        _storeTitleCtrl.text = vals['ssl_store_title']?.isNotEmpty == true
            ? vals['ssl_store_title']!
            : 'ElectroZoneBD';
        _timerMinutesCtrl.text = vals['ssl_timer_minutes']?.isNotEmpty == true
            ? vals['ssl_timer_minutes']!
            : '5';
        _convenienceChargeCtrl.text =
            vals['ssl_convenience_charge']?.isNotEmpty == true
                ? vals['ssl_convenience_charge']!
                : '0';
        _termsTextCtrl.text = vals['ssl_terms_text']?.isNotEmpty == true
            ? vals['ssl_terms_text']!
            : 'By clicking Pay, you agree to our Terms of Service facilitating your payment to ElectroZoneBD.';
        _offersTextCtrl.text = vals['ssl_offers_title']?.isNotEmpty == true
            ? vals['ssl_offers_title']!
            : 'Special Offers and Savings';
        _noOffersTextCtrl.text = vals['ssl_no_offers_text']?.isNotEmpty == true
            ? vals['ssl_no_offers_text']!
            : 'No promotional offers available for this transaction';

        _tabCardEnabled = vals['ssl_tab_card_enabled'] != '0';
        _tabMobileBankingEnabled = vals['ssl_tab_mobile_enabled'] != '0';
        _tabNetBankingEnabled = vals['ssl_tab_netbanking_enabled'] != '0';
        _tabMoreEnabled = vals['ssl_tab_more_enabled'] != '0';

        _tabCardLabelCtrl.text = vals['ssl_tab_card_label']?.isNotEmpty == true
            ? vals['ssl_tab_card_label']!
            : 'Cards';
        _tabMobileLabelCtrl.text =
            vals['ssl_tab_mobile_label']?.isNotEmpty == true
                ? vals['ssl_tab_mobile_label']!
                : 'Mobile Banking';
        _tabNetBankingLabelCtrl.text =
            vals['ssl_tab_netbanking_label']?.isNotEmpty == true
                ? vals['ssl_tab_netbanking_label']!
                : 'Net Banking';
        _tabMoreLabelCtrl.text = vals['ssl_tab_more_label']?.isNotEmpty == true
            ? vals['ssl_tab_more_label']!
            : 'EMI & Other';

        _cardComingSoonCtrl.text =
            vals['ssl_card_coming_soon']?.isNotEmpty == true
                ? vals['ssl_card_coming_soon']!
                : 'Card payments are being upgraded. Please use Mobile Banking.';
        _netBankingComingSoonCtrl.text =
            vals['ssl_netbanking_coming_soon']?.isNotEmpty == true
                ? vals['ssl_netbanking_coming_soon']!
                : 'Internet banking options coming soon.';
        _moreComingSoonCtrl.text =
            vals['ssl_more_coming_soon']?.isNotEmpty == true
                ? vals['ssl_more_coming_soon']!
                : 'Additional payment methods coming soon.';

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
        'ssl_store_id': _storeIdCtrl.text.trim(),
        'ssl_store_passwd': _storePasswdCtrl.text.trim(),
        'ssl_sandbox_mode': _isSandbox ? '1' : '0',
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
          content: Text('SSLCommerz gateway settings saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        if (_error != null) _buildErrorBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 960;
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildCredentialsCard(),
                                const SizedBox(height: 20),
                                _buildGeneralParametersCard(),
                                const SizedBox(height: 20),
                                _buildPaymentTabsCard(),
                                const SizedBox(height: 20),
                                _buildPoliciesCard(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 35,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildLiveCheckoutPreviewCard(),
                                const SizedBox(height: 20),
                                _buildQuickReferenceCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // Mobile & Tablet Single Column
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLiveCheckoutPreviewCard(),
                        const SizedBox(height: 20),
                        _buildCredentialsCard(),
                        const SizedBox(height: 20),
                        _buildGeneralParametersCard(),
                        const SizedBox(height: 20),
                        _buildPaymentTabsCard(),
                        const SizedBox(height: 20),
                        _buildPoliciesCard(),
                        const SizedBox(height: 20),
                        _buildQuickReferenceCard(),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(color: AdminTheme.bg, child: SizedBox.expand(child: body));
    }
    return Scaffold(backgroundColor: AdminTheme.bg, body: body);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AdminTheme.surfaceAlt,
        border: Border(bottom: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SSLCommerz Gateway Settings',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSandbox
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSandbox
                              ? 'Sandbox Mode (Test Transactions)'
                              : 'Live Mode (Real Customer Payments)',
                          style: TextStyle(
                            color: _isSandbox
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(_saving ? 'Saving...' : 'Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadSettings,
            child: const Text('Retry', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  // 1. Credentials Card
  Widget _buildCredentialsCard() {
    return _buildAdminCard(
      title: 'Gateway Credentials & Mode',
      subtitle: 'Set your SSLCommerz Merchant credentials and test/live environment.',
      icon: Icons.vpn_key_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Environment Switcher
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AdminTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Environment Mode',
                        style: TextStyle(
                          color: AdminTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isSandbox
                            ? 'Testing mode active: no real money is deducted.'
                            : 'Live production mode active: transactions are live.',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSandbox
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _isSandbox ? 'SANDBOX' : 'LIVE',
                    style: TextStyle(
                      color: _isSandbox
                          ? const Color(0xFFB45309)
                          : const Color(0xFF047857),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Switch(
                  value: !_isSandbox,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _isSandbox = !val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Store ID & Password
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  label: 'Store ID',
                  controller: _storeIdCtrl,
                  hint: 'e.g. electrozonebdlive',
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInput(
                  label: 'Store Password / Secret Key',
                  controller: _storePasswdCtrl,
                  hint: '••••••••••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePasswd,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswd
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AdminTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePasswd = !_obscurePasswd),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // IPN Webhook URL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'IPN Webhook / Callback URL',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'https://electrozonebd.com/api/payments?action=sslcommerz_ipn',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
                  tooltip: 'Copy IPN URL',
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text:
                            'https://electrozonebd.com/api/payments?action=sslcommerz_ipn',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IPN URL copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. General Parameters Card
  Widget _buildGeneralParametersCard() {
    return _buildAdminCard(
      title: 'Checkout Session & Parameters',
      subtitle: 'Customize branding and session behavior on the hosted payment page.',
      icon: Icons.tune_rounded,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildInput(
              label: 'Merchant Display Title',
              controller: _storeTitleCtrl,
              hint: 'ElectroZoneBD',
              prefixIcon: Icons.storefront_outlined,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildInput(
              label: 'Session Timer (mins)',
              controller: _timerMinutesCtrl,
              hint: '5',
              isNumber: true,
              prefixIcon: Icons.timer_outlined,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildInput(
              label: 'Convenience Fee (৳)',
              controller: _convenienceChargeCtrl,
              hint: '0',
              isNumber: true,
              prefixIcon: Icons.attach_money_rounded,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Payment Tabs Card
  Widget _buildPaymentTabsCard() {
    return _buildAdminCard(
      title: 'Payment Tabs Configuration',
      subtitle: 'Enable or disable checkout channels, and configure fallback messages.',
      icon: Icons.tab_rounded,
      child: Column(
        children: [
          _buildTabSettingRow(
            icon: Icons.credit_card_rounded,
            title: 'Credit / Debit Cards',
            enabled: _tabCardEnabled,
            onToggle: (v) => setState(() => _tabCardEnabled = v),
            labelController: _tabCardLabelCtrl,
            comingSoonController: _cardComingSoonCtrl,
          ),
          const Divider(color: AdminTheme.border, height: 28),
          _buildTabSettingRow(
            icon: Icons.phone_android_rounded,
            title: 'Mobile Banking (bKash, Nagad, Rocket, Upay)',
            enabled: _tabMobileBankingEnabled,
            onToggle: (v) => setState(() => _tabMobileBankingEnabled = v),
            labelController: _tabMobileLabelCtrl,
          ),
          const Divider(color: AdminTheme.border, height: 28),
          _buildTabSettingRow(
            icon: Icons.account_balance_rounded,
            title: 'Internet / Net Banking',
            enabled: _tabNetBankingEnabled,
            onToggle: (v) => setState(() => _tabNetBankingEnabled = v),
            labelController: _tabNetBankingLabelCtrl,
            comingSoonController: _netBankingComingSoonCtrl,
          ),
          const Divider(color: AdminTheme.border, height: 28),
          _buildTabSettingRow(
            icon: Icons.more_horiz_rounded,
            title: 'EMI & Other Options',
            enabled: _tabMoreEnabled,
            onToggle: (v) => setState(() => _tabMoreEnabled = v),
            labelController: _tabMoreLabelCtrl,
            comingSoonController: _moreComingSoonCtrl,
          ),
        ],
      ),
    );
  }

  // 4. Policies & Offers Card
  Widget _buildPoliciesCard() {
    return _buildAdminCard(
      title: 'Offers & Customer Terms',
      subtitle: 'Copy displayed during the checkout flow and user agreements.',
      icon: Icons.policy_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  label: 'Offers Section Title',
                  controller: _offersTextCtrl,
                  hint: 'Special Offers and Savings',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInput(
                  label: 'Empty Offers Fallback Notice',
                  controller: _noOffersTextCtrl,
                  hint: 'No promotional offers available for this transaction',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInput(
            label: 'Terms of Service Disclaimer',
            controller: _termsTextCtrl,
            hint: 'By clicking Pay, you agree to our Terms...',
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  // Right Column: Live Mock Checkout Preview Card
  Widget _buildLiveCheckoutPreviewCard() {
    final title = _storeTitleCtrl.text.isNotEmpty
        ? _storeTitleCtrl.text
        : 'ElectroZoneBD';
    final timer = _timerMinutesCtrl.text.isNotEmpty
        ? _timerMinutesCtrl.text
        : '5';
    final fee = double.tryParse(_convenienceChargeCtrl.text) ?? 0.0;
    final total = 2450.0 + fee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F172A),
            child: Row(
              children: const [
                Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 16),
                SizedBox(width: 8),
                Text(
                  'Live Hosted Checkout Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Hosted Checkout Screen Mockup
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF1F5F9),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mock SSL Topbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(9),
                        topRight: Radius.circular(9),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Text(
                                'Invoice #EZB-89241',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '$timer:00',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Order Amount bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: const Color(0xFFEFF6FF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable Amount:',
                          style: TextStyle(
                            color: Color(0xFF1E40AF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '৳${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mock Tabs Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_tabCardEnabled)
                          _buildMockTabButton(
                            index: 0,
                            label: _tabCardLabelCtrl.text.isNotEmpty
                                ? _tabCardLabelCtrl.text
                                : 'Cards',
                            icon: Icons.credit_card,
                          ),
                        if (_tabMobileBankingEnabled)
                          _buildMockTabButton(
                            index: 1,
                            label: _tabMobileLabelCtrl.text.isNotEmpty
                                ? _tabMobileLabelCtrl.text
                                : 'Mobile Banking',
                            icon: Icons.phone_android,
                          ),
                        if (_tabNetBankingEnabled)
                          _buildMockTabButton(
                            index: 2,
                            label: _tabNetBankingLabelCtrl.text.isNotEmpty
                                ? _tabNetBankingLabelCtrl.text
                                : 'Net Banking',
                            icon: Icons.account_balance,
                          ),
                        if (_tabMoreEnabled)
                          _buildMockTabButton(
                            index: 3,
                            label: _tabMoreLabelCtrl.text.isNotEmpty
                                ? _tabMoreLabelCtrl.text
                                : 'More',
                            icon: Icons.more_horiz,
                          ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),

                  // Tab Content Area
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildMockTabContent(),
                  ),

                  // Terms & Disclaimer
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFFF8FAFC),
                    child: Text(
                      _termsTextCtrl.text.isNotEmpty
                          ? _termsTextCtrl.text
                          : 'By paying, you agree to the Terms of Service.',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final active = _previewActiveTab == index;
    return InkWell(
      onTap: () => setState(() => _previewActiveTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockTabContent() {
    if (_previewActiveTab == 1) {
      // Mobile Banking: show authentic bKash, Nagad, Rocket icons
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select your mobile payment service:',
            style: TextStyle(color: Color(0xFF475569), fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMockMfsIcon('bKash', const Color(0xFFE2136E)),
              _buildMockMfsIcon('Nagad', const Color(0xFFF7941D)),
              _buildMockMfsIcon('Rocket', const Color(0xFF8C3494)),
              _buildMockMfsIcon('Upay', const Color(0xFF005696)),
            ],
          ),
        ],
      );
    }

    String fallbackText = '';
    if (_previewActiveTab == 0) {
      fallbackText = _cardComingSoonCtrl.text;
    } else if (_previewActiveTab == 2) {
      fallbackText = _netBankingComingSoonCtrl.text;
    } else {
      fallbackText = _moreComingSoonCtrl.text;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 22),
          const SizedBox(height: 6),
          Text(
            fallbackText.isNotEmpty ? fallbackText : 'Service under maintenance',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMockMfsIcon(String name, Color color) {
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Center(
        child: Text(
          name,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReferenceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.help_outline_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'SSLCommerz Integration Guide',
                style: TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '• Sandbox credentials for testing:\n  Store ID: testbox\n  Passwd: qwerty\n• IPN notifications confirm successful payments instantly in real time.\n• For merchant live keys, visit merchant.sslcommerz.com',
            style: TextStyle(
              color: AdminTheme.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // Component Helpers
  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String hint = '',
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isNumber = false,
    bool obscureText = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AdminTheme.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AdminTheme.textSecondary, size: 18)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AdminTheme.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSettingRow({
    required IconData icon,
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController labelController,
    TextEditingController? comingSoonController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF475569)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: enabled,
              activeColor: const Color(0xFF10B981),
              onChanged: onToggle,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: comingSoonController != null ? 1 : 2,
              child: _buildInput(
                label: 'Display Tab Name',
                controller: labelController,
                hint: 'Tab name',
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (comingSoonController != null) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildInput(
                  label: 'Fallback / Notice Message',
                  controller: comingSoonController,
                  hint: 'Message when channel is unavailable',
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
