import 'package:flutter/material.dart';
import '../../../core/extensions/currency_formatting.dart';
import '../../products/data/datasources/app_database.dart';
class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});
  @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: Scaffold(appBar: AppBar(title: const Text('سجل المبيعات')), body: FutureBuilder<List<Map<String, dynamic>>>(future: AppDatabase.instance.getOrders(), builder: (context, snapshot) { if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); final rows = snapshot.data!.where((r) => r['source'] == 'sale').toList(); if (rows.isEmpty) return const Center(child: Text('لا توجد مبيعات مسجلة بعد.')); return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final r = rows[i]; final total = (r['total'] as num).toDouble(); return Card(child: ListTile(leading: const Icon(Icons.receipt_long_outlined), title: Text('بيع #${r['order_code']}'), subtitle: Text(r['created_at'] as String), trailing: Text(total.toCurrency(), style: const TextStyle(fontWeight: FontWeight.bold))); }); }))); }
}
