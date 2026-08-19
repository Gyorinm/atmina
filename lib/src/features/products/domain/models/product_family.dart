import '../../data/moroccan_grocery_presets.dart' show MeasurementUnit;

export '../../data/moroccan_grocery_presets.dart' show MeasurementUnit;

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
    this.imageExportedAt,
    this.measurementUnit = MeasurementUnit.none,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String category;
  final String? imagePath;

  /// تاريخ آخر رفع ناجح للصورة إلى الخادم (null يعني أنها لم تُصدَّر
  /// بعد، أو أن الصورة المحلية تغيّرت منذ آخر تصدير).
  final DateTime? imageExportedAt;

  /// نوع القياس لهذا المنتج (بدون / لتر / كيلوغرام)، يحدد ما إذا كان
  /// التاجر سيرى قائمة اختيار الأحجام المتوفرة عند إضافة منتج من
  /// هذه العائلة.
  final MeasurementUnit measurementUnit;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExportedToServer => imageExportedAt != null;
  bool get isMeasurable => measurementUnit != MeasurementUnit.none;

  ProductFamily copyWith({
    int? id,
    String? name,
    String? category,
    String? imagePath,
    bool clearImagePath = false,
    DateTime? imageExportedAt,
    bool clearImageExportedAt = false,
    MeasurementUnit? measurementUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductFamily(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      imageExportedAt: clearImageExportedAt ? null : (imageExportedAt ?? this.imageExportedAt),
      measurementUnit: measurementUnit ?? this.measurementUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductFamily.fromMap(Map<String, Object?> map) {
    final exportedRaw = map['image_exported_at'] as String?;
    return ProductFamily(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      imagePath: map['image_path'] as String?,
      imageExportedAt: exportedRaw == null ? null : DateTime.parse(exportedRaw),
      measurementUnit: MeasurementUnit.fromStorage(map['measurement_unit'] as String?),
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
      'image_exported_at': imageExportedAt?.toIso8601String(),
      'measurement_unit': measurementUnit.storageValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
