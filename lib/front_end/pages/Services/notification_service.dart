import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// flutter_local_notifications is not supported on web
// All notification calls are no-ops on web
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return; // Not supported on web
    if (_initialized) return;
    _initialized = true;
    debugPrint('? Notifications skipped on web');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    if (kIsWeb) return;
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    if (kIsWeb) return;
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('push_notifications_enabled') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', enabled);
  }

  Future<void> showOrderNotification({
    required String orderId,
    required String status,
    required String message,
  }) async {
    if (kIsWeb) return;
    await showNotification(
      title: 'Order Update',
      body: message,
      data: {'type': 'order', 'order_id': orderId, 'status': status},
    );
  }

  Future<void> showPromotionNotification({
    required String title,
    required String message,
    String? promotionId,
  }) async {
    if (kIsWeb) return;
    await showNotification(
      title: title,
      body: message,
      data: {'type': 'promotion', 'promotion_id': promotionId},
    );
  }

  Future<void> showFlashSaleNotification({
    required String title,
    required String message,
    String? flashSaleId,
  }) async {
    if (kIsWeb) return;
    await showNotification(
      title: title,
      body: message,
      data: {'type': 'Flash_Sale', 'Flash_Sale_id': flashSaleId},
    );
  }
}









