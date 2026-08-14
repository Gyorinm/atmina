class Product {
  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.barcode,
    required this.category,
    required this.stockQuantity,
    required this.searchTerms,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final double price;
  final String barcode;
  final String category;
  final int stockQuantity;
  final String searchTerms;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? barcode,
    String? category,
    int? stockQuantity,
    String? searchTerms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      searchTerms: searchTerms ?? this.searchTerms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      barcode: map['barcode'] as String,
      category: map['category'] as String,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      searchTerms: map['search_terms'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'barcode': barcode,
      'category': category,
      'stock_quantity': stockQuantity,
      'search_terms': searchTerms,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
