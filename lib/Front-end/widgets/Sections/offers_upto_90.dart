import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Banner_provider.dart';
import '../../utils/image_resolver.dart';

/// A horizontal row of 4 offer cards showing "Up to 90% OFF" with background images.
class OffersUpto90 extends StatelessWidget {
  const OffersUpto90({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BannerProvider>();
    final offers = bp.offers90;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    // If no offers configured yet, show nothing
    if (offers.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppDimensions.padding(context) * 0.8;
        final columns = isMobile
            ? 1
            : constraints.maxWidth < 1100
            ? 2
            : 4;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: offers
              .map(
                (o) => SizedBox(
                  width: cardWidth,
                  child: _OfferCard(
                    title: o['label'] as String,
                    imageUrl: o['image'] as String,
                    discountLabel: 'UP TO 90% OFF',
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String discountLabel;

  const _OfferCard({
    required this.title,
    required this.imageUrl,
    required this.discountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(ImageResolver.resolveUrl(imageUrl)),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.35),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 260;
                return Row(
                  children: [
                    // left thumbnail box
                    if (!compact) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // title and small label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Limited time',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // big discount label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            discountLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

