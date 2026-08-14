import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/product.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'atmina_pos.db';
  static const int _databaseVersion = 3;
  static const List<String> _legacySeedBarcodes = <String>[
    '628100000001',
    '628100000002',
    '628100000003',
    '628100000004',
    '628100000005',
    '628100000006',
    '628100000007',
    '628100000008',
    '628100000009',
    '628100000010',
  ];

  static const String productsTable = 'products';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $productsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        barcode TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
        search_terms TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_search ON $productsTable(search_terms)',
    );
    await db.execute(
      'CREATE INDEX idx_products_barcode ON $productsTable(barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_products_category ON $productsTable(category)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $productsTable ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await _removeLegacySeedProducts(db);
    }
  }

  Future<void> upsertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        productsTable,
        product.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert(
      productsTable,
      product.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return product.copyWith(id: id);
  }

  Future<Product> updateProduct(Product product) async {
    final db = await database;
    final values = product.toMap()..remove('id');

    if (product.id != null) {
      await db.update(
        productsTable,
        values,
        where: 'id = ?',
        whereArgs: [product.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return product;
    }

    await db.update(
      productsTable,
      values,
      where: 'barcode = ?',
      whereArgs: [product.barcode],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return product;
  }

  Future<void> deleteProduct(Product product) async {
    final db = await database;

    if (product.id != null) {
      await db.delete(
        productsTable,
        where: 'id = ?',
        whereArgs: [product.id],
      );
      return;
    }

    await db.delete(
      productsTable,
      where: 'barcode = ?',
      whereArgs: [product.barcode],
    );
  }

  /// Replaces the whole catalogue with [products] inside a single transaction.
  Future<void> replaceAllProducts(List<Product> products) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(productsTable);

      final batch = txn.batch();
      for (final product in products) {
        batch.insert(
          productsTable,
          product.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query(
      productsTable,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Product.fromMap).toList(growable: false);
  }

  Future<void> _removeLegacySeedProducts(Database db) async {
    final placeholders = List<String>.filled(
      _legacySeedBarcodes.length,
      '?',
    ).join(', ');

    await db.delete(
      productsTable,
      where: 'barcode IN ($placeholders)',
      whereArgs: _legacySeedBarcodes,
    );
  }

  static String buildSearchTerms(Product product) {
    return _buildSearchTerms(product.name, product.category, product.barcode);
  }

  static String _buildSearchTerms(
      String name, String category, String barcode) {
    final normalizedName = normalizeValue(name);
    final normalizedCategory = normalizeValue(category);
    final parts = {
      ...normalizedName.split(' '),
      ...normalizedCategory.split(' ')
    };
    final prefixes = <String>{
      normalizedName,
      normalizedCategory,
      normalizeValue(barcode),
      ...parts,
    };

    for (final part in parts) {
      for (var i = 1; i <= part.length; i++) {
        prefixes.add(part.substring(0, i));
      }
    }

    return prefixes.join(' ');
  }

  static String normalizeValue(String value) {
    const arabicVariants = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ة': 'ه',
      'ى': 'ي',
      'ؤ': 'و',
      'ئ': 'ي',
    };

    var result = value.trim().toLowerCase();
    arabicVariants.forEach((key, replacement) {
      result = result.replaceAll(key, replacement);
    });

    result = result.replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]+'), ' ');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
