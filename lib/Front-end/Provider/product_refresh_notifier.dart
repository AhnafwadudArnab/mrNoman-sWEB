import 'package:flutter/foundation.dart';
import '../utils/api_service.dart';

/// Notifies all product section widgets to reload their data from the server.
/// Call [refresh()] after any admin create/update/delete operation.
class ProductRefreshNotifier extends ChangeNotifier {
  int _version = 0;

  /// Incremented each time a refresh is triggered.
  int get version => _version;

  /// Clears all product-related caches and signals widgets to reload.
  void refresh() {
    ApiService.invalidateCache('/products');
    ApiService.invalidateCache('/deals');
    ApiService.invalidateCache('/best_sellers');
    ApiService.invalidateCache('/trending');
    ApiService.invalidateCache('/tech_part');
    ApiService.invalidateCache('/flash_sales');
    _version++;
    notifyListeners();
  }
}
