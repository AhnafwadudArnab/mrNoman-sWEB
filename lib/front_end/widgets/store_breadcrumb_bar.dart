import 'package:flutter/material.dart';
import '../Dimensions/responsive_dimensions.dart';
import '../pages/home_page.dart';

/// Standard e-commerce breadcrumb and back navigation bar.
/// Matches patterns from major e-commerce platforms (Amazon, Daraz, StarTech):
/// provides a clear "Back" button with route-fallback and direct "Home" breadcrumb.
class StoreBreadcrumbBar extends StatelessWidget {
  final String currentPage;
  final String? parentPage;
  final VoidCallback? onParentTap;
  final Widget? trailing;

  const StoreBreadcrumbBar({
    super.key,
    required this.currentPage,
    this.parentPage,
    this.onParentTap,
    this.trailing,
  });

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  void _handleHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final horizontalPad = r.value(
      smallMobile: 12.0,
      mobile: 12.0,
      tablet: 24.0,
      smallDesktop: 32.0,
      desktop: 48.0,
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 8),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => _handleBack(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back, size: 15, color: Color(0xFF1F2937)),
                  SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(
            height: 16,
            width: 1,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 8),

          // Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _handleHome(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.home_outlined, size: 15, color: Color(0xFF6B7280)),
                          SizedBox(width: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (parentPage != null && parentPage!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '/',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                    InkWell(
                      onTap: onParentTap,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          parentPage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: onParentTap != null
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '/',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ),

                  Text(
                    currentPage,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
