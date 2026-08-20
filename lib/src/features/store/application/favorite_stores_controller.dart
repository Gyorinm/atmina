import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _favoriteStoresKey = 'atmina_customer_favorite_stores';

class FavoriteStore {
  const FavoriteStore({required this.code, required this.name});

  final String code;
  final String name;

  Map<String, dynamic> toMap() => {'code': code, 'name': name};

  factory FavoriteStore.fromMap(Map<String, dynamic> map) => FavoriteStore(
        code: map['code'] as String? ?? '',
        name: map['name'] as String? ?? '',
      );
}

final favoriteStoresControllerProvider =
    AsyncNotifierProvider<FavoriteStoresController, List<FavoriteStore>>(FavoriteStoresController.new);

/// يحفظ قائمة المتاجر التي "أعجبت" الزبون محليًا على جهازه، ليصل إليها
/// بسرعة دون البحث في خريطة "المتاجر القريبة" أو تذكّر الرابط في كل مرة.
class FavoriteStoresController extends AsyncNotifier<List<FavoriteStore>> {
  @override
  Future<List<FavoriteStore>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoriteStoresKey) ?? const [];
    return raw
        .map((s) {
          try {
            return FavoriteStore.fromMap(Map<String, dynamic>.from(jsonDecode(s) as Map));
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteStore>()
        .toList(growable: false);
  }

  bool isFavorite(String code) {
    final list = state.valueOrNull ?? const [];
    return list.any((s) => s.code == code);
  }

  Future<void> toggle(String code, String name) async {
    final current = List<FavoriteStore>.from(state.valueOrNull ?? await build());
    final index = current.indexWhere((s) => s.code == code);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(FavoriteStore(code: code, name: name));
    }
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> remove(String code) async {
    final current = List<FavoriteStore>.from(state.valueOrNull ?? await build())..removeWhere((s) => s.code == code);
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> _persist(List<FavoriteStore> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteStoresKey, list.map((s) => jsonEncode(s.toMap())).toList());
  }
}
