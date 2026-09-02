import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../Dimensions/responsive_dimensions.dart';

/// Loads the SSLCommerz gateway URL in a WebView.
/// Intercepts success / fail / cancel redirect URLs and pops with a result.
class SslCommerzPage extends StatefulWidget {
  /// The GatewayPageURL returned by the SSLCommerz initiation API.
  final String gatewayUrl;

  /// Amount shown in the app bar subtitle.
  final double amount;

  const SslCommerzPage({
    super.key,
    required this.gatewayUrl,
    required this.amount,
  });

  @override
  State<SslCommerzPage> createState() => _SslCommerzPageState();
}

class _SslCommerzPageState extends State<SslCommerzPage> {
  late final WebViewController _controller;
  bool _loading = true;

  // These must match the success/fail/cancel URLs configured in your backend
  // SSLCommerz settings (or passed as parameters when initiating the session).
  static const _successKeywords = [
    '/payment/success',
    'payment_success',
    'ssl_success',
  ];
  static const _failKeywords = ['/payment/fail', 'payment_fail', 'ssl_fail'];
  static const _cancelKeywords = [
    '/payment/cancel',
    'payment_cancel',
    'ssl_cancel',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final url = req.url.toLowerCase();

            if (_successKeywords.any((k) => url.contains(k))) {
              // Extract tran_id from URL query params if present
              final uri = Uri.tryParse(req.url);
              final tranId =
                  uri?.queryParameters['tran_id'] ??
                  uri?.queryParameters['val_id'] ??
                  'SSL-${DateTime.now().millisecondsSinceEpoch}';
              Navigator.of(context).pop(_SslResult.success(tranId));
              return NavigationDecision.prevent;
            }

            if (_failKeywords.any((k) => url.contains(k))) {
              Navigator.of(context).pop(_SslResult.fail());
              return NavigationDecision.prevent;
            }

            if (_cancelKeywords.any((k) => url.contains(k))) {
              Navigator.of(context).pop(_SslResult.cancel());
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.gatewayUrl));
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isMobile = r.isMobile || r.isSmallMobile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0066CC),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Payment',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '৳${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(_SslResult.cancel()),
          tooltip: 'Cancel payment',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0066CC)),
                  SizedBox(height: isMobile ? 10 : 12),
                  Text(
                    'Loading payment gateway...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Result returned when the WebView page is popped.
class _SslResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? transactionId;

  const _SslResult._({
    required this.isSuccess,
    required this.isCancelled,
    this.transactionId,
  });

  factory _SslResult.success(String txnId) =>
      _SslResult._(isSuccess: true, isCancelled: false, transactionId: txnId);

  factory _SslResult.fail() =>
      _SslResult._(isSuccess: false, isCancelled: false);

  factory _SslResult.cancel() =>
      _SslResult._(isSuccess: false, isCancelled: true);
}

/// Public result type used by callers.
class SslPaymentResult {
  final SslPaymentStatus status;
  final String? transactionId;

  const SslPaymentResult({required this.status, this.transactionId});
}

enum SslPaymentStatus { success, failed, cancelled }
