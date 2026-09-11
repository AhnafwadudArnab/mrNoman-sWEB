/// Admin Panel Responsive Design Constants & Utilities
/// Standardized breakpoints and responsive helpers for all admin pages
library;

import 'package:flutter/material.dart';

// ============================================================
// RESPONSIVE BREAKPOINTS (Standardized across all admin pages)
// ============================================================
class AdminResponsive {
  // Breakpoint thresholds (in logical pixels)
  static const double mobileBreakpoint = 480;        // iPhone 11, Galaxy S10
  static const double smallTabletBreakpoint = 600;   // iPad Mini  
  static const double tabletBreakpoint = 768;        // iPad
  static const double desktopBreakpoint = 1024;      // Desktop monitors
  
  // Padding/margin adjustments
  static const double paddingMobile = 12.0;
  static const double paddingTablet = 16.0;
  static const double paddingDesktop = 24.0;
  
  static const double marginMobile = 8.0;
  static const double marginTablet = 12.0;
  static const double marginDesktop = 16.0;
  
  // Font size adjustments for small screens
  static const double fontSizeTitleMobile = 18.0;
  static const double fontSizeTitleTablet = 20.0;
  static const double fontSizeTitleDesktop = 22.0;
  
  static const double fontSizeBodyMobile = 12.0;
  static const double fontSizeBodyTablet = 13.0;
  static const double fontSizeBodyDesktop = 14.0;
  
  // ============================================================
  // DEVICE CLASSIFICATION HELPERS
  // ============================================================
  
  /// Check if current screen is mobile (< 480px)
  static bool isMobile(BoxConstraints constraints) {
    return constraints.maxWidth < mobileBreakpoint;
  }
  
  /// Check if current screen is small tablet (480-600px)
  static bool isSmallTablet(BoxConstraints constraints) {
    return constraints.maxWidth >= mobileBreakpoint && 
           constraints.maxWidth < smallTabletBreakpoint;
  }
  
  /// Check if current screen is tablet (600-1024px)
  static bool isTablet(BoxConstraints constraints) {
    return constraints.maxWidth >= smallTabletBreakpoint && 
           constraints.maxWidth < desktopBreakpoint;
  }
  
  /// Check if current screen is desktop (>= 1024px)
  static bool isDesktop(BoxConstraints constraints) {
    return constraints.maxWidth >= desktopBreakpoint;
  }
  
  /// Check if screen is mobile or small tablet (< 600px)
  static bool isSmallScreen(BoxConstraints constraints) {
    return constraints.maxWidth < smallTabletBreakpoint;
  }
  
  /// Check if screen is tablet or larger (>= 600px)
  static bool isLargeScreen(BoxConstraints constraints) {
    return constraints.maxWidth >= smallTabletBreakpoint;
  }
  
  // ============================================================
  // RESPONSIVE VALUE SELECTORS
  // ============================================================
  
  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BoxConstraints constraints) {
    if (isMobile(constraints)) {
      return const EdgeInsets.all(paddingMobile);
    } else if (isSmallTablet(constraints)) {
      return const EdgeInsets.all(paddingTablet);
    }
    return const EdgeInsets.all(paddingDesktop);
  }
  
  /// Get responsive horizontal padding
  static EdgeInsets getPaddingHorizontal(BoxConstraints constraints) {
    final p = isMobile(constraints) ? paddingMobile : paddingTablet;
    return EdgeInsets.symmetric(horizontal: p);
  }
  
  /// Get responsive vertical padding
  static EdgeInsets getPaddingVertical(BoxConstraints constraints) {
    final p = isMobile(constraints) ? paddingMobile : paddingTablet;
    return EdgeInsets.symmetric(vertical: p);
  }
  
  /// Get responsive title font size
  static double getTitleFontSize(BoxConstraints constraints) {
    if (isMobile(constraints)) return fontSizeTitleMobile;
    if (isSmallTablet(constraints)) return fontSizeTitleTablet;
    return fontSizeTitleDesktop;
  }
  
  /// Get responsive body font size
  static double getBodyFontSize(BoxConstraints constraints) {
    if (isMobile(constraints)) return fontSizeBodyMobile;
    if (isSmallTablet(constraints)) return fontSizeBodyTablet;
    return fontSizeBodyDesktop;
  }
  
  /// Get responsive grid column count
  static int getGridColumns(BoxConstraints constraints, {
    int? mobileCount,
    int? tabletCount,
    int? desktopCount,
  }) {
    mobileCount ??= 1;
    tabletCount ??= 2;
    desktopCount ??= 4;
    
    if (isMobile(constraints)) return mobileCount;
    if (isTablet(constraints)) return tabletCount;
    return desktopCount;
  }
  
  /// Get responsive spacing (gap between items)
  static double getSpacing(BoxConstraints constraints) {
    if (isMobile(constraints)) return 8.0;
    if (isSmallTablet(constraints)) return 12.0;
    return 16.0;
  }
  
  // ============================================================
  // LAYOUT HELPERS FOR COMMON PATTERNS
  // ============================================================
  
  /// Determine if two fields should be side-by-side or stacked
  static bool shouldStackFields(BoxConstraints constraints) {
    return constraints.maxWidth < 640;
  }
  
  /// Determine if table should show simplified card view
  static bool shouldUseCardListForTable(BoxConstraints constraints) {
    return constraints.maxWidth < 500;
  }
  
  /// Determine if toolbar buttons should stack
  static bool shouldStackToolbarButtons(BoxConstraints constraints) {
    return constraints.maxWidth < 500;
  }
}

// ============================================================
// USAGE EXAMPLE
// ============================================================
/*
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = AdminResponsive.isMobile(constraints);
    final padding = AdminResponsive.getPadding(constraints);
    final fontSize = AdminResponsive.getTitleFontSize(constraints);
    
    return Container(
      padding: padding,
      child: isMobile
        ? Column(...)  // Stack vertically on mobile
        : Row(...)      // Side-by-side on desktop
    );
  }
)

// For grids:
LayoutBuilder(
  builder: (context, constraints) {
    final cols = AdminResponsive.getGridColumns(
      constraints,
      mobileCount: 1,
      tabletCount: 2,
      desktopCount: 4,
    );
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: AdminResponsive.getSpacing(constraints),
        mainAxisSpacing: AdminResponsive.getSpacing(constraints),
      ),
      ...
    );
  }
)
*/
