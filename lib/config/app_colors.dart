import 'package:flutter/material.dart';

/// 🎨 CENTRALIZED COLOR SYSTEM
///
/// This is the single source of truth for all colors in the app.
/// Import this file and use AppColors.colorName instead of hardcoded Color values.
///
/// Features:
/// - Centralized management: Change once, applies everywhere
/// - Consistency: All colors organized by category
/// - Easy theming: Ready for dark mode and custom themes
/// - Labeled colors: Clear naming for different use cases
///
/// Usage:
/// ```dart
/// import 'package:electrocitybd1/config/app_colors.dart';
///
/// Text('Hello', style: TextStyle(color: AppColors.textPrimary))
/// Container(color: AppColors.bgLight)
/// ```

class AppColors {
  // ═══════════════════════════════════════════════════════════════
  // 🎯 PRIMARY & BRAND COLORS
  // ═══════════════════════════════════════════════════════════════
  /// Main brand color - Dark blue
  static const Color primary = Color(0xFF123456);

  /// Secondary brand color
  static const Color secondary = Color(0xFF56789A);

  /// Primary accent - Orange
  static const Color p1 = Color(0xFFFFB700);

  /// Secondary accent - Yellow
  static const Color p2 = Color(0xFFfbd000);

  /// Light yellow/gold
  static const Color blond = Color(0xFFf5e886);

  /// Main purple (alternative primary)
  static const Color primaryPurple = Color(0xFF7C3AED);

  /// Darker purple variant
  static const Color primaryDark = Color(0xFF6D28D9);

  /// Dark theme color
  static const Color tertiary = Color(0xFF0066CC);

  /// Brand orange
  static const Color brandOrange = Color(0xFFF59E0B);

  /// Brand orange alternative
  static const Color brandOrangeAlt = Color(0xFFCF9641);

  /// Brand orange light
  static const Color brandOrangeLight = Color(0xFFFAB12F);

  // ═══════════════════════════════════════════════════════════════
  // 🏙️ BACKGROUND COLORS
  // ═══════════════════════════════════════════════════════════════
  /// Main page background - Light
  static const Color background = Color(0xFFF5F6FA);

  /// Light background for sections
  static const Color bgLight = Color(0xFFF5F5F5);

  /// Light background - Secondary
  static const Color bgSecondary = Color(0xFFF5F5F5);

  /// Card background - White
  static const Color cardBackground = Colors.white;

  /// Card background - Very light
  static const Color bgCard = Color(0xFFFAFAFA);

  /// Input field background
  static const Color bgInput = Color(0xFFEEEEEE);

  /// Light background - Primary variant
  static const Color bgPrimary = Color(0xFFF7F8FD);

  /// Dark theme background
  static const Color bgDark = Color(0xFF2A2A2A);

  /// Dark theme alternative
  static const Color bgDarkAlt = Color(0xFF0F172A);

  /// Footer background - Very dark
  static const Color footerBackground = Color(0xFF0F172A);

  /// Header background
  static const Color headerBackground = primary;

  /// Dark gradient start (for banners/headers)
  static const Color bgDarkGradientStart = Color(0xFF1a1a2e);

  /// Dark gradient end
  static const Color bgDarkGradientEnd = Color(0xFF16213e);

  // Legacy header colors (kept for backward compatibility with lib/front_end/widgets/colors.dart)
  static const Color hdr1 = Color(0xFFfbd633);
  static const Color hdr2 = Color(0xFFb9b8bd);
  static const Color hdr3 = Color(0xFFD5D5DB);
  static const Color hdr4 = Color.fromARGB(255, 228, 208, 189);

  // ═══════════════════════════════════════════════════════════════
  // 📝 TEXT COLORS - BLACK রাখা হয়েছে (স্পষ্টতার জন্য)
  // ═══════════════════════════════════════════════════════════════
  /// Primary text - Black for clarity and titles
  static const Color textPrimary = Colors.black87;

  /// Primary text - Dark (legacy name)
  static const Color textPrimaryDark = Color(0xFF1E1E1E);

  /// Secondary text - Gray
  static const Color textSecondary = Color(0xFF6B7280);

  /// Light text - White (for dark backgrounds)
  static const Color textLight = Colors.white;

  /// Muted text - Light gray
  static const Color textMuted = Color(0xFF64748B);

  /// Text on dark backgrounds
  static const Color textOnDark = Color(0xFF111827);

  /// White text
  static const Color textWhite = Colors.white;

  // ═══════════════════════════════════════════════════════════════
  // 🎯 ICON COLORS - BLACK রাখা হয়েছে (for visibility)
  // ═══════════════════════════════════════════════════════════════
  /// Primary icon color - Black for visibility
  static const Color iconPrimary = Colors.black87;

  /// Secondary icon color
  static const Color iconSecondary = Color(0xFF757575);

  /// Light icon color
  static const Color iconLight = Color(0xFFBDBDBD);

  // ═══════════════════════════════════════════════════════════════
  // 🔲 BORDER & DIVIDER COLORS - LIGHT GRAY
  // ═══════════════════════════════════════════════════════════════
  /// Light border - Used for card borders
  static const Color border = Color(0xFFE5E7EB);

  /// Light border - Alternative
  static const Color borderLight = Color(0xFFE5E7EB);

  /// Medium border - For more prominent borders
  static const Color borderMedium = Color(0xFFE0E0E0);

  /// Medium border - Alternative
  static const Color borderMediumAlt = Color(0xFFD0D0D0);

  /// Divider color - For separating sections
  static const Color divider = Color(0xFFCBD5E1);

  /// Divider color - Alternative
  static const Color dividerColor = Color(0xFFE8E8E8);

  /// Alternative divider
  static const Color dividerAlt = Color(0xFFCBD5E1);

  // ═══════════════════════════════════════════════════════════════
  // ✅❌ STATUS COLORS - SUCCESS / ERROR / WARNING / INFO
  // ═══════════════════════════════════════════════════════════════
  // SUCCESS - Green
  /// Success indicator - Green
  static const Color success = Color(0xFF16A34A);

  /// Success - Alternative (darker)
  static const Color successGreen = Color(0xFF4CAF50);

  /// Success background - Light
  static const Color successLight = Color(0xFFD4EDDA);

  /// Success border color
  static const Color successBorder = Color(0xFFB2EBF2);

  // ERROR - Red
  /// Error indicator - Red
  static const Color error = Color(0xFFDC2626);

  /// Error - Alternative
  static const Color errorRed = Colors.red;

  /// Error background - Light
  static const Color errorLight = Color(0xFFFFF3CD);

  /// Error text - Dark
  static const Color errorDark = Color(0xFF721C24);

  // WARNING - Yellow/Orange
  /// Warning indicator - Yellow
  static const Color warning = Color(0xFFFACC15);

  /// Warning - Alternative (amber)
  static const Color warningAlt = Color(0xFFFFC107);

  /// Warning - Orange variant
  static const Color warningOrange = Color(0xFFFF9800);

  // INFO - Blue
  /// Info indicator - Blue
  static const Color info = Color(0xFF0284C7);

  /// Info background - Light
  static const Color infoLight = Color(0xFFE0F7FA);

  // ═══════════════════════════════════════════════════════════════
  // 🏷️ PRODUCT STATUS COLORS
  // ═══════════════════════════════════════════════════════════════
  /// In-stock background - Light green
  static const Color inStockBg = Color(0xFFD4EDDA);

  /// In-stock text - Dark green
  static const Color inStockText = Color(0xFF155724);

  /// Low stock background - Light yellow
  static const Color lowStockBg = Color(0xFFFFEDD5);

  /// Low stock text - Dark yellow
  static const Color lowStockText = Color(0xFFB45309);

  /// Out-of-stock background - Light red
  static const Color outOfStockBg = Color(0xFFF8D7DA);

  /// Out-of-stock text - Dark red
  static const Color outOfStockText = Color(0xFF721C24);

  // ═══════════════════════════════════════════════════════════════
  // 🌈 ACCENT & HIGHLIGHT COLORS
  // ═══════════════════════════════════════════════════════════════
  /// Accent blue - For product borders
  static const Color accentBlue = Color(0xFF62A9D8);

  /// Accent purple
  static const Color accentPurple = Color(0xFF7C4DFF);

  /// Accent gold
  static const Color accentGold = Color(0xFFFFD169);

  /// Accent cyan
  static const Color accentCyan = Color(0xFF00A651);

  /// Accent green
  static const Color accentGreen = Color(0xFF25D366);

  /// Green color (from legacy colors.dart)
  static const Color green = Color(0xFF1E3922);

  /// Yellow gold color (from legacy colors.dart)
  static const Color yellowGold = Color(0xFFFBB03B);

  // ═══════════════════════════════════════════════════════════════
  // 🎨 SHADE VARIANTS - Material Color Shades
  // ═══════════════════════════════════════════════════════════════
  // Red shades
  static const Color redLight = Colors.red;
  static const Color redShade50 = Color(0xFFFFF5F5);
  static const Color redShade100 = Color(0xFFFFEBEE);
  static const Color redShade200 = Color(0xFFEF9A9A);
  static const Color redShade300 = Color(0xFFE57373);
  static const Color redShade700 = Color(0xFFD32F2F);
  static const Color redShade800 = Color(0xFFC62828);
  static const Color redShade900 = Color(0xFFB71C1C);

  // Orange shades
  static const Color orangeShade50 = Colors.orange;
  static const Color orangeShade100 = Color(0xFFFFE0B2);
  static const Color orangeShade700 = Color(0xFFF57C00);
  static const Color orangeShade800 = Color(0xFFE65100);

  // Green shades
  static const Color greenShade50 = Color(0xFFC8E6C9);
  static const Color greenShade800 = Color(0xFF2E7D32);

  // BlueGrey shades
  static const Color blueGreyShade300 = Color(0xFF90CAF9);
  static const Color blueGreyShade500 = Color(0xFF64B5F6);
  static const Color blueGreyShade700 = Color(0xFF1976D2);
  static const Color blueGreyShade800 = Color(0xFF1565C0);

  // Blue shades
  static const Color blueShade900 = Color(0xFF0D47A1);

  // Amber shades
  static const Color amberShade700 = Color(0xFFFBC02D);

  // ═══════════════════════════════════════════════════════════════
  // 🔘 GREY COLOR VARIANTS (Material Grey Scale)
  // ═══════════════════════════════════════════════════════════════
  /// Material grey
  static const Color grey = Colors.grey;

  /// Very light grey
  static const Color greyLight = Color(0xFFBDBDBD);

  /// Light grey - 200 variant (most used for light backgrounds)
  static const Color grey200 = Color(0xFFEEEEEE);

  /// Light grey - 300 variant (most used for borders/text)
  static const Color grey300 = Color(0xFFE0E0E0);

  /// Medium-light grey - 400 variant
  static const Color grey400 = Color(0xFFBDBDBD);

  /// Medium grey - 500 variant
  static const Color grey500 = Color(0xFF9E9E9E);

  /// Medium-dark grey - 600 variant
  static const Color grey600 = Color(0xFF757575);

  /// Medium grey
  static const Color greyMedium = Color(0xFF9E9E9E);

  /// Dark grey - 700 variant
  static const Color grey700 = Color(0xFF616161);

  /// Dark grey - 800 variant
  static const Color grey800 = Color(0xFF424242);

  /// Very dark grey - 900 variant
  static const Color grey900 = Color(0xFF212121);

  /// Very dark grey
  static const Color greyDark = Color(0xFF424242);

  // ═══════════════════════════════════════════════════════════════
  // 👥 OVERLAY & TRANSPARENCY COLORS
  // ═══════════════════════════════════════════════════════════════
  // Black overlays with varying opacity
  static const Color overlayBlack5 = Color(0x0D000000); // 5%
  static const Color overlayBlack8 = Color(0x14000000); // 8%
  static const Color overlayBlack12 = Color(0x1F000000); // 12% shadow
  static const Color overlayBlack26 = Color(0x42000000); // 26%
  static const Color overlayBlack28 = Color(0x47000000); // 28%
  static const Color overlayBlack35 = Color(0x59000000); // 35%
  static const Color overlayBlack50 = Color(0x80000000); // 50%

  // Red overlays
  static const Color overlayRed5 = Color(0x0DF44336); // 5%
  static const Color overlayRed7 = Color(0x12F44336); // 7%
  static const Color overlayRed10 = Color(0x14F44336); // 10%
  static const Color overlayRed26 = Color(0x1AF44336); // 26%
  static const Color overlayRed40 = Color(0x4DF44336); // 40%

  // Orange overlays
  static const Color overlayOrange5 = Color(0x0DFF9800); // 5%
  static const Color overlayOrange20 = Color(0x33FF9800); // 20%

  // Blue overlays
  static const Color overlayBlue10 = Color(0x1A2196F3); // 10%

  // White overlays
  static const Color whiteOverlay36 = Color(0x5CFFFFFF); // 36%
  static const Color whiteOverlay62 = Color(0x9EFFFFFF); // 62%
  static const Color whiteOverlay65 = Color(0xA6FFFFFF); // 65%
  static const Color whiteOverlay72 = Color(0xB8FFFFFF); // 72%

  // Additional overlays
  static const Color shadowColor = Color(0x1F000000); // Black shadow
  static const Color overlayDark = Color(0x80000000); // 50% dark overlay

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ UTILITY COLORS
  // ═══════════════════════════════════════════════════════════════
  /// Pure white
  static const Color white = Colors.white;

  /// Pure black
  static const Color black = Colors.black;

  /// Transparent
  static const Color transparent = Colors.transparent;

  // ═══════════════════════════════════════════════════════════════
  // 🔧 HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Get text color based on background brightness
  static Color getTextColor(Color backgroundColor) {
    final luminance =
        (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;
    return luminance > 0.5 ? textPrimary : textWhite;
  }

  /// Create dark gradient for backgrounds
  static LinearGradient darkGradient() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgDarkGradientStart, bgDarkGradientEnd],
  );

  /// Create semi-transparent overlay
  static Color createOverlay(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get status color based on status string
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'delivered':
        return success;
      case 'pending':
      case 'processing':
        return warning;
      case 'error':
      case 'failed':
      case 'cancelled':
        return error;
      case 'info':
        return info;
      default:
        return grey;
    }
  }
}
