import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/product.dart';
import '../../domain/models/product_family.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'atmina_pos.db';
  static const int _databaseVersion = 6;
  static const List<String> _legacySeedBarcodes = <String>[
    '628100000001','628100000002','628100000003','628100000004','628100000005',
    '628100000006','628100000007','628100000008','628100000009','628100000010',
  ];

  static const String productsTable = 'products';
  static const String productFamiliesTable = 'product_families';
  static const String ordersTable = 'orders';
  static const String orderItemsTable = 'order_items';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createProductsTable(db);
    await _createOrdersTables(db);
    await _createProductFamiliesTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $productsTable ADD COLUMN stock_quantity INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) await _removeLegacySeedProducts(db);
    if (oldVersion < 4) await _createOrdersTables(db);
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE $productsTable ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 6) {
      await _createProductFamiliesTable(db);
      await db.execute('ALTER TABLE $productsTable ADD COLUMN family_id INTEGER');
    }
  }

  Future<void> _createProductsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $productsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        barcode TEXT NOT NULL UNIQUE,
        category TEXT NOT NULL,
        stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK(stock_quantity >= 0),
        search_terms TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        image_path TEXT,
        family_id INTEGER
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_search ON $productsTable(search_terms)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON $productsTable(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON $productsTable(category)');
  }

  Future<void> _createProductFamiliesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $productFamiliesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_families_category ON $productFamiliesTable(category)');
  }

  Future<void> _createOrdersTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $ordersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_code TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        received REAL NOT NULL DEFAULT 0,
        change_due REAL NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'sale',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $orderItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_barcode TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        collected_quantity INTEGER NOT NULL DEFAULT 0 CHECK(collected_quantity >= 0),
        FOREIGN KEY(order_id) REFERENCES $ordersTable(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_created ON $ordersTable(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_order_items_order ON $orderItemsTable(order_id)');
  }

  Future<void> upsertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert(productsTable, product.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert(productsTable, product.toMap()..remove('id'), conflictAlgorithm: ConflictAlgorithm.abort);
    return product.copyWith(id: id);
  }

  Future<Product> updateProduct(Product product) async {
    final db = await database;
    final values = product.toMap()..remove('id');
    final updated = product.id != null
        ? await db.update(productsTable, values, where: 'id = ?', whereArgs: [product.id], conflictAlgorithm: ConflictAlgorithm.abort)
        : await db.update(productsTable, values, where: 'barcode = ?', whereArgs: [product.barcode], conflictAlgorithm: ConflictAlgorithm.abort);
    if (updated == 0) throw StateError('المنتج غير موجود.');
    return product;
  }

  Future<void> deleteProduct(Product product) async {
    final db = await database;
    await db.delete(productsTable, where: product.id != null ? 'id = ?' : 'barcode = ?', whereArgs: [product.id ?? product.barcode]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final rows = await db.query(productsTable, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Product.fromMap).toList(growable: false);
  }

  Future<Product?> findProductByBarcode(String barcode) async {
    final db = await database;
    final rows = await db.query(productsTable, where: 'barcode = ?', whereArgs: [barcode], limit: 1);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<List<Map<String, dynamic>>> getOrders({String? source}) async {
    final db = await database;
    return db.query(
      ordersTable,
      where: source == null ? null : 'source = ?',
      whereArgs: source == null ? null : [source],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrderItems(int orderId) async {
    final db = await database;
    return db.query(orderItemsTable, where: 'order_id = ?', whereArgs: [orderId], orderBy: 'id ASC');
  }

  Future<void> markOrderCollected(int orderId, int collectedQuantity) async {
    final db = await database;
    await db.update(ordersTable, {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [orderId]);
    await db.update(orderItemsTable, {'collected_quantity': collectedQuantity.clamp(0, 1 << 30)}, where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<int> createOrder({
    required String orderCode,
    required String status,
    required double subtotal,
    required double discount,
    required double total,
    required double received,
    required double changeDue,
    required String source,
    required List<Map<String, dynamic>> items,
    bool deductStock = false,
  }) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      if (items.isEmpty) throw StateError('لا يمكن إنشاء طلب بدون منتجات.');

      if (deductStock) {
        for (final item in items) {
          final barcode = item['product_barcode'] as String;
          final quantity = item['quantity'] as int;
          if (quantity <= 0) throw StateError('كمية غير صالحة للمنتج $barcode.');
          final rows = await txn.query(productsTable, columns: ['id','stock_quantity'], where: 'barcode = ?', whereArgs: [barcode], limit: 1);
          if (rows.isEmpty) throw StateError('المنتج $barcode غير موجود.');
          final stock = (rows.first['stock_quantity'] as num).toInt();
          if (stock < quantity) throw StateError('المخزون غير كافٍ للمنتج $barcode.');
          await txn.update(productsTable, {'stock_quantity': stock - quantity, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [rows.first['id']]);
        }
      }

      final now = DateTime.now().toIso8601String();
      final orderId = await txn.insert(ordersTable, {
        'order_code': orderCode,
        'status': status,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'received': received,
        'change_due': changeDue,
        'source': source,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      final batch = txn.batch();
      for (final item in items) {
        final quantity = (item['quantity'] as num).toInt();
        final collected = (item['collected_quantity'] as num?)?.toInt() ?? 0;
        batch.insert(orderItemsTable, {
          'order_id': orderId,
          'product_barcode': item['product_barcode'],
          'product_name': item['product_name'],
          'unit_price': item['unit_price'],
          'quantity': quantity,
          'collected_quantity': collected.clamp(0, quantity),
        });
      }
      await batch.commit(noResult: true);
      return orderId;
    });
  }

  Future<Map<String, dynamic>> exportBackup() async {
    final db = await database;
    return {
      'format': 'atmina-backup',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'products': await db.query(productsTable),
      'orders': await db.query(ordersTable),
      'order_items': await db.query(orderItemsTable),
    };
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    if (backup['format'] != 'atmina-backup' || backup['version'] is! int) {
      throw const FormatException('ملف النسخة الاحتياطية غير صالح.');
    }

    final rawProducts = backup['products'];
    final rawOrders = backup['orders'];
    final rawItems = backup['order_items'];
    if (rawProducts is! List || rawOrders is! List || rawItems is! List) {
      throw const FormatException('بيانات النسخة الاحتياطية ناقصة أو غير صالحة.');
    }

    final products = rawProducts.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);
    final orders = rawOrders.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);
    final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList(growable: false);

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(orderItemsTable);
      await txn.delete(ordersTable);
      await txn.delete(productsTable);
      final batch = txn.batch();
      for (final row in products) {
        batch.insert(productsTable, row);
      }
      for (final row in orders) {
        batch.insert(ordersTable, row);
      }
      for (final row in items) {
        batch.insert(orderItemsTable, row);
      }
      await batch.commit(noResult: true);
    });
  }

  // ===== Product families =====

  Future<List<ProductFamily>> getAllProductFamilies() async {
    final db = await database;
    final rows = await db.query(productFamiliesTable, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(ProductFamily.fromMap).toList(growable: false);
  }

  Future<int> countProductFamilies() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $productFamiliesTable');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<ProductFamily> insertProductFamily(ProductFamily family) async {
    final db = await database;
    final id = await db.insert(productFamiliesTable, family.toMap()..remove('id'));
    return family.copyWith(id: id);
  }

  Future<void> insertProductFamiliesBatch(List<ProductFamily> families) async {
    final db = await database;
    final batch = db.batch();
    for (final family in families) {
      batch.insert(productFamiliesTable, family.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<ProductFamily> updateProductFamily(ProductFamily family) async {
    final db = await database;
    final updated = await db.update(
      productFamiliesTable,
      family.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [family.id],
    );
    if (updated == 0) throw StateError('عائلة المنتج غير موجودة.');
    return family;
  }

  Future<void> deleteProductFamily(int familyId) async {
    final db = await database;
    await db.transaction((txn) async {
      // فك ارتباط أي منتجات كانت تابعة لهذه العائلة قبل حذفها.
      await txn.update(productsTable, {'family_id': null}, where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete(productFamiliesTable, where: 'id = ?', whereArgs: [familyId]);
    });
  }


    final placeholders = List<String>.filled(_legacySeedBarcodes.length, '?').join(', ');
    await db.delete(productsTable, where: 'barcode IN ($placeholders)', whereArgs: _legacySeedBarcodes);
  }

  static String buildSearchTerms(Product product) => _buildSearchTerms(product.name, product.category, product.barcode);

  static String _buildSearchTerms(String name, String category, String barcode) {
    final normalizedName = normalizeValue(name);
    final normalizedCategory = normalizeValue(category);
    final parts = {...normalizedName.split(' '), ...normalizedCategory.split(' ')};
    final prefixes = <String>{normalizedName, normalizedCategory, normalizeValue(barcode), ...parts};
    for (final part in parts) {
      for (var i = 1; i <= part.length; i++) {
        prefixes.add(part.substring(0, i));
      }
    }
    return prefixes.join(' ');
  }

  static String normalizeValue(String value) {
    const arabicVariants = {'أ': 'ا','إ': 'ا','آ': 'ا','ة': 'ه','ى': 'ي','ؤ': 'و','ئ': 'ي'};
    var result = value.trim().toLowerCase();
    arabicVariants.forEach((key, replacement) => result = result.replaceAll(key, replacement));
    result = result.replaceAll(RegExp(r'[^0-9a-zA-Z\u0600-\u06FF\s]+'), ' ');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}