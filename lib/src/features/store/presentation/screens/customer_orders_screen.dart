import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/customer_orders_controller.dart';
import '../../domain/customer_order_record.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  DateTimeRange? _selectedRange;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _selectedRange,
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  void _clearRange() {
    setState(() => _selectedRange = null);
  }

  List<CustomerOrderRecord> _filter(List<CustomerOrderRecord> orders) {
    final range = _selectedRange;
    if (range == null) return orders;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return orders.where((order) {
      final date = DateTime.tryParse(order.createdAt);
      if (date == null) return false;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبياتي'),
        actions: [
          IconButton(
            tooltip: 'تحديد فترة',
            onPressed: _pickRange,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('تعذر تحميل الطلبيات: $error')),
          data: (allOrders) {
            if (allOrders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('لم ترسل أي طلبية بعد.', style: theme.textTheme.bodyLarge),
                ),
              );
            }
            final orders = _filter(allOrders);
            final totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_selectedRange != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'الفترة: ${_formatDate(_selectedRange!.start)} - ${_formatDate(_selectedRange!.end)}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearRange,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('إلغاء'),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRange == null ? 'إجمالي ما أنفقته' : 'الإنفاق خلال الفترة',
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                            ),
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
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Center(
                      child: Text('لا توجد طلبيات خلال هذه الفترة.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
                    ),
                  )
                else
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
                                const SizedBox(height: 2),
                                Builder(builder: (context) {
                                  final date = DateTime.tryParse(order.createdAt);
                                  return Text(
                                    date == null ? '' : _formatDate(date),
                                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                  );
                                }),
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
