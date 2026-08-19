/// لائحة ديال المنتوجات اللي كاينة بزاف فبقالة مغربية، مكتوبة
/// بالدارجة المغربية، مقسّمة حسب النوع، باش التاجر ما يكتبش كلشي
/// بيدو. كل منتوج فيه "نوع القياس" (measurementUnit) اللي كيحدد وقتاش
/// كنعرضو للتاجر اختيار الأحجام (باللتر ولا بالكيلو) بدل ما يكتبها
/// بيدو.
enum MeasurementUnit {
  /// منتوج عادي بلا وزن ولا حجم يختاروه (بسكوي، صابون، معلبة...).
  none,

  /// سائل كيتباع بالجملة (زيت، عسل...) — كيتعرض بالليتر.
  liter,

  /// شي حاجة كتتباع بالوزن (دقيق، سكر، عدس بالجملة...) — كيتعرض بالكيلو.
  kg;

  String get storageValue => switch (this) {
        MeasurementUnit.none => 'none',
        MeasurementUnit.liter => 'liter',
        MeasurementUnit.kg => 'kg',
      };

  static MeasurementUnit fromStorage(String? value) {
    switch (value) {
      case 'liter':
        return MeasurementUnit.liter;
      case 'kg':
        return MeasurementUnit.kg;
      default:
        return MeasurementUnit.none;
    }
  }

  String get unitLabel => switch (this) {
        MeasurementUnit.liter => 'لتر',
        MeasurementUnit.kg => 'كغ',
        MeasurementUnit.none => '',
      };
}

class GroceryPresetItem {
  const GroceryPresetItem({
    required this.name,
    required this.category,
    this.measurementUnit = MeasurementUnit.none,
  });

  final String name;
  final String category;
  final MeasurementUnit measurementUnit;
}

const List<String> moroccanGroceryCategories = [
  'الزيوت',
  'حوايج المطبخ',
  'الحليب والجبن',
  'المشروبات',
  'الماء المعدني',
  'الجاوي وتنظيف الدار',
  'النظافة الشخصية',
  'الحلويات والبسكوي',
  'المعلبات والصلصة',
  'الخبز',
];

const List<GroceryPresetItem> moroccanGroceryPresets = [
  // ===== الزيوت (سائل - باللتر) =====
  GroceryPresetItem(name: 'الزيت ديال العافية', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'الزيت ديال لوزيان', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'الزيت الذهبي', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'زيت الشمس', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'زيت الزيتون البلدي', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'زيت الزيتون ديال أفريقيا', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),
  GroceryPresetItem(name: 'زيت الصوجا', category: 'الزيوت', measurementUnit: MeasurementUnit.liter),

  // ===== حوايج المطبخ =====
  GroceryPresetItem(name: 'السكر ديال كوسومار', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'السكر مقطع', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'الدقيق ديال سيطانوف', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'الدقيق ديال شعارة', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'الدقيق ديال داري', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'الملح ديال مايضة', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'الروز', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'العدس والفول والحمص', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'الكسكسو ديال شعارة', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),
  GroceryPresetItem(name: 'الشعرية', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'أتاي ديال السلطان', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'أتاي ديال العطاس', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'القهوة ديال نسكافي', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'الخميرة', category: 'حوايج المطبخ'),
  GroceryPresetItem(name: 'العسل بالجملة', category: 'حوايج المطبخ', measurementUnit: MeasurementUnit.kg),

  // ===== الحليب والجبن =====
  GroceryPresetItem(name: 'الحليب ديال الفلاح', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الحليب ديال النخيل', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الفرماج لاباك ديال الضحكة', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الفرماج ديال جيبال', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الياغورط ديال الفلاح أكتيفيا', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الزبدة', category: 'الحليب والجبن'),
  GroceryPresetItem(name: 'الحليب مركز نيدو', category: 'الحليب والجبن'),

  // ===== المشروبات =====
  GroceryPresetItem(name: 'كوكاكولا', category: 'المشروبات'),
  GroceryPresetItem(name: 'بيبسي', category: 'المشروبات'),
  GroceryPresetItem(name: 'حمود بوعلام', category: 'المشروبات'),
  GroceryPresetItem(name: 'العصير ديال مراكش', category: 'المشروبات'),
  GroceryPresetItem(name: 'عصير رافريشيسمو', category: 'المشروبات'),

  // ===== الماء المعدني =====
  GroceryPresetItem(name: 'سيدي علي', category: 'الماء المعدني'),
  GroceryPresetItem(name: 'ولمس', category: 'الماء المعدني'),
  GroceryPresetItem(name: 'عين السايس', category: 'الماء المعدني'),
  GroceryPresetItem(name: 'سيدي حرازم', category: 'الماء المعدني'),
  GroceryPresetItem(name: 'عين إفران', category: 'الماء المعدني'),

  // ===== الجاوي وتنظيف الدار =====
  GroceryPresetItem(name: 'الجاوي ديال جواكس', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'الجاوي ديال نيلي', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'التيد', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'أريال', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'أكسيون', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'فيري ديال الماعون', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'أجاكس', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'مسّاح الزجاج', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'الكاغيط ديال الحمام', category: 'الجاوي وتنظيف الدار'),
  GroceryPresetItem(name: 'صك الزبل', category: 'الجاوي وتنظيف الدار'),

  // ===== النظافة الشخصية =====
  GroceryPresetItem(name: 'الصابون ديال لوكس', category: 'النظافة الشخصية'),
  GroceryPresetItem(name: 'الصابون ديال دوف', category: 'النظافة الشخصية'),
  GroceryPresetItem(name: 'صابون جميلة', category: 'النظافة الشخصية'),
  GroceryPresetItem(name: 'المعجون ديال سيغنال', category: 'النظافة الشخصية'),
  GroceryPresetItem(name: 'الشمبوان ديال هيد أند شولدرز', category: 'النظافة الشخصية'),

  // ===== الحلويات والبسكوي =====
  GroceryPresetItem(name: 'البسكوي ديال بيمو', category: 'الحلويات والبسكوي'),
  GroceryPresetItem(name: 'البسكوي ديال لوماتان', category: 'الحلويات والبسكوي'),
  GroceryPresetItem(name: 'الشكولاطة ديال كيندر', category: 'الحلويات والبسكوي'),
  GroceryPresetItem(name: 'الشيبس', category: 'الحلويات والبسكوي'),

  // ===== المعلبات والصلصة =====
  GroceryPresetItem(name: 'الطماطم مصبرة ديال أطلس', category: 'المعلبات والصلصة'),
  GroceryPresetItem(name: 'الطماطم مصبرة ديال عائشة', category: 'المعلبات والصلصة'),
  GroceryPresetItem(name: 'الطماطم مصبرة ديال دولي', category: 'المعلبات والصلصة'),
  GroceryPresetItem(name: 'التونة مصبرة', category: 'المعلبات والصلصة'),
  GroceryPresetItem(name: 'الزيتون مصبر', category: 'المعلبات والصلصة'),
  GroceryPresetItem(name: 'المايونيز ديال عائشة', category: 'المعلبات والصلصة'),

  // ===== الخبز =====
  GroceryPresetItem(name: 'خبز فرنسي', category: 'الخبز'),
  GroceryPresetItem(name: 'خبز الصاندويتش', category: 'الخبز'),
  GroceryPresetItem(name: 'الكرواسون', category: 'الخبز'),
];
