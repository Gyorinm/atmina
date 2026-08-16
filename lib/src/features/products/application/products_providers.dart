import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/application/store_api_service.dart';
import '../../store/application/store_profile_controller.dart';
import '../../store/application/store_service.dart';
import '../data/datasources/app_database.dart';
import '../data/repositories/products_repository.dart';
import '../domain/models/create_product_input.dart';
import '../domain/models/product.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(appDatabaseProvider));
});

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
