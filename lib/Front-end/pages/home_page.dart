import 'dart:async';

import 'package:electrocitybd1/Front-end/widgets/Sections/TechPart.dart';
import 'package:electrocitybd1/Front-end/widgets/Sections/Trendings/TrendingItems.dart';
import 'package:electrocitybd1/Front-end/widgets/Sidebar/sidebar.dart';
import 'package:electrocitybd1/Front-end/widgets/footer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Dimensions/responsive_dimensions.dart';
import '../Provider/Banner_provider.dart';
import '../widgets/Sections/BestSellings/best_selling.dart';
import '../widgets/Sections/Collections/collections_pages.dart';
import '../widgets/Sections/Deals_of_the_day.dart';
import '../widgets/Sections/FeaturedBrandsStrip.dart';
import '../widgets/Sections/Flash Sale/flash_sale.dart';
import '../widgets/Sections/mid_banner_row.dart';
import '../widgets/header.dart';
import '../utils/api_service.dart';
import '../utils/image_resolver.dart';
import '../utils/app_base_url.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load banners once, not on every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BannerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final showSidebar = r.isSmallDesktop || r.isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: !showSidebar ? Drawer(child: const Sidebar()) : null,
      floatingActionButton: const _WhatsAppSupportFab(),
      body: Column(
        children: [
          const Header(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSidebar)
                  SizedBox(width: AppDimensions.padding(context)),
                if (showSidebar) const Sidebar(),
                if (showSidebar)
                  SizedBox(width: AppDimensions.padding(context)),
                const Expanded(child: _MainContent()),
                if (showSidebar)
                  SizedBox(width: AppDimensions.padding(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppSupportFab extends StatefulWidget {
  const _WhatsAppSupportFab();

  @override
  State<_WhatsAppSupportFab> createState() => _WhatsAppSupportFabState();
}

class _WhatsAppSupportFabState extends State<_WhatsAppSupportFab>
    with WidgetsBindingObserver {
  String? _whatsAppNumber;
  bool _loading = true;

  String _normalizeWhatsAppNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    return digits;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWhatsAppNumber();
    // Removed periodic 1-min timer — only refresh on app resume
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWhatsAppNumber();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadWhatsAppNumber() async {
    final number = await _fetchWhatsAppNumber();

    if (mounted) {
      setState(() {
        _whatsAppNumber = number;
        _loading = false;
      });
    }
  }

  Future<void> _refreshWhatsAppNumber() async {
    final number = await _fetchWhatsAppNumber();

    if (mounted && number != _whatsAppNumber) {
      setState(() {
        _whatsAppNumber = number;
      });
    }
  }

  Future<String?> _fetchWhatsAppNumber() async {
    try {
      final support = await ApiService.getSiteSetting(
        'support_whatsapp_number',
      );
      var number = (support['setting_value'] ?? '').toString().trim();

      if (number.isEmpty) {
        final phone = await ApiService.getSiteSetting('site_phone');
        number = (phone['setting_value'] ?? '').toString().trim();
      }

      return _normalizeWhatsAppNumber(number);
    } catch (e) {
      return null;
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final number = _normalizeWhatsAppNumber(_whatsAppNumber ?? '');
    if (number.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support WhatsApp number is not configured.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent('Hello Admin, I need help with my ElectroZoneBD order.')}',
    );

    final opened = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
    if (opened) return;

    final fallbackOpened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
    if (fallbackOpened) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp chat open করা যাচ্ছে না।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: const Color(0xFF25D366),
        mini: true,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _openWhatsApp(context),
      backgroundColor: const Color(0xFF25D366),
      foregroundColor: Colors.white,
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
      label: const Text('Help', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _MainContent extends StatefulWidget {
  const _MainContent({super.key});

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final bp = context.read<BannerProvider>();
      final len = bp.heroSlides.length;
      if (len < 2) return;
      final next = (_currentIndex + 1) % len;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _sliderButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF111827)),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    List<Map<String, String>> slides,
    AppResponsive r,
  ) {
    final len = slides.length;
    final height = r.value(
      smallMobile: 200.0,
      mobile: 250.0,
      tablet: 280.0,
      smallDesktop: 400.0,
      desktop: 420.0,
    );
    final contentLeft = r.value(
      smallMobile: 12.0,
      mobile: 20.0,
      tablet: 40.0,
      smallDesktop: 50.0,
      desktop: 60.0,
    );

    ImageProvider _heroImage(String path) {
      if (path.isEmpty) return const AssetImage('assets/1.png');

      // Always use ImageResolver for all paths — it handles:
      // - full URLs (with /api fix if missing)
      // - /uploads/... relative paths
      // - asset paths
      final resolved = ImageResolver.resolveUrl(path);

      // If resolved to a network URL, use NetworkImage
      if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        return NetworkImage(resolved);
      }

      // Flutter asset path
      if (kIsWeb) {
        final base = getAppBaseUrl();
        final url = base.isNotEmpty ? '$base/$resolved' : resolved;
        return NetworkImage(url);
      }
      return AssetImage(resolved);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // PageView for smooth left-right sliding
            PageView.builder(
              controller: _pageController,
              itemCount: len,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) {
                final slide = slides[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: _heroImage(slide['image']!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x990F172A),
                            Color(0x330F172A),
                            Color(0x000F172A),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: contentLeft,
                      top: r.value(
                        smallMobile: 20.0,
                        mobile: 30.0,
                        tablet: 40.0,
                        smallDesktop: 50.0,
                        desktop: 60.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          slide['label']!,
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: r.value(
                              smallMobile: 10.0,
                              mobile: 12.0,
                              tablet: 13.0,
                              smallDesktop: 13.0,
                              desktop: 13.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Left arrow
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _sliderButton(
                  Icons.chevron_left,
                  onTap: len > 1
                      ? () => _goToPage((_currentIndex - 1 + len) % len)
                      : null,
                ),
              ),
            ),

            // Right arrow
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: _sliderButton(
                  Icons.chevron_right,
                  onTap: len > 1
                      ? () => _goToPage((_currentIndex + 1) % len)
                      : null,
                ),
              ),
            ),

            // Dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  len,
                  (i) => GestureDetector(
                    onTap: () => _goToPage(i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i == _currentIndex
                            ? const Color(0xFFF97316)
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final bp = context.watch<BannerProvider>();
    final slides = bp.heroSlides;
    final len = slides.length;
    final hasHero = len > 0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: r.value(
          smallMobile: 8.0,
          mobile: 12.0,
          tablet: 16.0,
          smallDesktop: 16.0,
          desktop: 16.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// HERO + BEST SELLING
          r.isSmallMobile || r.isMobile
              ? Column(
                  children: [
                    if (hasHero) ...[
                      _buildHeroBanner(context, slides, r),
                      const SizedBox(height: 12),
                    ],
                    const BestSellingBox(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasHero) ...[
                      Expanded(
                        flex: 7,
                        child: _buildHeroBanner(context, slides, r),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const SizedBox(width: 300, child: BestSellingBox()),
                  ],
                ),

          SizedBox(
            height: r.value(
              smallMobile: 12.0,
              mobile: 14.0,
              tablet: 16.0,
              smallDesktop: 16.0,
              desktop: 16.0,
            ),
          ),

          /// OTHER SECTIONS
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: CollectionsPage(),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 10.0,
              mobile: 11.0,
              tablet: 12.0,
              smallDesktop: 12.0,
              desktop: 12.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: TrendingItems(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: const FeaturedBrandsStrip(),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 12.0,
              mobile: 14.0,
              tablet: 16.0,
              smallDesktop: 16.0,
              desktop: 16.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: const DealsOfTheDay(),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 10.0,
              mobile: 12.0,
              tablet: 14.0,
              smallDesktop: 14.0,
              desktop: 14.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: FlashSaleCarousel(),
          ),
          SizedBox(
            height: r.value(
              smallMobile: 12.0,
              mobile: 14.0,
              tablet: 16.0,
              smallDesktop: 16.0,
              desktop: 16.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(
                smallMobile: 8.0,
                mobile: 10.0,
                tablet: 12.0,
                smallDesktop: 12.0,
                desktop: 12.0,
              ),
            ),
            child: MidBannerRow(),
          ),

          SizedBox(
            height: r.value(
              smallMobile: 12.0,
              mobile: 14.0,
              tablet: 16.0,
              smallDesktop: 16.0,
              desktop: 16.0,
            ),
          ),
          Techpart(),
          SizedBox(
            height: r.value(
              smallMobile: 16.0,
              mobile: 20.0,
              tablet: 24.0,
              smallDesktop: 24.0,
              desktop: 24.0,
            ),
          ),
          const FooterSection(showQr: true),
        ],
      ),
    );
  }
}

