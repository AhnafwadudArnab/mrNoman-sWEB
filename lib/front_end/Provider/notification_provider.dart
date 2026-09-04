import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  
  int get unreadCount => _unreadCount;
  bool get hasNotifications => _unreadCount > 0;
  
  void addNotification() {
    _unreadCount++;
    notifyListeners();
  }
  
  void clearNotifications() {
    _unreadCount = 0;
    notifyListeners();
  }
  
  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}









