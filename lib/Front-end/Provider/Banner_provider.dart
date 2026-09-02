import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_service.dart';

class BannerProvider extends ChangeNotifier {
  static const String _keyHero = 'electrocity_banner_hero';
  static const String _keyMid = 'electrocity_banner_mid';
  static const String _keySidebar = 'electrocity_banner_sidebar';
  static const String _keyFeatured = 'electrocity_featured_brands';
  static const String _keyOffers = 'electrocity_offers_90';

  List<Map<String, String>> _heroSlides = [];
  List<Map<String, String>> _midBanners = [];
  Map<String, String> _sidebarPromo = {};
  List<String> _featuredBrands = [];
  List<Map<String, String>> _offers90 = [];

  List<Map<String, String>> get heroSlides => List.unmodifiable(_heroSlides);
  List<Map<String, String>> get midBanners => List.unmodifiable(_midBanners);
  Map<String, String> get sidebarPromo => Map.unmodifiable(_sidebarPromo);
  List<String> get featuredBrands => List.unmodifiable(_featuredBrands);
  List<Map<String, String>> get offers90 => List.unmodifiable(_offers90);

  bool _loaded = false;
  bool _isLoading = false; // prevent concurrent loads
  DateTime? _lastLoadedAt;
  String? _error;
  static const Duration _reloadInterval = Duration(minutes: 10); // reduced from 30min
  bool get loaded => _loaded;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<String, String> _toHeroEntry(dynamic e) {
    final m = Map<String, dynamic>.from((e as Map));
    final rawImage = (m['image'] ?? m['img'] ?? '').toString();
    return {
      'image': rawImage,
      'img': rawImage,
      'label': (m['label'] ?? m['title'] ?? '').toString(),
      'link': (m['link'] ?? '').toString(),
    };
  }

  Map<String, String> _toMidEntry(dynamic e) {
    final m = Map<String, dynamic>.from((e as Map));
    final rawImage = (m['img'] ?? m['image'] ?? '').toString();
    return {
      'img': rawImage,
      'image': rawImage,
      'link': (m['link'] ?? '').toString(),
      'title': (m['title'] ?? '').toString(),
    };
  }

  Map<String, String> _toSidebarEntry(dynamic e) {
    final m = Map<String, dynamic>.from((e as Map));
    final productIdsRaw = m['productIds'];
    final productIds = productIdsRaw is List
        ? productIdsRaw.map((id) => id.toString()).where((id) => id.isNotEmpty)
        : const <String>[];
    return {
      'title': (m['title'] ?? 'FLASH SALE').toString(),
      'subtitle': (m['subtitle'] ?? m['description'] ?? '').toString(),
      'buttonText': (m['buttonText'] ?? 'VIEW ALL').toString(),
      'image': (m['image'] ?? m['img'] ?? '').toString(),
      'link': (m['link'] ?? '').toString(),
      'source': (m['source'] ?? m['page'] ?? 'flash-sale').toString(),
      'page': (m['page'] ?? m['source'] ?? 'flash-sale').toString(),
      'productIds': productIds.join(','),
    };
  }

  Future<void> load({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _loaded && _lastLoadedAt != null) {
      if (now.difference(_lastLoadedAt!) < _reloadInterval) return;
    }
    // Prevent concurrent API calls
    if (_isLoading) return;
    _isLoading = true;
    try {
      ApiService.invalidateCache('/banners');
      final raw = await ApiService.get('/banners', withAuth: false);
      final data = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final hero = (data['hero'] is List)
          ? (data['hero'] as List)
          : <dynamic>[];
      final mid = (data['mid'] is List) ? (data['mid'] as List) : <dynamic>[];
      final sidebarRaw = data['sidebar'];

      final parsedHero = hero
          .map(_toHeroEntry)
          .where((e) => (e['image'] ?? '').isNotEmpty)
          .toList();
      final parsedMid = mid
          .map(_toMidEntry)
          .where((e) => (e['img'] ?? '').isNotEmpty)
          .toList();

      // Always update from server response (even if empty — user may have deleted all)
      _heroSlides = parsedHero;
      _midBanners = parsedMid;

      if (sidebarRaw is Map) {
        _sidebarPromo = _toSidebarEntry(sidebarRaw);
      } else if (sidebarRaw is List && (sidebarRaw as List).isNotEmpty) {
        _sidebarPromo = _toSidebarEntry(sidebarRaw.first);
      }

      _error = null;
      _lastLoadedAt = now;

      // Cache locally for offline use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHero, jsonEncode(_heroSlides));
      await prefs.setString(_keyMid, jsonEncode(_midBanners));
      await prefs.setString(_keySidebar, jsonEncode(_sidebarPromo));
    } catch (e) {
      // Try local cache before falling back to empty state
      bool restoredFromCache = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final heroJson = prefs.getString(_keyHero);
        final midJson = prefs.getString(_keyMid);
        final sidebarJson = prefs.getString(_keySidebar);

        if (heroJson != null) {
          _heroSlides = (jsonDecode(heroJson) as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
          restoredFromCache = true;
        }
        if (midJson != null) {
          _midBanners = (jsonDecode(midJson) as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
        if (sidebarJson != null) {
          _sidebarPromo = Map<String, String>.from(
            jsonDecode(sidebarJson) as Map,
          );
        }
      } catch (_) {}

      if (!restoredFromCache) {
        // No cached data and API failed — show empty state
        _error = 'Failed to load banners. Please check your connection.';
      }
    } finally {
      _isLoading = false;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<bool> saveHero(List<Map<String, String>> slides) async {
    final previous = List<Map<String, String>>.from(_heroSlides);
    _heroSlides = List.from(slides);
    notifyListeners();
    try {
      ApiService.invalidateCache('/banners');
      await ApiService.put('/banners', {'hero': _heroSlides});
      _lastLoadedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyHero, jsonEncode(_heroSlides));
      return true;
    } catch (e) {
      _heroSlides = previous;
      _error = 'Failed to save hero banners: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveMid(List<Map<String, String>> banners) async {
    final previous = List<Map<String, String>>.from(_midBanners);
    _midBanners = List.from(banners);
    notifyListeners();
    try {
      ApiService.invalidateCache('/banners');
      await ApiService.put('/banners', {'mid': _midBanners});
      _lastLoadedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyMid, jsonEncode(_midBanners));
      return true;
    } catch (e) {
      _midBanners = previous;
      _error = 'Failed to save mid banners: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSidebarPromo(Map<String, String> promo) async {
    final previous = Map<String, String>.from(_sidebarPromo);
    _sidebarPromo = Map.from(promo);
    notifyListeners();
    try {
      ApiService.invalidateCache('/banners');
      await ApiService.put('/banners', {'sidebar': _sidebarPromo});
      _lastLoadedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySidebar, jsonEncode(_sidebarPromo));
      return true;
    } catch (e) {
      _sidebarPromo = previous;
      _error = 'Failed to save sidebar promo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  String get sidebarTitle => _sidebarPromo['title'] ?? '';
  String get sidebarSubtitle => _sidebarPromo['subtitle'] ?? '';
  String get sidebarButtonText => _sidebarPromo['buttonText'] ?? 'VIEW ALL';
  String get sidebarSource => _sidebarPromo['source'] ?? 'flash-sale';
  List<String> get sidebarProductIds => (_sidebarPromo['productIds'] ?? '')
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList();

  Future<bool> saveFeaturedBrands(List<String> logos) async {
    final previous = List<String>.from(_featuredBrands);
    _featuredBrands = List.from(logos);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFeatured, jsonEncode(_featuredBrands));
      return true;
    } catch (e) {
      _featuredBrands = previous;
      _error = 'Failed to save featured brands: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveOffers90(List<Map<String, String>> offers) async {
    final previous = List<Map<String, String>>.from(_offers90);
    _offers90 = List.from(offers);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyOffers, jsonEncode(_offers90));
      return true;
    } catch (e) {
      _offers90 = previous;
      _error = 'Failed to save offers: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
