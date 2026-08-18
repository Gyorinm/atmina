/// "عائلة منتج" تمثل منتجًا أساسيًا واحدًا (مثال: ماء سيدي علي) قد
/// يُباع بعدة أحجام مختلفة (1 لتر، نصف لتر، صغير...). كل عائلة تحمل
/// صورة واحدة فقط تُستخدم لكل الأحجام المنبثقة عنها تلقائيًا، فلا
/// حاجة لتصوير كل حجم على حدة.
class ProductFamily {
  const ProductFamily({
    this.id,
    required this.name,
    required this.category,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String category;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductFamily copyWith({
    int? id,
    String? name,
    String? category,
    String? imagePath,
    bool clearImagePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductFamily(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductFamily.fromMap(Map<String, Object?> map) {
    return ProductFamily(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
