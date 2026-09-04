import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerBody extends StatefulWidget {
  final Future<void> Function(String) onCodeScanned;

  const QrScannerBody({super.key, required this.onCodeScanned});

  @override
  State<QrScannerBody> createState() => _QrScannerBodyState();
}

class _QrScannerBodyState extends State<QrScannerBody> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handlingScan = false;
  String? _lastCode;

  Future<void> _onDetect(BarcodeCapture capture) async {
    final barcode = capture.barcodes.firstOrNull;
    final code = barcode?.rawValue?.trim() ?? '';
    if (code.isEmpty || _handlingScan) return;
    if (_lastCode == code) return;

    _lastCode = code;
    _handlingScan = true;
    await widget.onCodeScanned(code);
    if (mounted) {
      _handlingScan = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
              // Overlay
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF2E3192),
                      width: 8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Align the QR code inside the frame to scan.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}









