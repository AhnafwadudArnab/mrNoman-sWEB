import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';

class QrScannerBody extends StatelessWidget {
  final Future<void> Function(String) onCodeScanned;

  const QrScannerBody({super.key, required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 64, color: AppColors.grey300),
            SizedBox(height: 16),
            Text(
              'QR Scanner is only available on mobile app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.grey300),
            ),
          ],
        ),
      ),
    );
  }
}










