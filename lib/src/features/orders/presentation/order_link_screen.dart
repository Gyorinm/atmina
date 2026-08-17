import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/currency_formatting.dart';
import '../../cart/application/cart_controller.dart';
import '../../products/data/datasources/app_database.dart';
import '../../products/domain/models/product.dart';
import '../application/order_service.dart';
import '../domain/order_payload.dart';

class OrderLinkScreen extends ConsumerStatefulWidget {
  const OrderLinkScreen({super.key, required this.payload});

  final OrderPayload payload;

  @override
  ConsumerState<OrderLinkScreen> createState() => _OrderLinkScreenState();
}

class _OrderLinkScreenState extends ConsumerState<OrderLinkScreen> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.payload.items.fold<double>(
      0,
      (sum, item) => sum + item.unitPrice * item.quantity,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلبية مستلمة')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  title: Text('الطلب #${widget.payload.code}'),
                  subtitle: Text('الإجمالي: ${total.toCurrency()}'),
                ),
              ),
              if (widget.payload.customerName.isNotEmpty)
                Card(
                  color: const Color(0xFFEFF6FF),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text('الزبون: ${widget.payload.customerName}'),
                  ),
                )
              else
                const Card(
                  color: Color(0xFFFFF4E5),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text('لم يُدخل الزبون اسمه في التطبيق.'),
                  ),
                ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF5D98B)),
                ),
                child: const Text(
                  'تأكد من اسم الزبون قبل تجهيز الطلبية، وتأكد من أنك سألت الزبون الخاص بك عن اسمه في التطبيق.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A5B00)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: widget.payload.items
                      .map(
                        (item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.barcode),
                          trailing: Text('× ${item.quantity}'),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : _accept,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    saving ? 'جارٍ الاستلام...' : 'استلام الطلب وتجهيزه',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => saving = true);

    try {
      final cart = ref.read(cartControllerProvider);
      final controller = ref.read(cartControllerProvider.notifier);
      final products = <({Product product, int quantity})>[];

      for (final item in widget.payload.items) {
        if (item.quantity <= 0) {
          throw StateError('الكمية المطلوبة من ${item.name} غير صالحة.');
        }

        final product = await AppDatabase.instance.findProductByBarcode(
          item.barcode,
        );
        if (product == null) {
          throw StateError('المنتج ${item.name} غير موجود في مخزون التاجر.');
        }

        final key = controller.productKey(product);
        final existingQuantity = cart[key]?.quantity ?? 0;
        if (existingQuantity + item.quantity > product.stockQuantity) {
          throw StateError(
            'الكمية المطلوبة من ${item.name} تتجاوز المخزون المتاح مع السلة الحالية.',
          );
        }

        products.add((product: product, quantity: item.quantity));
      }

      await OrderService(AppDatabase.instance).importOrder(widget.payload);

      for (final entry in products) {
        for (var index = 0; index < entry.quantity; index++) {
          if (!controller.addProduct(entry.product)) {
            throw StateError('تعذر إضافة ${entry.product.name} إلى السلة.');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الطلب إلى السلة وحفظه محلياً.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر استلام الطلب: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
