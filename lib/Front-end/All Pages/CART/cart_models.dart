class CartItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String category;

  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.category,
  });

  double get itemTotal => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
    String? category,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'category': category,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String,
    quantity: (json['quantity'] as num).toInt(),
    category: json['category'] as String,
  );
}
