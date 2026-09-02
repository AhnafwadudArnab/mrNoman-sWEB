class ProductData {
  final String id;
  final String name;
  final String category;
  final double priceBDT;
  final List<String> images;
  final String description;
  final Map<String, String> additionalInfo;

  ProductData({
    required this.id,
    required this.name,
    required this.category,
    required this.priceBDT,
    required this.images,
    required this.description,
    required this.additionalInfo,
  });

  // Helper to get formatted price anywhere in the app
  String get formattedPrice => "৳ ${priceBDT.toStringAsFixed(0)}";
}
