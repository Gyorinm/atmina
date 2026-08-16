import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/share_links.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../../../features/orders/application/order_service.dart';
import '../../../../features/products/application/products_providers.dart';
import '../../../../features/products/data/datasources/app_database.dart';
import '../../application/cart_controller.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider); final totals = ref.watch(cartTotalsProvider);
    return Scaffold(appBar: AppBar(title: const Text('نقطة البيع')), body: SafeArea(child: items.isEmpty ? const _EmptyCartState() : ListView(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), children: [
      ...items.map((item) { final key = item.product.id ?? item.product.barcode.hashCode; return CartItemTile(item: item, canIncrement: item.quantity < item.product.stockQuantity, onIncrement: () { if (!ref.read(cartControllerProvider.notifier).increment(key)) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لا يمكن تجاوز المخزون المتاح لمنتج "${item.product.name}"'))); }, onDecrement: () => ref.read(cartControllerProvider.notifier).decrement(key), onRemove: () => ref.read(cartControllerProvider.notifier).remove(key)); }),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { try { final payload = OrderService(AppDatabase.instance).buildPayload(items.map((e) => (product: e.product, quantity: e.quantity)).toList()); final link = ShareLinks.orderLink(payload.encode()); await SharePlus.instance.share(ShareParams(text: 'طلبية Atmina #${payload.code}\nافتح هذا الرابط داخل تطبيق Atmina لإضافة الطلب:\n$link', title: 'مشاركة الطلبية')); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر مشاركة الطلبية: $error'))); } }, icon: const Icon(Icons.share_outlined), label: const Text('نسخ ومشاركة رابط الطلبية')),
      const SizedBox(height: 10),
      CartSummaryCard(totals: totals, onCheckout: (finalAmount, receivedAmount) async { try { await OrderService(AppDatabase.instance).saveSale(items: items.map((e) => (product: e.product, quantity: e.quantity)).toList(), subtotal: totals.subtotal, discount: totals.subtotal - finalAmount, total: finalAmount, received: receivedAmount); ref.read(cartControllerProvider.notifier).clear(); await ref.read(productsControllerProvider.notifier).refresh(); if (!context.mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تسجيل البيع بمبلغ ${finalAmount.toCurrency()} وخصم الكميات من المخزون.'))); Navigator.of(context).pop(); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تسجيل البيع: $error'))); } }),
    ])));
  }
}
class _EmptyCartState extends StatelessWidget { const _EmptyCartState(); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.border)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.shopping_bag_outlined, size: 36, color: AppColors.navy), const SizedBox(height: 16), Text('السلة فارغة', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text('أضف منتجات من الشاشة الرئيسية ليظهر إيصال البيع هنا.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted))])))); }
