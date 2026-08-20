import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shopping_list_item.dart';

const String _shoppingListKey = 'atmina_customer_shopping_list';

final shoppingListControllerProvider =
    AsyncNotifierProvider<ShoppingListController, List<ShoppingListItem>>(ShoppingListController.new);

/// قائمة تسوّق بسيطة يديرها الزبون بنفسه: يضيف منتجات ينوي شراءها من أي
/// حانوت، ويشطبها عند اقتنائها. تُحفظ محليًا على الجهاز فقط.
class ShoppingListController extends AsyncNotifier<List<ShoppingListItem>> {
  static final Random _random = Random();

  @override
  Future<List<ShoppingListItem>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_shoppingListKey) ?? const [];
    return raw
        .map((s) {
          try {
            return ShoppingListItem.fromMap(Map<String, dynamic>.from(jsonDecode(s) as Map));
          } catch (_) {
            return null;
          }
        })
        .whereType<ShoppingListItem>()
        .toList(growable: false);
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final current = List<ShoppingListItem>.from(state.valueOrNull ?? await build());
    final id = '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1000)}';
    current.add(ShoppingListItem(id: id, name: trimmed));
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> toggleDone(String id) async {
    final current = List<ShoppingListItem>.from(state.valueOrNull ?? await build());
    final index = current.indexWhere((i) => i.id == id);
    if (index < 0) return;
    current[index] = current[index].copyWith(done: !current[index].done);
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> remove(String id) async {
    final current = List<ShoppingListItem>.from(state.valueOrNull ?? await build())..removeWhere((i) => i.id == id);
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> clearDone() async {
    final current = List<ShoppingListItem>.from(state.valueOrNull ?? await build())..removeWhere((i) => i.done);
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> _persist(List<ShoppingListItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shoppingListKey, list.map((i) => jsonEncode(i.toMap())).toList());
  }
}
