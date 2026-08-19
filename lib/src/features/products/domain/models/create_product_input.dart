class CreateProductInput {
  const CreateProductInput({
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.imagePath,
    this.familyId,
    this.variantLabel,
  });

  final String name;
  final String category;
  final double price;
  final int stockQuantity;

  /// مسار صورة خاصة بهذا المنتج (اختياري)، تُستخدم فقط إذا لم يكن
  /// المنتج مرتبطًا بعائلة تملك صورتها الخاصة.
  final String? imagePath;

  /// عائلة المنتج التي ينتمي إليها هذا الحجم/النوع (اختياري).
  final int? familyId;

  /// تسمية الحجم/الوزن (مثال: "1 لتر"، "5 كغ") منفصلة عن الاسم.
  final String? variantLabel;
}
