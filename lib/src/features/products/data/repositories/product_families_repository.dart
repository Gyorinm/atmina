import '../../application/product_image_picker.dart';
import '../../domain/models/product_family.dart';
import '../datasources/app_database.dart';
import '../moroccan_grocery_presets.dart';

/// يدير "عائلات المنتجات" — القائمة القابلة للتعديل من طرف التاجر
/// نفسه، والتي تبدأ مبذورة بمنتجات البقالة المغربية الجاهزة، ويمكن
/// للتاجر إضافة المزيد إليها أو إرفاق صورة بكل عائلة لاحقًا.
class ProductFamiliesRepository {
  const ProductFamiliesRepository(this._database);

  final AppDatabase _database;

  /// يجلب كل العائلات، ويزرع القائمة الجاهزة الافتراضية في أول
  /// استخدام فقط إذا كان الجدول فارغًا (حتى لا يُعاد الزرع كل مرة
  /// أو يُلغي إضافات/صور التاجر الخاصة).
  Future<List<ProductFamily>> fetchFamilies() async {
    final existingCount = await _database.countProductFamilies();
    if (existingCount == 0) {
      await _seedDefaults();
    }
    return _database.getAllProductFamilies();
  }

  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    final families = moroccanGroceryPresets
        .map(
          (preset) => ProductFamily(
            name: preset.name,
            category: preset.category,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList(growable: false);
    await _database.insertProductFamiliesBatch(families);
  }

  Future<ProductFamily> addFamily({
    required String name,
    required String category,
    String? imagePath,
  }) {
    final now = DateTime.now();
    return _database.insertProductFamily(
      ProductFamily(
        name: name.trim(),
        category: category.trim(),
        imagePath: imagePath,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<ProductFamily> updateFamilyImage(ProductFamily family, String? newImagePath) async {
    final oldImagePath = family.imagePath;
    final updated = family.copyWith(
      imagePath: newImagePath,
      clearImagePath: newImagePath == null,
      // أي تغيير في الصورة المحلية (جديدة أو محذوفة) يُبطل حالة
      // "مُصدَّرة" السابقة، لأن الصورة على الخادم لم تعد مطابقة.
      clearImageExportedAt: true,
      updatedAt: DateTime.now(),
    );
    await _database.updateProductFamily(updated);
    if (oldImagePath != null && oldImagePath != newImagePath) {
      await ProductImagePicker.deleteImage(oldImagePath);
    }
    return updated;
  }

  /// يُعلّم صورة العائلة كمُصدَّرة بنجاح إلى الخادم بتاريخ اليوم،
  /// لتظهر علامة الصح الخضراء في واجهة الاختيار.
  Future<ProductFamily> markImageExported(ProductFamily family) async {
    final updated = family.copyWith(imageExportedAt: DateTime.now());
    await _database.updateProductFamily(updated);
    return updated;
  }

  Future<void> deleteFamily(ProductFamily family) async {
    await _database.deleteProductFamily(family.id!);
    await ProductImagePicker.deleteImage(family.imagePath);
  }
}
