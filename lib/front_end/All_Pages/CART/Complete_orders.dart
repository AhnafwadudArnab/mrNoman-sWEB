import 'package:electrocitybd1/config/app_colors.dart';
import 'package:electrocitybd1/front_end/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Dimensions/responsive_dimensions.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import 'cart_models.dart';

String _defaultDeliveryDate() {
  final d = DateTime.now().add(const Duration(days: 5));
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class OrderCompletedPage extends StatefulWidget {
  final String? orderId;
  final String? paymentMethod;
  final String? transactionId;
  final String? estimatedDelivery;
  final List<CartItem> orderItems;
  final double totalAmount;

  const OrderCompletedPage({
    super.key,
    this.orderId,
    this.paymentMethod,
    this.transactionId,
    this.estimatedDelivery,
    this.orderItems = const [],
    this.totalAmount = 0.0,
  });

  @override
  State<OrderCompletedPage> createState() => _OrderCompletedPageState();
}

class _OrderCompletedPageState extends State<OrderCompletedPage> {
  bool _generatingPdf = false;

  Future<void> _downloadInvoice() async {
    setState(() => _generatingPdf = true);
    try {
      final doc = pw.Document();
      final orderId =
          widget.orderId ?? '#EC-${DateTime.now().millisecondsSinceEpoch}';
      final paymentMethod = widget.paymentMethod ?? 'Not specified';
      final transactionId = widget.transactionId ?? '?';
      final estimatedDelivery =
          widget.estimatedDelivery ?? _defaultDeliveryDate();
      final invoiceDate = DateTime.now();
      final dateStr =
          '${invoiceDate.day}/${invoiceDate.month}/${invoiceDate.year}';

      // Calculate totals from items
      double subtotal = 0;
      for (final item in widget.orderItems) {
        subtotal += item.itemTotal;
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Premium Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('1B4D3E'),
                  borderRadius: pw.BorderRadius.circular(12),
                  boxShadow: [
                    pw.BoxShadow(
                      blurRadius: 8,
                      color: PdfColor.fromInt(0x1F000000),
                      offset: const PdfPoint(0, 2),
                    ),
                  ],
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '? ElectroCityBD',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'electrocitybd14@gmail.com',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '+880 1X XXX XXX XXX',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Order ID: $orderId',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: $dateStr',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Order Details Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Information',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1B4D3E'),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Method: $paymentMethod',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Transaction ID: $transactionId',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Delivery Information',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1B4D3E'),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Estimated Delivery: $estimatedDelivery',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Status: Processing',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.black),
              pw.SizedBox(height: 24),

              // Order Items table with Premium styling
              if (widget.orderItems.isNotEmpty) ...[
                pw.Text(
                  'Order Items',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1B4D3E'),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    horizontalInside: pw.BorderSide(
                      color: PdfColors.black,
                      width: 0.5,
                    ),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FixedColumnWidth(60),
                    2: const pw.FixedColumnWidth(90),
                    3: const pw.FixedColumnWidth(90),
                  },
                  children: [
                    // Header row with premium styling
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F0F0F0'),
                      ),
                      children: [
                        _cell('Product Name', bold: true),
                        _cell('Qty', bold: true),
                        _cell('Unit Price', bold: true),
                        _cell('Total', bold: true),
                      ],
                    ),
                    // Data rows
                    ...widget.orderItems.map(
                      (item) => pw.TableRow(
                        children: [
                          _cell(item.name),
                          _cell('${item.quantity}'),
                          _cell('Tk ${item.price.toStringAsFixed(0)}'),
                          _cell('Tk ${item.itemTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Premium Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('E8F5E9'),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('4CAF50'),
                      width: 1.5,
                    ),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      // Subtotal
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Subtotal:',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            'Tk ${subtotal.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      // Divider
                      pw.Divider(color: PdfColor.fromHex('4CAF50')),
                      pw.SizedBox(height: 6),
                      // Grand Total (Premium)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Grand Total:',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('1B4D3E'),
                            ),
                          ),
                          pw.Text(
                            'Tk ${(widget.totalAmount > 0 ? widget.totalAmount : subtotal).toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('4CAF50'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // Premium Footer
              pw.Divider(color: PdfColors.black),
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F5F5F5'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      '? Thank you for shopping with ElectroCityBD!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1B4D3E'),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For support or inquiries, contact us:',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '?? electrocitybd14@gmail.com | ?? +880 1X XXX XXX XXX',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Invoice Generated: ${DateTime.now().toString().substring(0, 16)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: bold ? PdfColor.fromHex('1B4D3E') : PdfColors.black,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isCompact = r.isSmallMobile || r.isMobile || r.isTablet;
    final maxWidth = r.value(
      smallMobile: 360.0,
      mobile: 420.0,
      tablet: 640.0,
      smallDesktop: 760.0,
      desktop: 860.0,
    );
    final pagePad = EdgeInsets.symmetric(
      horizontal: AppDimensions.padding(context),
      vertical: AppDimensions.padding(context) * 0.8,
    );

    return Scaffold(
      appBar: const Header(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.orange),
              child: Text('Menu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.grey300,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: r.value(
                  smallMobile: 20.0,
                  mobile: 24.0,
                  tablet: 30.0,
                  smallDesktop: 36.0,
                  desktop: 40.0,
                ),
              ),
              color: AppColors.grey300,
              child: Column(
                children: [
                  Text(
                    'Order Completed',
                    style: TextStyle(
                      fontSize: AppDimensions.titleFont(context),
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: AppColors.grey300,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '  /  ',
                        style: TextStyle(color: AppColors.grey300, fontSize: 11),
                      ),
                      TextButton(
                        onPressed: null,
                        child: Text(
                          'Order Completed',
                          style: TextStyle(
                            color: AppColors.grey300,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: pagePad,
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB8860B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your order is completed!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey300,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Thank you. Your Order has been received.',
                        style: TextStyle(color: AppColors.grey300, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D3E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _orderInfoColumn(
                          orderId: widget.orderId,
                          paymentMethod: widget.paymentMethod,
                          transactionId: widget.transactionId,
                          estimatedDelivery: widget.estimatedDelivery,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Features Section
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 32,
                horizontal: AppDimensions.padding(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      _buildFeatureItem(
                        icon: Icons.local_shipping_outlined,
                        color: const Color(0xFF1B4D3E),
                        title: 'Free Shipping',
                        subtitle: 'Free shipping for order above ?5000',
                      ),
                      _buildFeatureItem(
                        icon: Icons.payment_outlined,
                        color: const Color(0xFFB8860B),
                        title: 'Flexible Payment',
                        subtitle: 'Multiple secure payment options',
                      ),
                      _buildFeatureItem(
                        icon: Icons.headset_mic_outlined,
                        color: const Color(0xFF1B4D3E),
                        title: '24?7 Support',
                        subtitle: 'We support online all days.',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _orderInfoColumn({
    required String? orderId,
    required String? paymentMethod,
    required String? transactionId,
    required String? estimatedDelivery,
  }) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _infoBlock(
            'Order ID',
            orderId ?? '#EC-${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: _infoBlock('Payment Method', paymentMethod ?? 'Not specified'),
        ),
        SizedBox(
          width: double.infinity,
          child: _infoBlock('Transaction ID', transactionId ?? '?'),
        ),
        SizedBox(
          width: double.infinity,
          child: _infoBlock(
            'Estimated Delivery Date',
            estimatedDelivery ?? _defaultDeliveryDate(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _generatingPdf ? null : _downloadInvoice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4D3E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _generatingPdf
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1B4D3E),
                  ),
                )
              : const Text(
                  'Download Invoice',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.grey300, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}










