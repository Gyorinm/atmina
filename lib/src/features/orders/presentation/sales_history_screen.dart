import 'package:flutter/material.dart';

import '../../../core/extensions/currency_formatting.dart';
import '../../products/data/datasources/app_database.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل المبيعات')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: AppDatabase.instance.getOrders(source: 'sale'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('تعذر تحميل سجل المبيعات: ${snapshot.error}'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final rows = snapshot.data!;
            if (rows.isEmpty) {
              return const Center(child: Text('لا توجد مبيعات مسجلة بعد.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final row = rows[index];
                final total = (row['total'] as num).toDouble();
                final received = (row['received'] as num).toDouble();
                final change = (row['change_due'] as num).toDouble();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('بيع #${row['order_code']}'),
                    subtitle: Text(
                      '${row['created_at']}\nالمستلم: ${received.toCurrency()} • الباقي: ${change.toCurrency()}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      total.toCurrency(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
