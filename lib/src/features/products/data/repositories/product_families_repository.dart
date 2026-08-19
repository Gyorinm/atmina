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
    } else {
      // إصلاح تلقائي: العائلات التي بُذرت سابقًا بأسماء قديمة (فرنسية)
      // قبل تحديث القائمة إلى الدارجة تُحدَّث هنا تلقائيًا، مع الحفاظ
      // على صورها وحالة تصديرها للخادم دون أي تغيير.
      final current = await _database.getAllProductFamilies();
      await _repairLegacyNames(current);
    }
    return _database.getAllProductFamilies();
  }

  Future<void> _repairLegacyNames(List<ProductFamily> families) async {
    for (final family in families) {
      final newName = _legacyNameFixes[family.name];
      if (newName == null) continue;

      GroceryPresetItem? matchingPreset;
      for (final preset in moroccanGroceryPresets) {
        if (preset.name == newName) {
          matchingPreset = preset;
          break;
        }
      }
      if (matchingPreset == null) continue;

      final updated = family.copyWith(
        name: newName,
        category: matchingPreset.category,
        measurementUnit: matchingPreset.measurementUnit,
        updatedAt: DateTime.now(),
      );
      await _database.updateProductFamily(updated);
    }
  }



  Future<void> _seedDefaults() async {
    final now = DateTime.now();
    final families = moroccanGroceryPresets
        .map(
          (preset) => ProductFamily(
            name: preset.name,
            category: preset.category,
            measurementUnit: preset.measurementUnit,
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
    MeasurementUnit measurementUnit = MeasurementUnit.none,
  }) {
    final now = DateTime.now();
    return _database.insertProductFamily(
      ProductFamily(
        name: name.trim(),
        category: category.trim(),
        imagePath: imagePath,
        measurementUnit: measurementUnit,
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

  static const Map<String, String> _legacyNameFixes = {
    'Huile Afia 1L': 'الزيت ديال العافية',
    'Huile Lesieur Cristal 1L': 'الزيت ديال لوزيان',
    'Huile El Kef 1L': 'الزيت الذهبي',
    'Huile Chams 1L': 'زيت الشمس',
    'Huile d\'olive Sidi 1L': 'زيت الزيتون البلدي',
    'Huile d\'olive Afriquia 1L': 'زيت الزيتون ديال أفريقيا',
    'Huile de soja Coco 1L': 'زيت الصوجا',
    'Sucre Cosumar 1kg': 'السكر ديال كوسومار',
    'Sucre en morceaux Cosumar': 'السكر مقطع',
    'Farine Sitanaf 10kg': 'الدقيق ديال سيطانوف',
    'Farine Chaarat 10kg': 'الدقيق ديال شعارة',
    'Farine Dari 10kg': 'الدقيق ديال داري',
    'Sel Maïda': 'الملح ديال مايضة',
    'Riz Casablanca 1kg': 'الروز',
    'Lentilles / Fèves / Pois chiches (au kg)': 'العدس والفول والحمص',
    'Couscous Chaarat': 'الكسكسو ديال شعارة',
    'Vermicelles / Pâtes': 'الشعرية',
    'Thé Sultan': 'أتاي ديال السلطان',
    'Thé El Attas': 'أتاي ديال العطاس',
    'Café Nescafé': 'القهوة ديال نسكافي',
    'Levure Saf': 'الخميرة',
    'Lait Centrale Danone 1L': 'الحليب ديال الفلاح',
    'Lait Nakhil': 'الحليب ديال النخيل',
    'Fromage La Vache Qui Rit': 'الفرماج لاباك ديال الضحكة',
    'Fromage Jibal': 'الفرماج ديال جيبال',
    'Yaourt Danone Activia': 'الياغورط ديال الفلاح أكتيفيا',
    'Beurre': 'الزبدة',
    'Lait concentré Nido': 'الحليب مركز نيدو',
    'Coca-Cola 1.5L': 'كوكاكولا',
    'Pepsi 1.5L': 'بيبسي',
    'Hamoud Boualem': 'حمود بوعلام',
    'Jus Marrakech': 'العصير ديال مراكش',
    'Jus Rafraîchissant': 'عصير رافريشيسمو',
    'Sidi Ali 1.5L': 'سيدي علي',
    'Oulmès 1.5L': 'ولمس',
    'Ain Saiss 1.5L': 'عين السايس',
    'Sidi Harazem 1.5L': 'سيدي حرازم',
    'Ain Ifrane 1.5L': 'عين إفران',
    'Javel Jawex': 'الجاوي ديال جواكس',
    'Javel Nilly': 'الجاوي ديال نيلي',
    'Lessive Tide': 'التيد',
    'Lessive Ariel': 'أريال',
    'Lessive Axion': 'أكسيون',
    'Liquide vaisselle Fairy': 'فيري ديال الماعون',
    'Désinfectant Ajax': 'أجاكس',
    'Nettoyant vitres': 'مسّاح الزجاج',
    'Papier hygiénique': 'الكاغيط ديال الحمام',
    'Sacs poubelle': 'صك الزبل',
    'Savon Lux': 'الصابون ديال لوكس',
    'Savon Dove': 'الصابون ديال دوف',
    'Savon Jamila': 'صابون جميلة',
    'Dentifrice Signal': 'المعجون ديال سيغنال',
    'Shampoing Head & Shoulders': 'الشمبوان ديال هيد أند شولدرز',
    'Biscuits Bimo': 'البسكوي ديال بيمو',
    'Biscuits Le Matin': 'البسكوي ديال لوماتان',
    'Chocolat Kinder': 'الشكولاطة ديال كيندر',
    'Chips': 'الشيبس',
    'Concentré de tomate Atlas': 'الطماطم مصبرة ديال أطلس',
    'Concentré de tomate Aïcha': 'الطماطم مصبرة ديال عائشة',
    'Concentré de tomate Dolly': 'الطماطم مصبرة ديال دولي',
    'Thon en conserve': 'التونة مصبرة',
    'Olives en conserve': 'الزيتون مصبر',
    'Mayonnaise Aïcha': 'المايونيز ديال عائشة',
    'Pain français / Baguette': 'خبز فرنسي',
    'Pain de mie Sandwich': 'خبز الصاندويتش',
    'Croissant': 'الكرواسون',
  };
}
