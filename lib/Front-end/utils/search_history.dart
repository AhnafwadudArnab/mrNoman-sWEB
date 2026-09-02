import 'package:shared_preferences/shared_preferences.dart';

class SearchHistory {
  static const String _key = 'electrocity_search_history';
  static const int _maxItems = 10;

  /// Get search history
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    return history;
  }

  /// Add search query to history
  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];

    // Remove if already exists (to move to top)
    history.removeWhere((q) => q.toLowerCase() == query.toLowerCase());

    // Add to beginning
    history.insert(0, query.trim());

    // Keep only latest 10
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }

    await prefs.setStringList(_key, history);
  }

  /// Remove specific search from history
  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    history.removeWhere((q) => q.toLowerCase() == query.toLowerCase());
    await prefs.setStringList(_key, history);
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
