import 'package:cached_network_image/cached_network_image.dart';
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'image_resolver.dart';

/// Optimized image widget with caching, progressive loading, and error handling
/// Use this instead of Image.network for better performance
class OptimizedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showShimmer;

  const OptimizedImageWidget({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Handle asset images through the Flutter asset bundle on every platform.
    if (_isAssetImage(imageUrl!)) {
      final assetPath = _getAssetPath(imageUrl!);
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          assetPath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }

    // Handle network images with caching
    final networkUrl = ImageResolver.resolveUrl(imageUrl!);
    if (kDebugMode)
      debugPrint('?? OptimizedImage: raw=$imageUrl ? resolved=$networkUrl');

    if (networkUrl.isEmpty) return _buildPlaceholder();

    // CachedNetworkImage has issues on Flutter Web ? use Image.network directly
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          networkUrl,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _buildLoadingPlaceholder(),
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: networkUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => showShimmer
            ? _buildShimmerPlaceholder()
            : _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
      ),
    );
  }

  bool _isAssetImage(String url) {
    return url.startsWith('assets/') ||
        url.startsWith('/assets/') ||
        url.startsWith('asset:');
  }

  String _getAssetPath(String url) {
    if (url.startsWith('asset:')) {
      return url.substring(6);
    }
    if (url.startsWith('/assets/')) {
      return url.substring(1);
    }
    return url;
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.black26,
      highlightColor: AppColors.grey300,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.grey300,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.grey300,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.black54,
        size: (width != null && width! < 80) ? 24 : 40,
      ),
    );
  }
}
