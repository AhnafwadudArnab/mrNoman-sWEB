import 'package:flutter/material.dart';

class AdminProductProvider extends ChangeNotifier {
  // প্রতিটি সেকশনের জন্য প্রোডাক্ট সংরক্ষণ
  final Map<String, List<Map<String, dynamic>>> _sectionProducts = {
    "Best Sellings": [],
    "Flash Sale": [],
    "Trending Items": [],
    "Deals of the Day": [],
    "Tech Part": [],
    "Collections": [],
    "Others": [],
  };

  static int _idCounter = 0;
  static String _nextId() => 'admin_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  // গেটার
  Map<String, List<Map<String, dynamic>>> get sectionProducts =>
      Map.unmodifiable(_sectionProducts);

  // প্রোডাক্ট যোগ করার মেথড (unique id অটো অ্যাড)
  void addProduct(String sectionTitle, Map<String, dynamic> product) {
    if (_sectionProducts.containsKey(sectionTitle)) {
      final data = Map<String, dynamic>.from(product);
      if (!data.containsKey('id')) data['id'] = _nextId();
      _sectionProducts[sectionTitle]!.add(data);
      notifyListeners();
    }
  }

  // প্রোডাক্ট আপডেট
  void updateProduct(String sectionTitle, int index, Map<String, dynamic> product) {
    final list = _sectionProducts[sectionTitle];
    if (list == null || index < 0 || index >= list.length) return;
    final data = Map<String, dynamic>.from(product);
    if (list[index].containsKey('id')) data['id'] = list[index]['id'];
    list[index] = data;
    notifyListeners();
  }

  // প্রোডাক্ট ডিলিট
  void removeProduct(String sectionTitle, int index) {
    final list = _sectionProducts[sectionTitle];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  // একটি সেকশনের সব প্রোডাক্ট পাওয়া
  List<Map<String, dynamic>> getProductsBySection(String sectionTitle) {
    return _sectionProducts[sectionTitle] ?? [];
  }

  // সব সেকশনের প্রোডাক্ট ক্লিয়ার করা (যদি needed)
  void clearAll() {
    _sectionProducts.forEach((key, value) {
      _sectionProducts[key] = [];
    });
    notifyListeners();
  }
}
