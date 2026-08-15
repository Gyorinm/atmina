import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/currency_formatting.dart';
import '../../cart/application/cart_controller.dart';
import '../../products/data/datasources/app_database.dart';
import '../../products/domain/models/product.dart';
import '../application/order_service.dart';
import '../domain/order_payload.dart';
class OrderLinkScreen extends ConsumerStatefulWidget { const OrderLinkScreen({super.key, required this.payload}); final OrderPayload payload; @override ConsumerState<OrderLinkScreen> createState() => _OrderLinkScreenState(); }
class _OrderLinkScreenState extends ConsumerState<OrderLinkScreen> {
  bool saving = false;
  @override Widget build(BuildContext context) { final total = widget.payload.items.fold<double>(0, (s, i) => s + i.unitPrice * i.quantity); return Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('طلبية مستلمة')), body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [Card(child: ListTile(title: Text('الطلب #${widget.payload.code}'), subtitle: Text('الإجمالي: ${total.toCurrency()}'))), const SizedBox(height: 12), Expanded(child: ListView(children: widget.payload.items.map((i) => ListTile(title: Text(i.name), subtitle: Text(i.barcode), trailing: Text('× ${i.quantity}'))).toList())), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : _accept, icon: const Icon(Icons.add_shopping_cart), label: Text(saving ? 'جارٍ الاستلام...' : 'استلام الطلب وتجهيزه')))])))); }
  Future<void> _accept() async {
    setState(() => saving = true);
    try {
      final products = <({Product product, int quantity})>[];
      for (final item in widget.payload.items) {
        final product = await AppDatabase.instance.findProductByBarcode(item.barcode);
        if (product == null) throw StateError('المنتج ${item.name} غير موجود في مخزون التاجر.');
        if (product.stockQuantity < item.quantity) throw StateError('الكمية المطلوبة من ${item.name} تتجاوز المخزون المتاح.');
        products.add((product: product, quantity: item.quantity));
      }
      await OrderService(AppDatabase.instance).importOrder(widget.payload);
      for (final entry in products) for (var n = 0; n < entry.quantity; n++) ref.read(cartControllerProvider.notifier).addProduct(entry.product);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الطلب إلى السلة وحفظه محلياً.'))); Navigator.of(context).pop(); }
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر استلام الطلب: $error'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
}
