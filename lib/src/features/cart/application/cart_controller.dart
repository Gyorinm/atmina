import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/models/product.dart';

final cartControllerProvider =
    NotifierProvider<CartController, Map<int, CartLine>>(CartController.new);

final cartItemsProvider = Provider<List<CartLine>>((ref) {
  final items =
      ref.watch(cartControllerProvider).values.toList(growable: false);
  items.sort((a, b) => a.product.name.compareTo(b.product.name));
  return items;
});

final cartTotalsProvider = Provider<CartTotals>((ref) {
  final items = ref.watch(cartItemsProvider);
  final subtotal = items.fold<double>(
    0,
    (sum, item) => sum + item.lineTotal,
  );
  final totalQuantity = items.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );

  return CartTotals(
    itemsCount: items.length,
    totalQuantity: totalQuantity,
    subtotal: subtotal,
  );
});

class CartController extends Notifier<Map<int, CartLine>> {
  @override
  Map<int, CartLine> build() => <int, CartLine>{};

  int productKey(Product product) => product.id ?? product.barcode.hashCode;

  bool addProduct(Product product) {
    final key = productKey(product);
    final current = state[key];
    final nextQuantity = (current?.quantity ?? 0) + 1;

    if (nextQuantity > product.stockQuantity) {
      return false;
    }

    state = {
      ...state,
      key: current == null
          ? CartLine(product: product, quantity: 1)
          : current.copyWith(quantity: nextQuantity),
    };

    return true;
  }

  bool increment(int productKey) {
    final current = state[productKey];
    if (current == null) {
      return false;
    }

    if (current.quantity >= current.product.stockQuantity) {
      return false;
    }

    state = {
      ...state,
      productKey: current.copyWith(quantity: current.quantity + 1),
    };

    return true;
  }

  void decrement(int productKey) {
    final current = state[productKey];
    if (current == null) {
      return;
    }

    if (current.quantity == 1) {
      remove(productKey);
      return;
    }

    state = {
      ...state,
      productKey: current.copyWith(quantity: current.quantity - 1),
    };
  }

  void remove(int productKey) {
    final next = {...state}..remove(productKey);
    state = next;
  }

  void removeProduct(Product product) {
    remove(productKey(product));
  }

  void syncProduct(Product product) {
    final key = productKey(product);
    final current = state[key];
    if (current == null) {
      return;
    }

    final nextQuantity = current.quantity > product.stockQuantity
        ? product.stockQuantity
        : current.quantity;

    if (nextQuantity <= 0) {
      remove(key);
      return;
    }

    state = {
      ...state,
      key: current.copyWith(
        product: product,
        quantity: nextQuantity,
      ),
    };
  }

  void clear() {
    state = <int, CartLine>{};
  }
}

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartLine copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartTotals {
  const CartTotals({
    required this.itemsCount,
    required this.totalQuantity,
    required this.subtotal,
  });

  final int itemsCount;
  final int totalQuantity;
  final double subtotal;

  double get total => subtotal;
}
