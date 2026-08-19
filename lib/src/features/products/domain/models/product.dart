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
    this.imagePath,
    this.familyId,
    this.variantLabel,
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

  /// المسار المحلي لصورة المنتج المضغوطة (اختياري). إذا كان فارغًا
  /// وكان المنتج مرتبطًا بـ[familyId]، تُستخدم صورة العائلة بدلًا منه.
  final String? imagePath;

  /// معرّف "عائلة المنتج" التي ينتمي إليها هذا المنتج (مثال: كل
  /// أحجام ماء سيدي علي تنتمي لعائلة واحدة تحمل صورة واحدة).
  final int? familyId;

  /// تسمية الحجم/الوزن الخاصة بهذا المتغيّر (مثال: "1 لتر"، "5 كغ").
  /// منفصلة عن [name] حتى يبقى اسم المنتج نظيفًا (اسم العائلة فقط)
  /// ويسهل تجميع المتغيّرات معًا في كتالوج الزبون.
  final String? variantLabel;

  /// الاسم الكامل المعروض (يدمج اسم المنتج مع تسمية الحجم إن وُجدت).
  String get displayName => variantLabel == null || variantLabel!.isEmpty ? name : '$name - $variantLabel';

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
    String? imagePath,
    bool clearImagePath = false,
    int? familyId,
    bool clearFamilyId = false,
    String? variantLabel,
    bool clearVariantLabel = false,
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
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      familyId: clearFamilyId ? null : (familyId ?? this.familyId),
      variantLabel: clearVariantLabel ? null : (variantLabel ?? this.variantLabel),
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
      imagePath: map['image_path'] as String?,
      familyId: (map['family_id'] as num?)?.toInt(),
      variantLabel: map['variant_label'] as String?,
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
      'image_path': imagePath,
      'family_id': familyId,
      'variant_label': variantLabel,
    };
  }
}
