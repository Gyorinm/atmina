import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/customer_order_record.dart';

const String _ordersKey = 'atmina_customer_orders';

final customerOrdersControllerProvider =
    AsyncNotifierProvider<CustomerOrdersController, List<CustomerOrderRecord>>(CustomerOrdersController.new);

class CustomerOrdersController extends AsyncNotifier<List<CustomerOrderRecord>> {
  @override
  Future<List<CustomerOrderRecord>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_ordersKey) ?? const [];
    return raw
        .map((item) => CustomerOrderRecord.fromMap(Map<String, dynamic>.from(jsonDecode(item) as Map)))
        .toList(growable: false);
  }

  Future<void> addOrder(CustomerOrderRecord record) async {
    final current = state.valueOrNull ?? await build();
    final updated = [record, ...current];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ordersKey, updated.map((e) => jsonEncode(e.toMap())).toList());
    state = AsyncData(updated);
  }
}
