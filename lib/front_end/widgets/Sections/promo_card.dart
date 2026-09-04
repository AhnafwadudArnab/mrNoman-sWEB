import 'package:flutter/material.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/image_resolver.dart';

class PromoCard extends StatelessWidget {
  final String label;
  final String off;
  final Color color;
  final String imageUrl;

  const PromoCard({
    super.key,
    required this.label,
    required this.off,
    required this.color,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        height: r.value(
          smallMobile: 65.0,
          mobile: 70.0,
          tablet: 80.0,
          smallDesktop: 85.0,
          desktop: 90.0,
        ),
        padding: EdgeInsets.all(AppDimensions.padding(context) * 0.8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.95),
          image: DecorationImage(
            image: NetworkImage(ImageResolver.resolveUrl(imageUrl)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              const Color(0x47000000),
              BlendMode.darken,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(6),
                // optional subtle border so the thumbnail stands out on light images
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    off,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppDimensions.smallFont(context),
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
}










