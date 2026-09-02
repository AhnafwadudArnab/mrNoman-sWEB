import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Banner_provider.dart';
import '../../utils/image_resolver.dart';

class MidBannerRow extends StatelessWidget {
  const MidBannerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final bp = context.watch<BannerProvider>();
    final banners = bp.midBanners;

    String _bannerImage(Map<String, String> banner) {
      final raw = (banner['img'] ?? banner['image'] ?? '').trim();
      if (raw.toLowerCase() == 'null') return '';
      return raw;
    }

    ImageProvider _resolveImage(String path) {
      // Always use ImageResolver — handles full URLs, /uploads/, assets
      final resolved = ImageResolver.resolveUrl(path);
      if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
        return NetworkImage(resolved);
      }
      return AssetImage(resolved);
    }

    final bannerHeight = r.value(
      smallMobile: 80.0,
      mobile: 100.0,
      tablet: 140.0,
      smallDesktop: 150.0,
      desktop: 160.0,
    );

    final bannerWidth = r.value(
      smallMobile: 180.0,
      mobile: 220.0,
      tablet: 280.0,
      smallDesktop: 320.0,
      desktop: 360.0,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: banners
            .where((b) => _bannerImage(b).isNotEmpty)
            .map(
              (b) => GestureDetector(
                onTap: () async {
                  final link = (b['link'] ?? '').trim();
                  if (link.isNotEmpty) {
                    final uri = Uri.tryParse(link);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
                child: Container(
                  width: bannerWidth,
                  height: bannerHeight,
                  margin: EdgeInsets.symmetric(
                    horizontal: AppDimensions.padding(context) * 0.4,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image(
                          image: _resolveImage(_bannerImage(b)),
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.22),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.36),
                                  Colors.white.withValues(alpha: 0.74),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image(
                          image: _resolveImage(_bannerImage(b)),
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.62),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

