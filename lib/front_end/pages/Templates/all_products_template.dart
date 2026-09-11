class ProductData {
  final String id;
  final String name;
  final String category;
  final double priceBDT;
  final double? regularPrice;
  final List<String> images;
  final String description;
  final Map<String, String> additionalInfo;

  ProductData({
    required this.id,
    required this.name,
    required this.category,
    required this.priceBDT,
    this.regularPrice,
    required this.images,
    required this.description,
    required this.additionalInfo,
  });

  // Helper to get formatted price anywhere in the app
  String get formattedPrice => "Tk ${priceBDT.toStringAsFixed(0)}";
}









