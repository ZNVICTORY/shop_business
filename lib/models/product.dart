class Product {
  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.onShelf,
    this.imageEmoji = '📦',
  });

  final String id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final bool onShelf;
  final String imageEmoji;

  Product copyWith({
    String? name,
    String? sku,
    double? price,
    int? stock,
    bool? onShelf,
    String? imageEmoji,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      onShelf: onShelf ?? this.onShelf,
      imageEmoji: imageEmoji ?? this.imageEmoji,
    );
  }
}
