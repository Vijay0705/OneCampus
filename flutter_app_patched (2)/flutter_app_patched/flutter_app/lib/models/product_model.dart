class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final String condition;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final bool isSold;
  final String createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.condition,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.isSold,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      condition: json['condition'] ?? 'Good',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      sellerId: json['sellerId'] ?? json['seller'] ?? '',
      sellerName: json['sellerName'] ?? 'Unknown',
      isSold: json['isSold'] ?? json['sold'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}