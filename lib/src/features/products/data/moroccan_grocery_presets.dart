/// قائمة جاهزة بأشهر منتجات البقالة المغربية (بالاسم التجاري/الماركة)
/// مصنّفة حسب النوع، لتسهيل إضافتها على التاجر دون كتابة يدوية.
class GroceryPresetItem {
  const GroceryPresetItem({required this.name, required this.category});

  final String name;
  final String category;
}

const List<String> moroccanGroceryCategories = [
  'زيوت',
  'مواد غذائية جافة',
  'ألبان وأجبان',
  'مشروبات',
  'مياه معدنية',
  'منظفات وجافيل',
  'عناية شخصية',
  'بسكويت وحلويات',
  'معلبات وصلصات',
  'خبز ومخبوزات',
];

const List<GroceryPresetItem> moroccanGroceryPresets = [
  // ===== زيوت =====
  GroceryPresetItem(name: 'زيت عافية 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت لوزيان (Lesieur) 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت الذهبي 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت الشمس 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت الزيتون سيدي 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت الزيتون أفريقيا 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت كوكو الصويا 1 لتر', category: 'زيوت'),
  GroceryPresetItem(name: 'زيت العافية 5 لتر', category: 'زيوت'),

  // ===== مواد غذائية جافة =====
  GroceryPresetItem(name: 'سكر كوسومار (Cosumar) 1 كغ', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'سكر مكعبات كوسومار', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'دقيق سيتناف (Sitanaf) 10 كغ', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'دقيق شعائر 10 كغ', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'دقيق الديار 10 كغ', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'ملح مايدة (Maïda)', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'أرز الدار البيضاء 1 كغ', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'عدس / فول / حمص (بالكيلو)', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'كسكس شعائر', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'شعرية / اتريا (باستا)', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'شاي السلطان (Sultan Tea)', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'شاي العطاس', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'قهوة نسكافيه (Nescafé)', category: 'مواد غذائية جافة'),
  GroceryPresetItem(name: 'خميرة سعيدة (Fleischmann\'s / Saf)', category: 'مواد غذائية جافة'),

  // ===== ألبان وأجبان =====
  GroceryPresetItem(name: 'حليب سنترال دانون 1 لتر', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'حليب النخيل (Nakhil)', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'جبن الفاشة الضاحكة (La Vache Qui Rit)', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'جبن جيبال (Jibal)', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'زبادي دانون أكتيفيا', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'زبدة الوردة (Beurre)', category: 'ألبان وأجبان'),
  GroceryPresetItem(name: 'حليب مركز نيدو (Nido)', category: 'ألبان وأجبان'),

  // ===== مشروبات =====
  GroceryPresetItem(name: 'كوكاكولا 1.5 لتر', category: 'مشروبات'),
  GroceryPresetItem(name: 'بيبسي 1.5 لتر', category: 'مشروبات'),
  GroceryPresetItem(name: 'حمود بوعلام (Hamoud Boualem)', category: 'مشروبات'),
  GroceryPresetItem(name: 'عصير مارو (Marrakech / Maroc)', category: 'مشروبات'),
  GroceryPresetItem(name: 'عصير ريفريش (Rafraîchissant)', category: 'مشروبات'),

  // ===== مياه معدنية =====
  GroceryPresetItem(name: 'سيدي علي (Sidi Ali) 1.5 لتر', category: 'مياه معدنية'),
  GroceryPresetItem(name: 'ولماس (Oulmès) 1.5 لتر', category: 'مياه معدنية'),
  GroceryPresetItem(name: 'عين سايس (Ain Saiss) 1.5 لتر', category: 'مياه معدنية'),
  GroceryPresetItem(name: 'سيدي حرازم (Sidi Harazem) 1.5 لتر', category: 'مياه معدنية'),
  GroceryPresetItem(name: 'عين إفران (Ain Ifrane) 1.5 لتر', category: 'مياه معدنية'),

  // ===== منظفات وجافيل =====
  GroceryPresetItem(name: 'جافيل جواكس (Jawex)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'جافيل نيلي (Nilly)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'مسحوق تايد (Tide)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'مسحوق أريال (Ariel)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'مسحوق إكسيل (Axion / Excel)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'سائل تنظيف الأواني فيري (Fairy)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'مطهر أجاكس (Ajax)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'ملمع الزجاج فيتري (Vitre)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'مناديل ورقية (Papier Hygiénique)', category: 'منظفات وجافيل'),
  GroceryPresetItem(name: 'أكياس القمامة (Sacs Poubelle)', category: 'منظفات وجافيل'),

  // ===== عناية شخصية =====
  GroceryPresetItem(name: 'صابون لوكس (Lux)', category: 'عناية شخصية'),
  GroceryPresetItem(name: 'صابون دوف (Dove)', category: 'عناية شخصية'),
  GroceryPresetItem(name: 'صابون جميلة', category: 'عناية شخصية'),
  GroceryPresetItem(name: 'معجون أسنان سيغنال (Signal)', category: 'عناية شخصية'),
  GroceryPresetItem(name: 'شامبو هيد آند شولدرز (Head & Shoulders)', category: 'عناية شخصية'),

  // ===== بسكويت وحلويات =====
  GroceryPresetItem(name: 'بسكويت بيمو (Bimo)', category: 'بسكويت وحلويات'),
  GroceryPresetItem(name: 'بسكويت لو ماتان (Le Matin)', category: 'بسكويت وحلويات'),
  GroceryPresetItem(name: 'شوكولاطة كيندر (Kinder)', category: 'بسكويت وحلويات'),
  GroceryPresetItem(name: 'حلويات جيبس / شيبس (Chips)', category: 'بسكويت وحلويات'),

  // ===== معلبات وصلصات =====
  GroceryPresetItem(name: 'معجون طماطم أطلس (Atlas)', category: 'معلبات وصلصات'),
  GroceryPresetItem(name: 'معجون طماطم أيشة (Aïcha)', category: 'معلبات وصلصات'),
  GroceryPresetItem(name: 'معجون طماطم دبي', category: 'معلبات وصلصات'),
  GroceryPresetItem(name: 'تونة معلبة', category: 'معلبات وصلصات'),
  GroceryPresetItem(name: 'زيتون معلب', category: 'معلبات وصلصات'),
  GroceryPresetItem(name: 'مايونيز أيشة (Aïcha)', category: 'معلبات وصلصات'),

  // ===== خبز ومخبوزات =====
  GroceryPresetItem(name: 'خبز فرنسي / الرغيف', category: 'خبز ومخبوزات'),
  GroceryPresetItem(name: 'خبز شهيوات (Sandwich)', category: 'خبز ومخبوزات'),
  GroceryPresetItem(name: 'كرواسون', category: 'خبز ومخبوزات'),
];
