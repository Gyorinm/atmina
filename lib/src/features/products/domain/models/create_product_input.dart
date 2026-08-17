class CreateProductInput {
  const CreateProductInput({
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.imagePath,
  });

  final String name;
  final String category;
  final double price;
  final int stockQuantity;

  /// مسار الصورة المحلية المضغوطة (اختياري).
  final String? imagePath;
}
