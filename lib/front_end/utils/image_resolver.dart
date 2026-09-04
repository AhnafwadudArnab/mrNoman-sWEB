import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'constants.dart';
import 'app_base_url.dart';
import 'api_service.dart';

/// Resolves product image_url from API: 'asset:...' -> load from Flutter assets;
/// 'http...' or full URL -> load from network. Relative paths like /uploads/... use active backend base URL.
class ImageResolver {
  static const String _assetPrefix = 'asset:';

  static String _activeImageBaseUrl() {
    // Images are served from /api/uploads/... on the backend.
    // Use the full API base URL (including /api) so that
    // /uploads/img.jpg ? https://electrozonebd.com/api/uploads/img.jpg
    final activeApiBase = ApiService.overrideBaseUrl;
    if (activeApiBase != null && activeApiBase.isNotEmpty) {
      return activeApiBase; // already includes /api
    }
    return AppConstants.baseUrl; // AppConfig.apiBaseUrl ? includes /api
  }

  static bool isAssetUrl(String? url) =>
      url != null && url.startsWith(_assetPrefix);

  static String assetPath(String? url) {
    if (url == null || !url.startsWith(_assetPrefix)) return '';
    return url.substring(_assetPrefix.length);
  }

  static bool isFlutterAsset(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('assets/') ||
        url.startsWith('/assets/') ||
        url.startsWith('asset:');
  }

  /// Normalises legacy upload URL variants that may be stored in the DB or
  /// returned by the old backend config. All variants map to
  /// https://host/public/uploads/filename  (the new canonical).
  static String _fixMissingApiSegment(String url) {
    // Already correct new canonical: https://host/public/uploads/...
    if (RegExp(r'^https?://[^/]+/public/uploads/').hasMatch(url)) {
      return url;
    }
    // Legacy: https://host/api/public/uploads/... ? strip /api prefix
    final withApiPublic = RegExp(r'^(https?://[^/]+)/api/public/uploads/(.+)$');
    if (withApiPublic.hasMatch(url)) {
      return url.replaceFirstMapped(
        withApiPublic,
        (m) => '${m.group(1)}/public/uploads/${m.group(2)}',
      );
    }
    // Legacy: https://host/api/uploads/... ? strip /api prefix
    final withApiUploads = RegExp(r'^(https?://[^/]+)/api/uploads/(.+)$');
    if (withApiUploads.hasMatch(url)) {
      return url.replaceFirstMapped(
        withApiUploads,
        (m) => '${m.group(1)}/public/uploads/${m.group(2)}',
      );
    }
    // Legacy: https://host/uploads/... ? add /public prefix
    final bareUploads = RegExp(r'^(https?://[^/]+)/uploads/(.+)$');
    if (bareUploads.hasMatch(url)) {
      return url.replaceFirstMapped(
        bareUploads,
        (m) => '${m.group(1)}/public/uploads/${m.group(2)}',
      );
    }
    return url;
  }

  /// Returns the production host (e.g. https://electrozonebd.com) regardless
  /// of whether the app is running in debug/local mode. Uploaded images always
  /// live on the production server, never on the local dev server.
  static String _productionHost() {
    const String _productionUrl = 'https://electrozonebd.com';
    final activeBase = ApiService.overrideBaseUrl;
    if (activeBase != null && activeBase.isNotEmpty) {
      final host = activeBase.replaceAll(RegExp(r'/api$'), '');
      // Flutter Web debug runs the app and API on different localhost ports.
      // Mid-banner files are served as static images, so that cross-origin
      // localhost request does not receive the API CORS headers. These
      // bundled banner files are deployed on the production host, which is
      // also the correct source for previewing them during local web work.
      if (!host.contains('localhost') &&
          !host.contains('127.0.0.1') &&
          !host.contains('10.0.2.2')) {
        return host;
      }
      return _productionUrl;
    }
    final base = AppConstants.baseUrl.replaceAll(RegExp(r'/api$'), '');
    if (base.contains('localhost') ||
        base.contains('10.0.2.2') ||
        base.contains('127.0.0.1')) {
      return _productionUrl;
    }
    return base;
  }

  /// Normalises any upload path variant to the canonical URL exposed by the
  /// active API base, e.g. https://electrozonebd.com/public/uploads/filename
  ///
  /// DB stores:  /public/uploads/img_xxx.png  (new canonical ? since config fix)
  ///             /api/public/uploads/img_xxx.png (legacy ? from old config)
  ///             /uploads/img_xxx.png (older legacy)
  /// Working URL: https://electrozonebd.com/public/uploads/img_xxx.png
  static String _resolveUploadUrl(String imageUrl) {
    final base = _activeImageBaseUrl(); // e.g. https://electrozonebd.com/api
    final host = base.replaceAll(RegExp(r'/api$'), '');

    // Extract just the filename from any upload path variant
    String filename;
    if (imageUrl.startsWith('/public/uploads/')) {
      filename = imageUrl.substring('/public/uploads/'.length);
    } else if (imageUrl.startsWith('/api/public/uploads/')) {
      filename = imageUrl.substring('/api/public/uploads/'.length);
    } else if (imageUrl.startsWith('/api/uploads/')) {
      filename = imageUrl.substring('/api/uploads/'.length);
    } else if (imageUrl.startsWith('/uploads/')) {
      filename = imageUrl.substring('/uploads/'.length);
    } else {
      filename = imageUrl.split('/').last;
    }

    final midBannerAsset = _midBannerAssetUrl(filename);
    if (midBannerAsset != null) return midBannerAsset;

    // Canonical: https://electrozonebd.com/public/uploads/filename
    return '$host/public/uploads/$filename';
  }

  static String? _midBannerAssetUrl(String filename) {
    var raw = filename.trim();
    if (raw.startsWith(_assetPrefix)) {
      raw = raw.substring(_assetPrefix.length);
    }

    // Banner records may contain a plain filename, a relative path, or a URL.
    // Use the filename for generated mid-banner assets in every case.
    final parsed = Uri.tryParse(raw);
    final path = parsed != null && parsed.path.isNotEmpty ? parsed.path : raw;
    final assetName = path.split('/').last;
    final isMidBannerPath = path.contains('mid-banner-products/');
    if (!assetName.startsWith('mid_banner_') && !isMidBannerPath) return null;

    final bannerName = assetName.substring('mid_banner_'.length);
    final resolvedName = assetName.startsWith('mid_banner_')
      ? bannerName
      : assetName;
    if (resolvedName.isEmpty) return null;

    // On both web and mobile, serve from backend's public folder
    // This is more reliable than trying to use Flutter assets
    return '${_productionHost()}/public/assets/mid-banner-products/$resolvedName';
  }

  /// Resolves any image URL string to a fully qualified URL.
  /// Use this everywhere before passing to Image.network or NetworkImage.
  static String resolveUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    // Check for mid-banner assets FIRST (asset: prefix or mid_banner_)
    final midBannerUrl = _midBannerAssetUrl(imageUrl);
    if (midBannerUrl != null) return midBannerUrl;

    if (isFlutterAsset(imageUrl)) return imageUrl;

    // Already a full URL ? fix any malformed upload paths
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // If it's a full URL pointing to an upload path, normalise it too
      final uploadMatch = RegExp(
        r'^https?://[^/]+((/public/uploads/|/api/public/uploads/|/api/uploads/|/uploads/).+)$',
      ).firstMatch(imageUrl);
      if (uploadMatch != null) {
        return _resolveUploadUrl(uploadMatch.group(1)!);
      }
      return _fixMissingApiSegment(imageUrl);
    }

    // Relative upload paths ? canonical URL
    if (imageUrl.startsWith('/public/uploads/') ||
        imageUrl.startsWith('/api/public/uploads/') ||
        imageUrl.startsWith('/api/uploads/') ||
        imageUrl.startsWith('/uploads/')) {
      return _resolveUploadUrl(imageUrl);
    }

    final base = _activeImageBaseUrl();
    if (imageUrl.startsWith('/api/')) {
      final host = base.replaceAll(RegExp(r'/api$'), '');
      return '$host$imageUrl';
    }
    if (imageUrl.startsWith('/')) return '$base$imageUrl';

    // If it's just a filename, prepend the uploads path
    if (!imageUrl.contains('/')) {
      final host = base.replaceAll(RegExp(r'/api$'), '');
      return '$host/public/uploads/$imageUrl';
    }

    return '$base/$imageUrl';
  }

  static String _resolveNetworkUrl(String imageUrl) {
    if (isFlutterAsset(imageUrl)) return imageUrl;

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      final uploadMatch = RegExp(
        r'^https?://[^/]+((/public/uploads/|/api/public/uploads/|/api/uploads/|/uploads/).+)$',
      ).firstMatch(imageUrl);
      if (uploadMatch != null) {
        return _resolveUploadUrl(uploadMatch.group(1)!);
      }
      return _fixMissingApiSegment(imageUrl);
    }

    if (imageUrl.startsWith('/public/uploads/') ||
        imageUrl.startsWith('/api/public/uploads/') ||
        imageUrl.startsWith('/api/uploads/') ||
        imageUrl.startsWith('/uploads/')) {
      return _resolveUploadUrl(imageUrl);
    }

    final base = _activeImageBaseUrl();
    if (imageUrl.startsWith('/api/')) {
      final host = base.replaceAll(RegExp(r'/api$'), '');
      return '$host$imageUrl';
    }
    if (imageUrl.startsWith('/')) return '$base$imageUrl';

    // If it's just a filename, prepend the uploads path
    if (!imageUrl.contains('/')) {
      final host = base.replaceAll(RegExp(r'/api$'), '');
      return '$host/public/uploads/$imageUrl';
    }

    return '$base/$imageUrl';
  }

  static String _getAssetPath(String imageUrl) {
    if (imageUrl.startsWith('/assets/')) return imageUrl.substring(1);
    if (imageUrl.startsWith('assets/')) return imageUrl;
    if (imageUrl.startsWith('asset:')) return imageUrl.substring(6);
    return imageUrl;
  }

  /// On Flutter Web, asset images must be loaded via absolute URL.
  static String _webAssetUrl(String assetPath) {
    final base = getAppBaseUrl();
    // Ensure proper asset path - Flutter Web assets are served from /
    return '$base/$assetPath';
  }

  /// On Flutter Web, asset images are loaded via network from the app host.
  static Widget image({
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholderBox(width: width, height: height, child: placeholder);
    }

    final path = isAssetUrl(imageUrl) ? assetPath(imageUrl) : imageUrl;

    if (isFlutterAsset(path)) {
      final assetPath = _getAssetPath(path);
      // Flutter Web: Image.asset() doesn't work reliably for network-served assets.
      // Load via absolute network URL instead.
      if (kIsWeb) {
        final networkAssetUrl = _webAssetUrl(assetPath);
        return Image.network(
          networkAssetUrl,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : _placeholderBox(width: width, height: height),
          errorBuilder: (_, __, ___) =>
              _placeholderBox(width: width, height: height, child: placeholder),
        );
      }
      return Image.asset(
        assetPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            _placeholderBox(width: width, height: height, child: placeholder),
      );
    }

    final networkUrl = _resolveNetworkUrl(path);
    if (kIsWeb) {
      return Image.network(
        networkUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : _placeholderBox(width: width, height: height),
        errorBuilder: (_, __, ___) =>
            _placeholderBox(width: width, height: height, child: placeholder),
      );
    }
    return Image.network(
      networkUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholderBox(
          width: width,
          height: height,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) =>
          _placeholderBox(width: width, height: height, child: placeholder),
    );
  }

  static ImageProvider imageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const NetworkImage(
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      );
    }

    if (isAssetUrl(imageUrl)) {
      if (kIsWeb) return NetworkImage(_webAssetUrl(assetPath(imageUrl)));
      return AssetImage(assetPath(imageUrl));
    }

    if (isFlutterAsset(imageUrl)) {
      if (kIsWeb) return NetworkImage(_webAssetUrl(_getAssetPath(imageUrl)));
      return AssetImage(_getAssetPath(imageUrl));
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      final uploadMatch = RegExp(
        r'^https?://[^/]+((/public/uploads/|/api/public/uploads/|/api/uploads/|/uploads/).+)$',
      ).firstMatch(imageUrl);
      if (uploadMatch != null) {
        return NetworkImage(_resolveUploadUrl(uploadMatch.group(1)!));
      }
      return NetworkImage(_fixMissingApiSegment(imageUrl));
    }

    return NetworkImage(_resolveNetworkUrl(imageUrl));
  }

  static Widget _placeholderBox({
    double? width,
    double? height,
    Widget? child,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.black26,
      child:
          child ??
          Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.grey300,
            size: (width != null && width < 80) ? 24 : 40,
          ),
    );
  }
}


