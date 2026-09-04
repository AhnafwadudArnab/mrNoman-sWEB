import 'package:flutter/foundation.dart';

/// Signals to all widgets when the API base URL has been resolved and
/// it is safe to fire the first network requests.
class ApiReadyNotifier extends ChangeNotifier {
  bool _isReady = false;

  bool get isReady => _isReady;

  void markReady() {
    if (_isReady) return;
    _isReady = true;
    notifyListeners();
  }
}









