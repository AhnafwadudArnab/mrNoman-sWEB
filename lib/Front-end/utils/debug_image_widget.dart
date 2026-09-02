import 'package:flutter/material.dart';
import 'image_resolver.dart';

/// Debug widget to help identify image loading issues
class DebugImageWidget extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const DebugImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.red[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(height: 4),
            Text(
              'Empty URL',
              style: TextStyle(color: Colors.red[900], fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ImageResolver.image(
          imageUrl: imageUrl,
          fit: fit,
          width: width,
          height: height,
        ),
        // Debug overlay (only in debug mode)
        if (const bool.fromEnvironment('dart.vm.product') == false)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(2),
              child: Text(
                _getImageType(imageUrl!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  String _getImageType(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return 'NET: ${url.substring(0, url.length > 30 ? 30 : url.length)}...';
    }
    if (url.startsWith('assets/') || url.startsWith('/assets/')) {
      return 'ASSET: $url';
    }
    if (url.startsWith('asset:')) {
      return 'ASSET_PREFIX: $url';
    }
    if (url.startsWith('/uploads/')) {
      return 'UPLOAD: $url';
    }
    return 'UNKNOWN: $url';
  }
}
