import 'package:flutter/foundation.dart';

/// Returns the base URL of the Flutter Web app (e.g. http://localhost:62422)
/// On non-web platforms returns empty string (assets loaded natively).
String getAppBaseUrl() {
  if (!kIsWeb) return '';
  // Uri.base gives the current page URL on Flutter Web
  final base = Uri.base;
  return '${base.scheme}://${base.host}${base.port != 0 && base.port != 80 && base.port != 443 ? ':${base.port}' : ''}';
}
