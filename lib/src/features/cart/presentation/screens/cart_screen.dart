import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/cart_controller.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_card.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    final totals = ref.watch(cartTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
      ),
      body: SafeArea(
        child: items.isEmpty
            ? const _EmptyCartState()
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final productKey =
                              item.product.id ?? item.product.barcode.hashCode;

                          return CartItemTile(
                            item: item,
                            canIncrement:
                                item.quantity < item.product.stockQuantity,
                            onIncrement: () {
                              final incremented = ref
                                  .read(cartControllerProvider.notifier)
                                  .increment(productKey);
                              if (!incremented) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'لا يمكن تجاوز المخزون المتاح لمنتج "${item.product.name}"',
                                    ),
                                  ),
                                );
                              }
                            },
                            onDecrement: () => ref
                                .read(cartControllerProvider.notifier)
                                .decrement(productKey),
                            onRemove: () => ref
                                .read(cartControllerProvider.notifier)
                                .remove(productKey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    CartSummaryCard(
                      totals: totals,
                      onCheckout: (finalAmount) {
                        ref.read(cartControllerProvider.notifier).clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم إنهاء البيع بمبلغ ${finalAmount.toCurrency()} وحفظ العملية محليًا',
                            ),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 36,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'السلة فارغة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'أضف منتجات من الشاشة الرئيسية ليظهر إيصال البيع هنا.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
