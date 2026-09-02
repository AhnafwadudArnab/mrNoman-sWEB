import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Production backend base URL (no trailing slash)
  static const String _productionUrl = 'https://electrozonebd.com';

  /// Domain for production deployment
  static const String domain = 'electrozonebd.com';

  static String get apiBaseUrl => '$baseUrl/api';

  static String get baseUrl {
    // If explicitly set via --dart-define, use that
    if (_envUrl.isNotEmpty) return _envUrl;

    // Always use production URL (cPanel) for release builds
    if (kReleaseMode) return 'https://$domain';

    // Web debug builds — use local backend for development
    if (kIsWeb) {
      // Local development:
      return 'http://localhost:8000';
      // Production (cPanel):
      // return 'https://electrozonebd.com';
    }

    // Native debug builds: use cPanel production server
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Production (cPanel):
        return 'https://electrozonebd.com';
      // For local testing, change to: 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // Production (cPanel):
        return 'https://electrozonebd.com';
      // For local testing, change to: 'http://localhost:8000';
    }
  }

  static String uploadPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }

  // Database credentials are managed by backend only
  // Removed deprecated DB/JWT fields — never store secrets in client code

  static const int uploadMaxSize = 5242880; // 5MB

  static const String uploadDir = 'public/uploads';

  static bool get isProduction => kReleaseMode;

  static bool get isDevelopment => kDebugMode;

  static String get environment => isProduction ? 'Production' : 'Development';

  static void printConfig() {
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔧 App Configuration');
      debugPrint('═══════════════════════════════════════');
      debugPrint('Environment: $environment');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint('Base URL: $baseUrl');
      debugPrint('═══════════════════════════════════════');
    }
  }
}
