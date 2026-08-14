import 'package:sqflite/sqflite.dart';

import '../../domain/models/create_product_input.dart';
import '../../domain/models/product.dart';
import '../datasources/app_database.dart';

class ProductsRepository {
  const ProductsRepository(this._database);

  final AppDatabase _database;

  Future<List<Product>> fetchProducts() {
    return _database.getAllProducts();
  }

  Future<Product> addProduct(CreateProductInput input) async {
    final now = DateTime.now();
    final product = Product(
      name: input.name.trim(),
      price: input.price,
      barcode: input.barcode.trim(),
      category: input.category.trim(),
      stockQuantity: input.stockQuantity,
      searchTerms: AppDatabase.buildSearchTerms(
        Product(
          name: input.name.trim(),
          price: input.price,
          barcode: input.barcode.trim(),
          category: input.category.trim(),
          stockQuantity: input.stockQuantity,
          searchTerms: '',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      createdAt: now,
      updatedAt: now,
    );

    try {
      return await _database.insertProduct(product);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const ProductSaveException('الباركود مستخدم بالفعل لمنتج آخر.');
      }
      throw const ProductSaveException('تعذر حفظ المنتج محليًا.');
    }
  }

  Future<Product> updateStock(Product product, int stockQuantity) async {
    final updatedProduct = product.copyWith(
      stockQuantity: stockQuantity,
      updatedAt: DateTime.now(),
    );

    try {
      return await _database.updateProduct(updatedProduct);
    } on DatabaseException {
      throw const ProductSaveException('تعذر تحديث كمية المخزون محليًا.');
    }
  }

  Future<void> deleteProduct(Product product) async {
    try {
      await _database.deleteProduct(product);
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
      final normalizedBarcode = _normalize(product.barcode);

      var score = 0;

      if (normalizedBarcode == normalizedQuery) {
        score = 1100;
      } else if (normalizedName.startsWith(normalizedQuery)) {
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
}

class ProductSaveException implements Exception {
  const ProductSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
