import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// ADMIN DESIGN SYSTEM — single source of truth for all
// colours, typography, spacing and reusable widgets.
// ============================================================

class AdminTheme {
  AdminTheme._();

  // ── DARK MODE PALETTE ──────────────────────────────────
  // Page canvas
  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceAlt = Color(0xFF1C2333);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkDivider = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextMuted = Color(0xFF484F58);

  // ── LIGHT MODE PALETTE ─────────────────────────────────
  static const Color lightBg = Color(0xFFFAFAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFEAECF0);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);

  // ── Shared Colors (both modes) ─────────────────────────
  // Premium Purple Theme (Changed from Orange)
  static const Color brand = Color(0xFF7C3AED); // Deep Purple/Indigo
  static const Color brandLight = Color(0xFFA78BFA); // Light Purple
  static const Color brandDim = Color(0x267C3AED); // Transparent Purple
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);
  static const Color purple = Color(0xFFBC8CFF);

  // ── Default (Light Mode) - Changed from Dark ────
  static const Color bg = lightBg;
  static const Color surface = lightSurface;
  static const Color surfaceAlt = lightSurfaceAlt;
  static const Color border = lightBorder;
  static const Color divider = lightDivider;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textMuted = lightTextMuted;

  // ── Order status ───────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD29922);
      case 'processing':
        return const Color(0xFF58A6FF);
      case 'shipped':
        return const Color(0xFFBC8CFF);
      case 'delivered':
        return const Color(0xFF3FB950);
      case 'cancelled':
        return const Color(0xFFF85149);
      default:
        return const Color(0xFF8B949E);
    }
  }

  // ── Elevation shadows ──────────────────────────────────
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  // ── Border radius ──────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  // ── Card decoration ────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    double radius = radiusMd,
    bool highlighted = false,
  }) => BoxDecoration(
    color: color ?? surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: highlighted
          ? brand.withValues(alpha: 0.6)
          : border.withValues(alpha: 0.6),
      width: highlighted ? 2 : 1,
    ),
    boxShadow: highlighted ? shadowMd : shadowSm,
  );

  // ── Input decoration ───────────────────────────────────
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
    String? prefixText,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    labelStyle: GoogleFonts.hindSiliguri(
      color: textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: GoogleFonts.hindSiliguri(color: textMuted, fontSize: 13),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: textSecondary, size: 18)
        : null,
    suffix: suffix,
    filled: true,
    fillColor: surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: border, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: brand, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: error, width: 1.5),
    ),
  );

  // ── Admin ThemeData with Bangla font support ───────────
  static ThemeData get themeData => _buildThemeData(isDark: true);

  static ThemeData _buildThemeData({required bool isDark}) {
    final isDarkMode = isDark;
    final bgColor = isDarkMode ? darkBg : lightBg;
    final surfaceColor = isDarkMode ? darkSurface : lightSurface;
    final textColor = isDarkMode ? darkTextPrimary : lightTextPrimary;
    final textSecondaryColor = isDarkMode
        ? darkTextSecondary
        : lightTextSecondary;
    final borderColor = isDarkMode ? darkBorder : lightBorder;

    return (isDarkMode ? ThemeData.dark() : ThemeData.light()).copyWith(
      colorScheme: isDarkMode
          ? const ColorScheme.dark(
              primary: brand,
              secondary: brand,
              surface: darkSurface,
              error: error,
            )
          : const ColorScheme.light(
              primary: brand,
              secondary: brand,
              surface: lightSurface,
              error: error,
            ),
      scaffoldBackgroundColor: bgColor,
      textTheme: GoogleFonts.hindSiliguriTextTheme(
        isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.hindSiliguri(
          color: textSecondaryColor,
          fontSize: 13,
        ),
        hintStyle: GoogleFonts.hindSiliguri(
          color: isDarkMode ? darkTextMuted : lightTextMuted,
          fontSize: 13,
        ),
      ),
    );
  }

  static ThemeData buildThemeData({required bool isDark}) =>
      _buildThemeData(isDark: isDark);

  // ── Helper Methods for Dynamic Colors (Light/Dark Mode) ──
  /// Get text color based on theme
  static Color getTextColor(bool isDarkMode, {bool primary = true}) {
    if (isDarkMode) {
      return primary ? darkTextPrimary : darkTextSecondary;
    } else {
      return primary ? lightTextPrimary : lightTextSecondary;
    }
  }

  /// Get background color based on theme
  static Color getBgColor(bool isDarkMode) {
    return isDarkMode ? darkBg : lightBg;
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? darkSurface : lightSurface;
  }

  /// Get surface alternate color based on theme
  static Color getSurfaceAltColor(bool isDarkMode) {
    return isDarkMode ? darkSurfaceAlt : lightSurfaceAlt;
  }

  /// Get border color based on theme
  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? darkBorder : lightBorder;
  }

  /// Get divider color based on theme
  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? darkDivider : lightDivider;
  }

  /// Get muted text color based on theme
  static Color getMutedTextColor(bool isDarkMode) {
    return isDarkMode ? darkTextMuted : lightTextMuted;
  }
}

// ── Shared Widgets ─────────────────────────────────────────

/// Rounded card container consistent with the design system.
class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final bool highlighted;
  final VoidCallback? onTap;

  const ACard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = AdminTheme.radiusMd,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AdminTheme.cardDecoration(
        color: color,
        radius: radius,
        highlighted: highlighted,
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: container,
      );
    }
    return container;
  }
}

/// Standard page section header with icon + title + optional action.
class ASectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const ASectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminTheme.brandDim,
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
          child: Icon(icon, color: AdminTheme.brand, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AdminTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

/// Stat/metric tile used in dashboard and section heroes.
class AStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  final bool trendPositive;

  const AStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.trendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AdminTheme.brand;
    return ACard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AdminTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
                  border: Border.all(
                    color: color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        (trendPositive ? AdminTheme.success : AdminTheme.error)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    trendPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: trendPositive
                        ? AdminTheme.success
                        : AdminTheme.error,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  trend!,
                  style: TextStyle(
                    color: trendPositive
                        ? AdminTheme.success
                        : AdminTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Primary CTA button (amber fill).
class APrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double height;

  const APrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AdminTheme.brand,
        foregroundColor: Colors.black87,
        disabledBackgroundColor: AdminTheme.brand.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        ),
        elevation: 2,
        shadowColor: AdminTheme.brand.withValues(alpha: 0.4),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.black54,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Ghost / outlined button.
class AGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const AGhostButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminTheme.textSecondary;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: c.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15), const SizedBox(width: 6)],
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Status badge (chip).
class ABadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool dot;

  const ABadge({super.key, required this.label, this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminTheme.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dot ? 10 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order-status specific badge.
class AStatusBadge extends StatelessWidget {
  final String status;

  const AStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AdminTheme.statusColor(status);
    final label = status[0].toUpperCase() + status.substring(1);
    return ABadge(label: label, color: color, dot: true);
  }
}

/// Dark-themed text field.
class ATextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const ATextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
      validator: validator,
      onChanged: onChanged,
      decoration: AdminTheme.inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: icon,
      ),
    );
  }
}

/// Horizontal divider with optional label.
class ADivider extends StatelessWidget {
  final String? label;

  const ADivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(color: AdminTheme.divider, height: 1);
    }
    return Row(
      children: [
        const Expanded(child: Divider(color: AdminTheme.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label!,
            style: const TextStyle(color: AdminTheme.textMuted, fontSize: 11),
          ),
        ),
        const Expanded(child: Divider(color: AdminTheme.divider, height: 1)),
      ],
    );
  }
}

/// Loading skeleton shimmer placeholder.
class ASkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ASkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = AdminTheme.radiusSm,
  });

  @override
  State<ASkeleton> createState() => _ASkeletonState();
}

class _ASkeletonState extends State<ASkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            AdminTheme.surface,
            AdminTheme.surfaceAlt,
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Empty-state widget.
class AEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminTheme.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AdminTheme.border),
              ),
              child: Icon(icon, color: AdminTheme.textMuted, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AdminTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
