import 'package:flutter/material.dart';

class AdminProductProvider extends ChangeNotifier {
  // ??????? ??????? ???? ????????? ???????
  final Map<String, List<Map<String, dynamic>>> _sectionProducts = {
    "Best Sellings": [],
    "Flash_Sale": [],
    "Trending Items": [],
    "Deals of the Day": [],
    "Tech Part": [],
    "Collections": [],
    "Others": [],
  };

  static int _idCounter = 0;
  static String _nextId() => 'admin_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  // ?????
  Map<String, List<Map<String, dynamic>>> get sectionProducts =>
      Map.unmodifiable(_sectionProducts);

  // ????????? ??? ???? ???? (unique id ??? ?????)
  void addProduct(String sectionTitle, Map<String, dynamic> product) {
    if (_sectionProducts.containsKey(sectionTitle)) {
      final data = Map<String, dynamic>.from(product);
      if (!data.containsKey('id')) data['id'] = _nextId();
      _sectionProducts[sectionTitle]!.add(data);
      notifyListeners();
    }
  }

  // ????????? ?????
  void updateProduct(String sectionTitle, int index, Map<String, dynamic> product) {
    final list = _sectionProducts[sectionTitle];
    if (list == null || index < 0 || index >= list.length) return;
    final data = Map<String, dynamic>.from(product);
    if (list[index].containsKey('id')) data['id'] = list[index]['id'];
    list[index] = data;
    notifyListeners();
  }

  // ????????? ?????
  void removeProduct(String sectionTitle, int index) {
    final list = _sectionProducts[sectionTitle];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    notifyListeners();
  }

  // ???? ??????? ?? ????????? ?????
  List<Map<String, dynamic>> getProductsBySection(String sectionTitle) {
    return _sectionProducts[sectionTitle] ?? [];
  }

  // ?? ??????? ????????? ??????? ??? (??? needed)
  void clearAll() {
    _sectionProducts.forEach((key, value) {
      _sectionProducts[key] = [];
    });
    notifyListeners();
  }
}









