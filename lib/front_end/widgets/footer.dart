import 'package:flutter/material.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../All_Pages/CART/Track_ur_orders.dart';
import '../Dimensions/responsive_dimensions.dart';
import '../pages/Profiles/Profile.dart';

class FooterSection extends StatelessWidget {
  final bool showQr;
  final ScrollController? scrollController;

  const FooterSection({super.key, this.showQr = false, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final padding = AppDimensions.padding(context);
    final isMobile = r.isMobile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: padding * 0.5,
            vertical: padding * 0.75,
          ),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFAB12F), Color(0xFFFAB12F), Color(0xFFFAB12F)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isMobile
              ? _buildMobileFooter(context, padding)
              : _buildDesktopFooter(context, padding),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  'Copyright ? 2026 ElectroZoneBD. All Rights Reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppDimensions.smallFont(context),
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 7, 3, 3),
                  ),
                ),
              ),
              if (scrollController != null)
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      scrollController!.animateTo(
                        0,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAB12F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x1A000000),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Back to Top',
                            style: TextStyle(
                              fontSize: AppDimensions.smallFont(context),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogoSection(context),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _linkColumn(context, 'Company', [
                'About Us',
                'Blog',
                'Contact Us',
                'Career',
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _linkColumn(context, 'Services', [
                'My Account',
                'Track Order',
                'Return',
                'FAQ',
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _linkColumn(context, 'Information', [
          'Privacy',
          'Terms',
          'Return Policy',
        ]),
        const SizedBox(height: 12),
        _buildContactInfo(context),
        const SizedBox(height: 12),
        Center(child: _PaymentLogosRow()),
      ],
    );
  }

  Widget _buildDesktopFooter(BuildContext context, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 1, child: _buildLogoSection(context)),
            const SizedBox(width: 30),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: _linkColumn(context, 'Company', [
                      'About Us',
                      'Blog',
                      'Contact Us',
                      'Career',
                    ]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _linkColumn(context, 'Services', [
                      'My Account',
                      'Track Order',
                      'Return',
                      'FAQ',
                    ]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _linkColumn(context, 'Information', [
                      'Privacy',
                      'Terms',
                      'Return Policy',
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(flex: 1, child: _buildContactInfo(context)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Expanded(child: _PaymentLogosRow())],
        ),
      ],
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          radius: AppDimensions.iconSize(context) * 1.2,
          child: ClipOval(
            child: Image.asset(
              'assets/elogo.png',
              width: AppDimensions.iconSize(context) * 2.0,
              height: AppDimensions.iconSize(context) * 2.0,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.storefront,
                color: const Color(0xFF2E3192),
                size: AppDimensions.iconSize(context) * 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ElectroZoneBD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppDimensions.bodyFont(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your one-stop shop for the latest electronics.',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppDimensions.smallFont(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _socialIcon(context, FontAwesomeIcons.facebookF),
            _socialIcon(context, FontAwesomeIcons.twitter),
            _socialIcon(context, FontAwesomeIcons.linkedinIn),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Contact Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppDimensions.bodyFont(context),
          ),
        ),
        const SizedBox(height: 10),
        _contactItem(context, Icons.phone, '+8801341-933958'),
        const SizedBox(height: 6),
        _contactItem(context, Icons.email, 'electrocitybd14@gmail.com'),
        const SizedBox(height: 6),
        _contactItem(
          context,
          Icons.location_on,
          'Sundarban-Square Market, Gulistan, Dhaka, Bangladesh',
        ),
      ],
    );
  }

  Widget _contactItem(BuildContext context, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: AppDimensions.iconSize(context) * 0.6,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: AppDimensions.smallFont(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialIcon(BuildContext context, FaIconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {},
        child: FaIcon(
          icon,
          color: Colors.white,
          size: AppDimensions.iconSize(context) * 0.6,
        ),
      ),
    );
  }
}

Widget _linkColumn(BuildContext context, String title, List<String> links) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: AppDimensions.bodyFont(context),
        ),
      ),
      const SizedBox(height: 6),
      ...links.map((link) => _footerButton(context, link)),
    ],
  );
}

Widget _footerButton(BuildContext context, String text) {
  return TextButton(
    onPressed: () => _handleFooterLinkTap(context, text),
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      minimumSize: const Size(0, 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: AppDimensions.smallFont(context)),
    ),
  );
}

void _handleFooterLinkTap(BuildContext context, String text) {
  final key = text.trim().toLowerCase();

  switch (key) {
    case 'my account':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      return;
    case 'track order':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrackOrderFormPage()),
      );
      return;
    case 'about us':
      _openFooterPage(
        context,
        title: 'About Us',
        body:
            'ElectroZoneBD is a trusted online electronics store in Bangladesh.\n\nWe focus on authentic products, fair prices, and fast delivery with reliable customer support.',
      );
      return;
    case 'blog':
      _openFooterPage(
        context,
        title: 'Blog',
        body:
            'Our blog section will share buying guides, product tips, and tech updates.\n\nStay tuned for new posts from ElectroZoneBD.',
      );
      return;
    case 'contact us':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _ContactUsPage()),
      );
      return;
    case 'career':
      _openFooterPage(
        context,
        title: 'Career',
        body:
            'We are always open to talented people in e-commerce, operations, and customer support.\n\nPlease send your CV to support@electrocitybd.com.',
      );
      return;
    case 'return':
    case 'return policy':
      _openFooterPage(
        context,
        title: 'Return Policy',
        body:
            'Products can be returned based on condition and policy terms.\n\nPlease keep invoice and original packaging. Contact support for return approval and process.',
      );
      return;
    case 'faq':
      _openFooterPage(
        context,
        title: 'FAQ',
        body:
            'Q: How long does delivery take?\nA: Delivery time depends on location and product availability.\n\nQ: How can I track my order?\nA: Use the Track Order section with your order details.',
      );
      return;
    case 'privacy':
      _openFooterPage(
        context,
        title: 'Privacy Policy',
        body:
            'We respect your privacy and protect your personal information.\n\nYour data is used only for account, order processing, and support-related communication.',
      );
      return;
    case 'terms':
      _openFooterPage(
        context,
        title: 'Terms & Conditions',
        body:
            'By using ElectroZoneBD, you agree to our purchase, delivery, return, and account usage terms.\n\nProduct availability and pricing may change without prior notice.',
      );
      return;
    default:
      _openFooterPage(
        context,
        title: text,
        body: '$text information is available in this section.',
      );
  }
}

void _openFooterPage(
  BuildContext context, {
  required String title,
  required String body,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _FooterContentPage(title: title, body: body),
    ),
  );
}

class _FooterContentPage extends StatelessWidget {
  final String title;
  final String body;

  const _FooterContentPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isMobile = r.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 24 : 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xE6FAB12F),
                    const Color(0xFFFFD169),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 48,
                vertical: isMobile ? 24 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      height: 1.8,
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Additional Info Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0x14FAB12F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x4DFAB12F),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAB12F),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'For more assistance, please contact our customer support team.',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: const Color(0xFF111827),
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFAB12F),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: isMobile ? 10 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const _ContactUsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.email_outlined, size: 16),
                          label: const Text('Contact Us'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFAB12F),
                            side: const BorderSide(
                              color: Color(0xFFFAB12F),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactUsPage extends StatelessWidget {
  const _ContactUsPage();

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final isMobile = r.isMobile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 24 : 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xE6FAB12F),
                    const Color(0xFFFFD169),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get In Touch',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'d love to hear from you. Send us a message!',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 48,
                vertical: isMobile ? 24 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _contactCard(
                          context,
                          Icons.phone_outlined,
                          'Phone',
                          '+8801341-933958',
                        ),
                      ),
                      if (!isMobile) const SizedBox(width: 12),
                      Expanded(
                        child: _contactCard(
                          context,
                          Icons.email_outlined,
                          'Email',
                          'electrocitybd14@gmail.com',
                        ),
                      ),
                    ],
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 12),
                    _contactCard(
                      context,
                      Icons.email_outlined,
                      'Email',
                      'electrocitybd14@gmail.com',
                    ),
                  ],
                  const SizedBox(height: 24),
                  _contactCard(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    'Sundarban-Square Market, Gulistan, Dhaka, Bangladesh',
                  ),
                  const SizedBox(height: 32),
                  // Business Hours Box
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0x14FAB12F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x4DFAB12F),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAB12F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Business Hours',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Monday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: const Color(0xFF374151),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFAB12F),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 32,
                          vertical: isMobile ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isMobile = AppResponsive.of(context).isMobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x1AFAB12F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFAB12F), size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PaymentLogosRow extends StatelessWidget {
  const _PaymentLogosRow();

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.padding(context);
    final logoHeight = 32.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _paymentLogoWidget(
          context,
          'assets/payments/amex.png',
          width: 50,
          height: logoHeight,
          rightPadding: padding * 0.5,
        ),
        _paymentLogoWidget(
          context,
          'assets/payments/master.png',
          width: 50,
          height: logoHeight,
          rightPadding: padding * 0.5,
        ),
        _paymentLogoWidget(
          context,
          'assets/payments/paypal.jpg',
          width: 50,
          height: logoHeight,
          rightPadding: padding * 0.5,
        ),
        _paymentLogoWidget(
          context,
          'assets/payments/visa.png',
          width: 50,
          height: logoHeight,
        ),
      ],
    );
  }
}

Widget _paymentLogoWidget(
  BuildContext context,
  String assetPath, {
  required double width,
  required double height,
  double rightPadding = 0,
}) {
  return Padding(
    padding: EdgeInsets.only(right: rightPadding),
    child: Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Container(width: width, height: height, color: Colors.black26),
    ),
  );
}




