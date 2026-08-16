import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/customer_orders_controller.dart';

class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('طلبياتي')),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('تعذر تحميل الطلبيات: $error')),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('لم ترسل أي طلبية بعد.', style: theme.textTheme.bodyLarge),
                ),
              );
            }
            final totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إجمالي ما أنفقته', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text(
                              totalSpent.toCurrency(),
                              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Text('${orders.length} طلبية', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...orders.map(
                  (order) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.storeName.isEmpty ? order.storeCode : order.storeName,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'طلبية #${order.orderCode} • ${order.itemsCount} قطعة',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(order.total.toCurrency(), style: theme.textTheme.titleMedium?.copyWith(color: AppColors.navy)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
