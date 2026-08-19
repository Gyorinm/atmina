import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// طريقة عرض قائمة المنتجات. يختار كل مستخدم (تاجر أو زبون) الطريقة
/// التي تناسبه بحرية كاملة، وتُحفظ محليًا على جهازه فتبقى كما اختارها
/// في المرات القادمة، بشكل مستقل عن الطرف الآخر.
enum ProductViewMode {
  /// بطاقة كاملة بكل التفاصيل (الوضع الافتراضي الحالي).
  comfortable,

  /// قائمة مضغوطة: صف أصغر لكل منتج، مناسبة لعرض أكبر عدد ممكن دفعة
  /// واحدة.
  compact,

  /// شبكة بعمودين: بطاقات صغيرة جنبًا إلى جنب.
  grid;

  static ProductViewMode fromStorageValue(String? value) {
    return ProductViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ProductViewMode.comfortable,
    );
  }

  IconData get icon => switch (this) {
        ProductViewMode.comfortable => Icons.view_agenda_outlined,
        ProductViewMode.compact => Icons.view_list_outlined,
        ProductViewMode.grid => Icons.grid_view_outlined,
      };

  String get label => switch (this) {
        ProductViewMode.comfortable => 'عرض مريح',
        ProductViewMode.compact => 'قائمة مضغوطة',
        ProductViewMode.grid => 'شبكة صغيرة',
      };
}

/// متحكم عام يقرأ ويحفظ طريقة العرض في SharedPreferences تحت مفتاح
/// مخصّص، بحيث يمكن استخدام نفس المنطق لكل من التاجر والزبون دون تكرار
/// الكود، مع بقاء تفضيل كل طرف منفصلًا عن الآخر.
class ProductViewModeController extends AsyncNotifier<ProductViewMode> {
  ProductViewModeController(this._storageKey);

  final String _storageKey;

  @override
  Future<ProductViewMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return ProductViewMode.fromStorageValue(prefs.getString(_storageKey));
  }

  Future<void> setMode(ProductViewMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);
  }
}

/// تفضيل طريقة العرض الخاص بالتاجر (شاشة المنتجات الرئيسية).
final merchantViewModeProvider =
    AsyncNotifierProvider<ProductViewModeController, ProductViewMode>(
  () => ProductViewModeController('atmina_merchant_view_mode'),
);

/// تفضيل طريقة العرض الخاص بالزبون (كتالوج المتجر).
final customerViewModeProvider =
    AsyncNotifierProvider<ProductViewModeController, ProductViewMode>(
  () => ProductViewModeController('atmina_customer_view_mode'),
);
