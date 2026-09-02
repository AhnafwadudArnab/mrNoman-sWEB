import 'package:flutter/foundation.dart';

/// Safe integer conversion with null check
int? intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safe double conversion with null check
double? doubleOrNull(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Safe string conversion
String getString(dynamic value, [String defaultValue = '']) {
  if (value is String) return value;
  if (value == null) return defaultValue;
  return value.toString();
}

/// Safe boolean conversion
bool getBool(dynamic value, [bool defaultValue = false]) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return defaultValue;
}

/// Extract ID from various API response formats
/// Tries: productId, id, product_id in order
int? extractId(Map<String, dynamic> response) {
  final candidates = [
    response['productId'],
    response['id'],
    response['product_id'],
    response['payment_id'],
    response['payment_method_id'],
    response['method_id'],
  ];

  for (final candidate in candidates) {
    final id = intOrNull(candidate);
    if (id != null && id > 0) return id;
  }

  // Try nested objects
  if (response['product'] is Map) {
    return extractId(response['product'] as Map<String, dynamic>);
  }

  return null;
}

/// Safe list conversion
List<T> asList<T>(dynamic value, [List<T> defaultValue = const []]) {
  if (value is List<T>) return value;
  if (value is List) {
    try {
      return value.cast<T>();
    } catch (_) {
      return defaultValue;
    }
  }
  return defaultValue;
}

/// Safe map conversion
Map<String, dynamic> asMap(
  dynamic value, [
  Map<String, dynamic> defaultValue = const {},
]) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return defaultValue;
    }
  }
  return defaultValue;
}

/// Extract setting value from API response
String? extractSettingValue(Map<String, dynamic>? response) {
  if (response == null) return null;
  final value = response['setting_value'];
  if (value is String) return value;
  if (value == null) return null;
  return value.toString();
}

/// Format duration as HH:MM:SS
String formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Format DateTime as readable string
String formatDateTime(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}

/// Format timestamp (milliseconds) as readable string
String formatTimestamp(int milliseconds) {
  try {
    final dt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return formatDateTime(dt);
  } catch (_) {
    return 'Invalid date';
  }
}

/// Validate price (must be > 0)
bool isValidPrice(dynamic price) {
  final p = doubleOrNull(price);
  return p != null && p > 0;
}

/// Validate stock quantity (must be >= 0)
bool isValidStock(dynamic stock) {
  final s = intOrNull(stock);
  return s != null && s >= 0;
}

/// Validate email format
bool isValidEmail(String email) {
  final pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  return RegExp(pattern).hasMatch(email);
}

/// Validate phone number (basic)
bool isValidPhone(String phone) {
  return phone.isNotEmpty && phone.length >= 10 && phone.length <= 15;
}

/// Debug log with consistent prefix
void adminLog(String message) {
  if (kDebugMode) {
    debugPrint('[AdminPanel] $message');
  }
}

/// Debug error log
void adminLogError(String message, dynamic error) {
  if (kDebugMode) {
    debugPrint('[AdminPanel] ❌ $message: $error');
  }
}

/// Debug success log
void adminLogSuccess(String message) {
  if (kDebugMode) {
    debugPrint('[AdminPanel] ✓ $message');
  }
}




