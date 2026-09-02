import 'package:flutter/material.dart';

/// ===============================
/// RESPONSIVE + DIMENSIONS SYSTEM
/// ===============================

class AppResponsive {
  final BuildContext context;

  AppResponsive(this.context);

  static AppResponsive of(BuildContext context) => AppResponsive(context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  /// Breakpoints
  bool get isSmallMobile => width < 375; // 320px
  bool get isMobile => width >= 375 && width < 768; // 375px, 425px
  bool get isTablet => width >= 768 && width < 1024; // 768px
  bool get isSmallDesktop => width >= 1024 && width < 1440; // 1024px
  bool get isDesktop => width >= 1440; // 1440px, 4K

  /// Flexible value selector - ALL 5 PARAMETERS REQUIRED
  T value<T>({
    required T smallMobile,
    required T mobile,
    required T tablet,
    required T smallDesktop,
    required T desktop,
  }) {
    if (isSmallMobile) return smallMobile;
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    if (isSmallDesktop) return smallDesktop;
    return desktop;
  }

  /// Percentage width
  double wp(double percent) => width * percent / 100;

  /// Percentage height
  double hp(double percent) => height * percent / 100;
}

/// ===============================
/// DIMENSIONS
/// ===============================

class AppDimensions {
  static double padding(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 12,
      mobile: 16,
      tablet: 20,
      smallDesktop: 24,
      desktop: 32,
    );
  }

  static double cardWidth(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 150,
      mobile: 180,
      tablet: 220,
      smallDesktop: 250,
      desktop: 280,
    );
  }

  static double cardHeight(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 200,
      mobile: 240,
      tablet: 280,
      smallDesktop: 320,
      desktop: 360,
    );
  }

  static double imageSize(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 120,
      mobile: 150,
      tablet: 180,
      smallDesktop: 200,
      desktop: 220,
    );
  }

  static double titleFont(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 18,
      mobile: 20,
      tablet: 24,
      smallDesktop: 28,
      desktop: 32,
    );
  }

  static double bodyFont(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 13,
      mobile: 14,
      tablet: 15,
      smallDesktop: 16,
      desktop: 16,
    );
  }

  static double smallFont(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 11,
      mobile: 12,
      tablet: 13,
      smallDesktop: 14,
      desktop: 14,
    );
  }

  static double buttonHeight(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 40,
      mobile: 45,
      tablet: 50,
      smallDesktop: 52,
      desktop: 54,
    );
  }

  static double iconSize(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 20,
      mobile: 22,
      tablet: 24,
      smallDesktop: 26,
      desktop: 28,
    );
  }

  static double borderRadius(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 8,
      mobile: 10,
      tablet: 12,
      smallDesktop: 14,
      desktop: 16,
    );
  }
}

/// ===============================
/// EXAMPLE USAGE WIDGET
/// ===============================

class ResponsiveExample extends StatelessWidget {
  const ResponsiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: Column(
          children: [
            Text(
              'Title',
              style: TextStyle(fontSize: AppDimensions.titleFont(context)),
            ),
            SizedBox(height: r.hp(2)),
            Container(
              width: AppDimensions.cardWidth(context),
              height: AppDimensions.cardHeight(context),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadius(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
