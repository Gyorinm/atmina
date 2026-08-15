import 'dart:math';
import '../../../products/data/datasources/app_database.dart';
import '../../../products/domain/models/product.dart';
import '../domain/order_payload.dart';

class OrderService {
  OrderService(this.db);
  final AppDatabase db;
  String newCode() => '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}';

  Future<int> saveSale({required List<({Product product, int quantity})> items, required double subtotal, required double discount, required double total, required double received}) => db.createOrder(
    orderCode: newCode(), status: 'completed', subtotal: subtotal, discount: discount, total: total,
    received: received, changeDue: received - total, source: 'sale', deductStock: true,
    items: items.map((e) => {'product_barcode': e.product.barcode, 'product_name': e.product.name, 'unit_price': e.product.price, 'quantity': e.quantity, 'collected_quantity': e.quantity}).toList(),
  );

  OrderPayload buildPayload(List<({Product product, int quantity})> items, {String note = ''}) => OrderPayload(
    code: newCode(), createdAt: DateTime.now().toIso8601String(), note: note,
    items: items.map((e) => OrderPayloadItem(barcode: e.product.barcode, name: e.product.name, unitPrice: e.product.price, quantity: e.quantity)).toList(growable: false),
  );

  Future<int> importOrder(OrderPayload payload) {
    final total = payload.items.fold<double>(0, (s, i) => s + i.unitPrice * i.quantity);
    return db.createOrder(orderCode: payload.code, status: 'pending', subtotal: total, discount: 0, total: total, received: 0, changeDue: 0, source: 'shared', items: payload.items.map((i) => {'product_barcode': i.barcode, 'product_name': i.name, 'unit_price': i.unitPrice, 'quantity': i.quantity, 'collected_quantity': 0}).toList());
  }
}
