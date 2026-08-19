import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/application/store_api_service.dart';
import '../../store/application/store_profile_controller.dart';
import '../../store/application/store_service.dart';
import '../data/datasources/app_database.dart';
import '../data/repositories/product_families_repository.dart';
import '../data/repositories/products_repository.dart';
import '../domain/models/create_product_input.dart';
import '../domain/models/product.dart';
import '../domain/models/product_family.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(appDatabaseProvider));
});

final productFamiliesRepositoryProvider = Provider<ProductFamiliesRepository>((ref) {
  return ProductFamiliesRepository(ref.watch(appDatabaseProvider));
});

final productFamiliesControllerProvider =
    AsyncNotifierProvider<ProductFamiliesController, List<ProductFamily>>(
  ProductFamiliesController.new,
);

/// خريطة سريعة من معرّف العائلة إلى العائلة نفسها، لاستخدامها عند
/// عرض صورة موروثة من العائلة على بطاقة منتج معيّن.
final productFamiliesByIdProvider = Provider<Map<int, ProductFamily>>((ref) {
  final families = ref.watch(productFamiliesControllerProvider).valueOrNull ?? const <ProductFamily>[];
  return {for (final family in families) if (family.id != null) family.id!: family};
});

class ProductFamiliesController extends AsyncNotifier<List<ProductFamily>> {
  @override
  Future<List<ProductFamily>> build() async {
    final repository = ref.watch(productFamiliesRepositoryProvider);
    return repository.fetchFamilies();
  }

  Future<ProductFamily> addFamily({
    required String name,
    required String category,
    String? imagePath,
    MeasurementUnit measurementUnit = MeasurementUnit.none,
  }) async {
    final repository = ref.read(productFamiliesRepositoryProvider);
    final family = await repository.addFamily(
      name: name,
      category: category,
      imagePath: imagePath,
      measurementUnit: measurementUnit,
    );

    final current = state.valueOrNull ?? await build();
    final updated = [...current, family]..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updated);
    return family;
  }

  Future<ProductFamily> updateFamilyImage(ProductFamily family, String? newImagePath) async {
    final repository = ref.read(productFamiliesRepositoryProvider);
    final updatedFamily = await repository.updateFamilyImage(family, newImagePath);

    final current = state.valueOrNull ?? await build();
    final updated = current.map((f) => f.id == updatedFamily.id ? updatedFamily : f).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updated);
    return updatedFamily;
  }

  Future<void> deleteFamily(ProductFamily family) async {
    final repository = ref.read(productFamiliesRepositoryProvider);
    await repository.deleteFamily(family);

    final current = state.valueOrNull ?? await build();
    final updated = current.where((f) => f.id != family.id).toList();
    state = AsyncData(updated);
  }

  /// يرفع صورة عائلة منتج محلية إلى الخادم لتصبح مرئية للزبائن.
  /// يتطلب أن يملك المنتج معرّفًا (id) وصورة محلية محفوظة مسبقًا.
  Future<void> uploadImageToServer({
    required ProductFamily family,
    required String storeCode,
    required String secret,
  }) async {
    if (family.id == null) throw StateError('لا يمكن رفع صورة لمنتج غير محفوظ بعد.');
    if (family.imagePath == null) throw StateError('لا توجد صورة محلية لهذا المنتج بعد.');

    final bytes = await File(family.imagePath!).readAsBytes();
    final base64Image = base64Encode(bytes);

    await StoreApiService().uploadFamilyImage(
      storeCode: storeCode,
      secret: secret,
      familyId: family.id!,
      base64Image: base64Image,
    );

    // نُعلّم العائلة محليًا كـ"مُصدَّرة" ليظهر مؤشر النجاح في الحال.
    final repository = ref.read(productFamiliesRepositoryProvider);
    final updatedFamily = await repository.markImageExported(family);
    final current = state.valueOrNull ?? await build();
    final updatedList = current.map((f) => f.id == updatedFamily.id ? updatedFamily : f).toList();
    state = AsyncData(updatedList);
  }

  /// يحذف صورة عائلة منتج من الخادم فقط (تبقى الصورة المحلية كما هي).
  Future<void> deleteImageFromServer({
    required ProductFamily family,
    required String storeCode,
    required String secret,
  }) async {
    if (family.id == null) return;
    await StoreApiService().deleteFamilyImage(storeCode: storeCode, secret: secret, familyId: family.id!);
  }
}

final productSearchQueryProvider = StateProvider<String>((ref) => '');

final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, List<Product>>(
  ProductsController.new,
);

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsControllerProvider);
  final query = ref.watch(productSearchQueryProvider);
  final repository = ref.watch(productsRepositoryProvider);

  return products.whenData((list) => repository.filterProducts(list, query));
});

final outOfStockProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsControllerProvider);
  return products.whenData(
    (items) => items.where((product) => product.stockQuantity <= 0).toList(),
  );
});

final lowStockProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsControllerProvider);
  return products.whenData(
    (items) => items
        .where(
          (product) => product.stockQuantity > 0 && product.stockQuantity <= 5,
        )
        .toList(),
  );
});

class ProductsController extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(productsRepositoryProvider);
    return repository.fetchProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => build());
    final items = state.valueOrNull;
    if (items != null) {
      unawaited(_autoPublish(items));
    }
  }

  Future<Product> addProduct(CreateProductInput input) async {
    final repository = ref.read(productsRepositoryProvider);
    final product = await repository.addProduct(input);

    final currentItems = state.valueOrNull ?? await build();
    final updatedItems = [...currentItems, product]
      ..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updatedItems);
    unawaited(_autoPublish(updatedItems));

    return product;
  }

  /// يضيف عدة منتجات دفعة واحدة (مثال: عدة أحجام تم اختيارها معًا
  /// من قائمة الأحجام المتوفرة)، ثم ينشر الكتالوج مرة واحدة فقط
  /// بعد انتهاء كل الإضافات بدل نشره بعد كل منتج على حدة.
  Future<List<Product>> addProductsBatch(List<CreateProductInput> inputs) async {
    final repository = ref.read(productsRepositoryProvider);
    final newProducts = await repository.addProductsBatch(inputs);

    final currentItems = state.valueOrNull ?? await build();
    final updatedItems = [...currentItems, ...newProducts]..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updatedItems);
    unawaited(_autoPublish(updatedItems));

    return newProducts;
  }

  Future<Product> updateStock(Product product, int stockQuantity) async {
    final repository = ref.read(productsRepositoryProvider);
    final updatedProduct = await repository.updateStock(product, stockQuantity);

    final currentItems = state.valueOrNull ?? await build();
    final updatedItems = currentItems
        .map((item) => item.id == updatedProduct.id ? updatedProduct : item)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updatedItems);
    unawaited(_autoPublish(updatedItems));

    return updatedProduct;
  }

  Future<void> deleteProduct(Product product) async {
    final repository = ref.read(productsRepositoryProvider);
    await repository.deleteProduct(product);

    final currentItems = state.valueOrNull ?? await build();
    final updatedItems = currentItems
        .where((item) => item.id != product.id || item.barcode != product.barcode)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    state = AsyncData(updatedItems);
    unawaited(_autoPublish(updatedItems));
  }

  /// Publishes the current catalog to the cloud in the background so
  /// customers always see live product data without the merchant needing
  /// to manually re-share the store link. Failures are silent (e.g. no
  /// internet) since the app stays fully usable offline; the next
  /// successful mutation will retry the publish.
  Future<void> _autoPublish(List<Product> products) async {
    try {
      final profile = await ref.read(storeProfileControllerProvider.future);
      final payload = StoreService().buildPayload(
        storeCode: profile.storeCode,
        storeName: profile.storeName,
        whatsappNumber: profile.whatsappNumber,
        products: products,
      );
      await StoreApiService().publishCatalog(
        storeCode: profile.storeCode,
        secret: profile.secret,
        body: payload.toMap(),
      );
    } catch (_) {
      // Ignore background sync failures.
    }
  }
}
