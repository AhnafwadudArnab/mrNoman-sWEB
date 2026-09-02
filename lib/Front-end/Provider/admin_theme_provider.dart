import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'admin_theme_mode';
  
  bool _isDarkMode = true;
  
  bool get isDarkMode => _isDarkMode;
  bool get isLightMode => !_isDarkMode;
  
  AdminThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? true;
      notifyListeners();
    } catch (_) {
      _isDarkMode = true;
    }
  }
  
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (_) {
      // Fallback
    }
  }
  
  Future<void> setDarkMode(bool dark) async {
    if (_isDarkMode == dark) return;
    try {
      _isDarkMode = dark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (_) {
      // Fallback
    }
  }
}
