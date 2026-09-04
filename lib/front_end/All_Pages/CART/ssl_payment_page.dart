import 'dart:async';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/material.dart';

import 'Orders.dart' show PaymentMethod;
import '../Registrations/login.dart';
import '../../utils/payment_config.dart';
import '../../utils/api_service.dart';

/// Full-screen SSLCommerz-style payment selection page.
class SslPaymentPage extends StatefulWidget {
  final PaymentConfig config;
  final double grandTotal;
  final void Function(PaymentMethod method) onMethodSelected;

  const SslPaymentPage({
    super.key,
    required this.config,
    required this.grandTotal,
    required this.onMethodSelected,
  });

  @override
  State<SslPaymentPage> createState() => _SslPaymentPageState();
}

class _SslPaymentPageState extends State<SslPaymentPage> {
  int _tabIndex = 1;
  PaymentMethod? _selected;

  // -- Settings loaded from admin --
  String _storeTitle = 'ElectroZoneBD';
  double _convenienceCharge = 0;
  String _termsText =
      'By clicking the "Pay" button you agree to our Terms of Service which is limited to facilitating your payment to ElectroZoneBD.';
  String _offersTitle = 'Special Offers and Savings';
  String _noOffersText = 'No offers available for this transaction';
  bool _tabCardEnabled = true;
  bool _tabMobileEnabled = true;
  bool _tabNetBankingEnabled = true;
  bool _tabMoreEnabled = true;
  String _tabCardLabel = 'Card';
  String _tabMobileLabel = 'Mobile Ban...';
  String _tabNetBankingLabel = 'Net Banking';
  String _tabMoreLabel = 'More';
  String _cardComingSoon = 'Card payment coming soon';
  String _netBankingComingSoon = 'Net Banking coming soon';
  String _moreComingSoon = 'More options coming soon';

  // -- Countdown timer --
  int _remainingSeconds = 5 * 60;
  Timer? _timer;
  late final String _trxId;

  @override
  void initState() {
    super.initState();
    _trxId =
        'EC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (widget.config.bkashEnabled) {
      _selected = PaymentMethod.bkash;
    } else if (widget.config.nagadEnabled) {
      _selected = PaymentMethod.nagad;
    } else if (widget.config.rocketEnabled) {
      _selected = PaymentMethod.rocket;
    } else if (widget.config.upayEnabled) {
      _selected = PaymentMethod.upay;
    }

    _loadSslSettings();
  }

  Future<void> _loadSslSettings() async {
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
      } catch (_) {}
    }
    if (!mounted) return;

    final minutes = int.tryParse(vals['ssl_timer_minutes'] ?? '') ?? 5;
    setState(() {
      if ((vals['ssl_store_title'] ?? '').isNotEmpty)
        _storeTitle = vals['ssl_store_title']!;
      _remainingSeconds = minutes * 60;
      _convenienceCharge =
          double.tryParse(vals['ssl_convenience_charge'] ?? '') ?? 0;
      if ((vals['ssl_terms_text'] ?? '').isNotEmpty)
        _termsText = vals['ssl_terms_text']!;
      if ((vals['ssl_offers_title'] ?? '').isNotEmpty)
        _offersTitle = vals['ssl_offers_title']!;
      if ((vals['ssl_no_offers_text'] ?? '').isNotEmpty)
        _noOffersText = vals['ssl_no_offers_text']!;
      _tabCardEnabled = vals['ssl_tab_card_enabled'] != '0';
      _tabMobileEnabled = vals['ssl_tab_mobile_enabled'] != '0';
      _tabNetBankingEnabled = vals['ssl_tab_netbanking_enabled'] != '0';
      _tabMoreEnabled = vals['ssl_tab_more_enabled'] != '0';
      if ((vals['ssl_tab_card_label'] ?? '').isNotEmpty)
        _tabCardLabel = vals['ssl_tab_card_label']!;
      if ((vals['ssl_tab_mobile_label'] ?? '').isNotEmpty)
        _tabMobileLabel = vals['ssl_tab_mobile_label']!;
      if ((vals['ssl_tab_netbanking_label'] ?? '').isNotEmpty)
        _tabNetBankingLabel = vals['ssl_tab_netbanking_label']!;
      if ((vals['ssl_tab_more_label'] ?? '').isNotEmpty)
        _tabMoreLabel = vals['ssl_tab_more_label']!;
      if ((vals['ssl_card_coming_soon'] ?? '').isNotEmpty)
        _cardComingSoon = vals['ssl_card_coming_soon']!;
      if ((vals['ssl_netbanking_coming_soon'] ?? '').isNotEmpty)
        _netBankingComingSoon = vals['ssl_netbanking_coming_soon']!;
      if ((vals['ssl_more_coming_soon'] ?? '').isNotEmpty)
        _moreComingSoon = vals['ssl_more_coming_soon']!;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Defer setState to avoid the mouse-tracker assertion on Flutter Web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _onTimeout();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTimeout() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your payment session has expired. Please try again.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close payment page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String get _timerDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isExpiringSoon => _remainingSeconds <= 60;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8ECF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -- Card header --
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066CC),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'SSL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _storeTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.grey300,
                                ),
                              ),
                              Text(
                                'Trx ID: $_trxId',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.grey300,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // -- Countdown timer display --
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _isExpiringSoon
                                  ? Colors.red.shade50
                                  : AppColors.grey200,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isExpiringSoon
                                    ? Colors.red.shade300
                                    : AppColors.grey200,
                              ),
                            ),
                            child: Text(
                              _timerDisplay,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isExpiringSoon
                                    ? Colors.red
                                    : AppColors.grey200,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    // -- Card body --
                    isWide
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(24),
                                    child: _buildLeftPanel(),
                                  ),
                                ),
                                const VerticalDivider(width: 1, thickness: 1),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: _buildRightPanel(),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildLeftPanel(),
                                const SizedBox(height: 16),
                                _buildRightPanel(),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Left panel --------------------------------------------------------------

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are paying',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tk ${widget.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey300,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.grey300),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Pay with',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.qr_code, size: 18, color: Color(0xFF0066CC)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _leftRow('Payable Amount', 'Tk ${widget.grandTotal.toStringAsFixed(2)}'),
        const Divider(height: 20),
        _leftRow(
          'Convenience Charge',
          'Tk ${_convenienceCharge.toStringAsFixed(2)}',
        ),
        const Divider(height: 20),
        _leftRow(
          'Total amount',
          'Tk ${(widget.grandTotal + _convenienceCharge).toStringAsFixed(2)}',
          bold: true,
        ),
        const SizedBox(height: 28),
        Text(
          _offersTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        const Text(
          'Automatically Applied with Eligible Payments',
          style: TextStyle(fontSize: 11, color: AppColors.grey300),
        ),
        const Divider(height: 24),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 52,
                color: Colors.black26,
              ),
              const SizedBox(height: 8),
              Text(
                _noOffersText,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leftRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: AppColors.grey300,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  // -- Right panel -------------------------------------------------------------

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LogIn()));
              },
              icon: const Icon(
                Icons.person_outline,
                size: 16,
                color: Color(0xFF0066CC),
              ),
              label: const Text(
                'Login',
                style: TextStyle(color: Color(0xFF0066CC), fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tabs
        Row(
          children: [
            if (_tabCardEnabled) ...[
              _tab(0, Icons.credit_card_outlined, _tabCardLabel),
              const SizedBox(width: 8),
            ],
            if (_tabMobileEnabled) ...[
              _tab(1, Icons.phone_android_outlined, _tabMobileLabel),
              const SizedBox(width: 8),
            ],
            if (_tabNetBankingEnabled) ...[
              _tab(2, Icons.account_balance_outlined, _tabNetBankingLabel),
              const SizedBox(width: 8),
            ],
            if (_tabMoreEnabled)
              _tab(3, Icons.grid_view_outlined, _tabMoreLabel),
          ],
        ),
        const SizedBox(height: 16),

        if (_tabIndex == 1 && _tabMobileEnabled) ...[
          const Text(
            'Pay with Mobile Banking',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMobileGrid(),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                _tabIndex == 0
                    ? _cardComingSoon
                    : _tabIndex == 2
                    ? _netBankingComingSoon
                    : _moreComingSoon,
                style: const TextStyle(color: AppColors.grey300),
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Pay button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selected == null || _remainingSeconds <= 0)
                ? null
                : () => widget.onMethodSelected(_selected!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Pay ?${(widget.grandTotal + _convenienceCharge).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _termsText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'SSL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Text(
                  'COMMERZ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Secured by ',
                  style: TextStyle(fontSize: 10, color: AppColors.grey300),
                ),
                const Icon(Icons.lock_outline, size: 11, color: AppColors.grey300),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'PCI DSS',
                    style: TextStyle(fontSize: 9, color: AppColors.grey300),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0066CC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF0066CC) : AppColors.grey200,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.white : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileGrid() {
    final methods = <Map<String, dynamic>>[];
    if (widget.config.bkashEnabled) {
      methods.add({
        'label': 'bKash',
        'logo': 'assets/payments/baksh.png',
        'method': PaymentMethod.bkash,
      });
    }
    if (widget.config.nagadEnabled) {
      methods.add({
        'label': 'Nagad',
        'logo': 'assets/payments/nagad.png',
        'method': PaymentMethod.nagad,
      });
    }
    if (widget.config.rocketEnabled) {
      methods.add({
        'label': 'Rocket',
        'logo': 'assets/payments/rocket.png',
        'method': PaymentMethod.rocket,
      });
    }
    if (widget.config.upayEnabled) {
      methods.add({
        'label': 'Upay',
        'logo': 'assets/payments/upay.png',
        'method': PaymentMethod.upay,
      });
    }

    if (methods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No mobile banking methods available.',
          style: TextStyle(color: AppColors.grey300),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(methods.length, (i) {
        final m = methods[i];
        final isSelected = _selected == m['method'];
        return GestureDetector(
          onTap: () => setState(() => _selected = m['method'] as PaymentMethod),
          child: SizedBox(
            width: 80,
            height: 70,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0066CC)
                      : AppColors.grey200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        m['logo'] as String,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          m['label'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066CC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}











