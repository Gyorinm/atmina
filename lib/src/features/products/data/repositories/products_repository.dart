import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/create_product_input.dart';
import '../../domain/models/product.dart';
import '../../application/product_image_picker.dart';
import '../datasources/app_database.dart';

class ProductsRepository {
  const ProductsRepository(this._database);

  final AppDatabase _database;

  Future<List<Product>> fetchProducts() {
    return _database.getAllProducts();
  }

  Future<Product> addProduct(CreateProductInput input) async {
    final now = DateTime.now();
    final internalCode = _generateInternalCode();
    final product = Product(
      name: input.name.trim(),
      price: input.price,
      barcode: internalCode,
      category: input.category.trim(),
      stockQuantity: input.stockQuantity,
      searchTerms: AppDatabase.buildSearchTerms(
        Product(
          name: input.name.trim(),
          price: input.price,
          barcode: internalCode,
          category: input.category.trim(),
          stockQuantity: input.stockQuantity,
          searchTerms: '',
          createdAt: now,
          updatedAt: now,
          variantLabel: input.variantLabel,
        ),
      ),
      createdAt: now,
      updatedAt: now,
      imagePath: input.imagePath,
      familyId: input.familyId,
      variantLabel: input.variantLabel,
    );

    try {
      return await _database.insertProduct(product);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        return addProduct(input);
      }
      throw const ProductSaveException('تعذر حفظ المنتج محليًا.');
    }
  }

  /// يضيف عدة منتجات دفعة واحدة (مثال: عدة أحجام لنفس المنتج تم
  /// اختيارها معًا). يعيد قائمة المنتجات المُنشأة بنفس الترتيب.
  Future<List<Product>> addProductsBatch(List<CreateProductInput> inputs) async {
    final results = <Product>[];
    for (final input in inputs) {
      results.add(await addProduct(input));
    }
    return results;
  }

  /// يحدّث كمية المخزون، ويحدّث السعر أيضًا إذا مُرِّر [price] (يبقى
  /// السعر كما هو إن تُرك null)، حتى يتمكن التاجر من تعديل الاثنين معًا
  /// من نفس النافذة.
  Future<Product> updateStock(
    Product product,
    int stockQuantity, {
    double? price,
  }) async {
    final updatedProduct = product.copyWith(
      stockQuantity: stockQuantity,
      price: price,
      updatedAt: DateTime.now(),
    );

    try {
      return await _database.updateProduct(updatedProduct);
    } on DatabaseException {
      throw const ProductSaveException('تعذر تحديث المنتج محليًا.');
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      await _database.deleteProduct(product);
      // لا نحذف الصورة إذا كانت موروثة من عائلة مشتركة مع منتجات أخرى.
      if (product.familyId == null) {
        await ProductImagePicker.deleteImage(product.imagePath);
      }
    } on DatabaseException {
      throw const ProductSaveException('تعذر حذف المنتج محليًا.');
    }
  }

  List<Product> filterProducts(List<Product> products, String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return products;
    }

    final scored = <({Product product, int score})>[];

    for (final product in products) {
      final normalizedName = _normalize(product.name);
      final normalizedCategory = _normalize(product.category);

      var score = 0;

      if (normalizedName.startsWith(normalizedQuery)) {
        score = 900;
      } else if (normalizedCategory.startsWith(normalizedQuery)) {
        score = 750;
      } else if (product.searchTerms.contains(normalizedQuery)) {
        final position = normalizedName.indexOf(normalizedQuery);
        score = 600 - (position < 0 ? 25 : position);
      } else if (_isSubsequenceMatch(normalizedQuery, normalizedName)) {
        score = 420;
      }

      if (score > 0) {
        scored.add((product: product, score: score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.product.name.compareTo(b.product.name);
    });

    return scored.map((item) => item.product).toList(growable: false);
  }

  static String _normalize(String value) {
    return AppDatabase.normalizeValue(value);
  }

  bool _isSubsequenceMatch(String query, String target) {
    if (query.isEmpty) {
      return true;
    }

    var qIndex = 0;
    for (var i = 0; i < target.length && qIndex < query.length; i++) {
      if (target[i] == query[qIndex]) {
        qIndex++;
      }
    }
    return qIndex == query.length;
  }

  static final Random _random = Random.secure();

  static String _generateInternalCode() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final salt = _random.nextInt(900000) + 100000;
    return 'sku-$timestamp-$salt';
  }
}

class ProductSaveException implements Exception {
  const ProductSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
