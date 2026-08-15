class CreateProductInput {
  const CreateProductInput({
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
  });

  final String name;
  final String category;
  final double price;
  final int stockQuantity;
}
