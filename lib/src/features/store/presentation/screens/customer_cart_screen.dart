import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/share_links.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../cart/presentation/widgets/cart_item_tile.dart';
import '../../../onboarding/application/user_name_controller.dart';
import '../../../orders/application/order_service.dart';
import '../../../products/data/datasources/app_database.dart';
import '../../application/customer_orders_controller.dart';
import '../../domain/customer_order_record.dart';
import '../../domain/store_payload.dart';

class CustomerCartScreen extends ConsumerStatefulWidget {
  const CustomerCartScreen({super.key, required this.payload});

  final StorePayload payload;

  @override
  ConsumerState<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends ConsumerState<CustomerCartScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartItemsProvider);
    final totals = ref.watch(cartTotalsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('طلبيتي')),
      body: SafeArea(
        child: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('السلة فارغة. أضف منتجات من المتجر أولاً.', style: theme.textTheme.bodyLarge),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  ...items.map((item) {
                    final key = item.product.id ?? item.product.barcode.hashCode;
                    return CartItemTile(
                      item: item,
                      canIncrement: item.quantity < item.product.stockQuantity,
                      onIncrement: () => ref.read(cartControllerProvider.notifier).increment(key),
                      onDecrement: () => ref.read(cartControllerProvider.notifier).decrement(key),
                      onRemove: () => ref.read(cartControllerProvider.notifier).remove(key),
                    );
                  }),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'الإجمالي التقديري',
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                              ),
                            ),
                            Text(
                              totals.subtotal.toCurrency(),
                              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'السعر النهائي سيؤكده التاجر بعد استلام الطلبية.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _sending ? null : _sendOrder,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(_sending ? 'جارٍ الإرسال...' : 'إرسال الطلبية عبر واتساب'),
                            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navy),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _sendOrder() async {
    setState(() => _sending = true);
    try {
      final cart = ref.read(cartItemsProvider);
      final totals = ref.read(cartTotalsProvider);
      final customerName = ref.read(userNameControllerProvider).valueOrNull ?? '';
      final orderService = OrderService(AppDatabase.instance);
      final orderPayload = orderService.buildPayload(
        cart.map((line) => (product: line.product, quantity: line.quantity)).toList(),
        note: 'طلبية من متجر ${widget.payload.storeCode}',
        customerName: customerName,
      );
      final link = ShareLinks.orderLink(orderPayload.encode());
      final customerLine = customerName.isEmpty ? '' : 'الزبون: $customerName\n';
      final message = 'طلبية جديدة #${orderPayload.code} من متجرك على Atmina\n'
          '$customerLine'
          'افتح هذا الرابط داخل تطبيق Atmina لاستلامها:\n$link';

      final whatsapp = widget.payload.whatsappNumber.trim();
      if (whatsapp.isNotEmpty) {
        final digitsOnly = whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
        final waUri = Uri.parse('https://wa.me/$digitsOnly?text=${Uri.encodeComponent(message)}');
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await SharePlus.instance.share(ShareParams(text: message, title: 'إرسال الطلبية'));
      }

      await ref.read(customerOrdersControllerProvider.notifier).addOrder(
            CustomerOrderRecord(
              orderCode: orderPayload.code,
              storeCode: widget.payload.storeCode,
              storeName: widget.payload.storeName,
              total: totals.subtotal,
              itemsCount: totals.totalQuantity,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );

      ref.read(cartControllerProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تجهيز الطلبية برقم #${orderPayload.code}.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الطلبية: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
