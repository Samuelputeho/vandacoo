class ProductEntity {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double salePrice;
  final String description;
  final String shopName;
  final String category;

  ProductEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.salePrice,
    required this.description,
    required this.shopName,
    required this.category,
  });
}
