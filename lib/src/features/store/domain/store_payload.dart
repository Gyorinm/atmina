class StorePayload {
  const StorePayload({
    required this.storeCode,
    required this.storeName,
    required this.whatsappNumber,
    required this.generatedAt,
    required this.items,
  });

  final String storeCode;
  final String storeName;
  final String whatsappNumber;
  final String generatedAt;
  final List<StorePayloadItem> items;

  Map<String, dynamic> toMap() => {
        'store_code': storeCode,
        'store_name': storeName,
        'whatsapp_number': whatsappNumber,
        'generated_at': generatedAt,
        'items': items.map((e) => e.toMap()).toList(),
      };

  factory StorePayload.fromMap(Map<String, dynamic> map, {String? fallbackCode}) => StorePayload(
        storeCode: (map['store_code'] as String?) ?? fallbackCode ?? '',
        storeName: (map['store_name'] as String?) ?? '',
        whatsappNumber: (map['whatsapp_number'] as String?) ?? '',
        generatedAt: (map['generated_at'] as String?) ?? '',
        items: (map['items'] as List? ?? const [])
            .map((e) => StorePayloadItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );
}

class StorePayloadItem {
  const StorePayloadItem({
    required this.internalCode,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.familyId,
    this.variantLabel,
  });

  final String internalCode;
  final String name;
  final String category;
  final double price;
  final int stockQuantity;

  /// معرّف "عائلة المنتج" إن وُجد، يُستخدم من تطبيق الزبون لبناء رابط
  /// صورة المنتج المخزَّنة على الخادم (/store/{code}/images/{familyId}).
  final int? familyId;

  /// تسمية الحجم/الوزن (مثال: "1 لتر") — تُستخدم عند الزبون لتمييز
  /// عدة أحجام لنفس المنتج دون تكرار الاسم أو الصورة.
  final String? variantLabel;

  Map<String, dynamic> toMap() => {
        'internal_code': internalCode,
        'name': name,
        'category': category,
        'price': price,
        'stock_quantity': stockQuantity,
        if (familyId != null) 'family_id': familyId,
        if (variantLabel != null) 'variant_label': variantLabel,
      };

  factory StorePayloadItem.fromMap(Map<String, dynamic> map) => StorePayloadItem(
        internalCode: map['internal_code'] as String,
        name: map['name'] as String,
        category: (map['category'] as String?) ?? '',
        price: (map['price'] as num).toDouble(),
        stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
        familyId: (map['family_id'] as num?)?.toInt(),
        variantLabel: map['variant_label'] as String?,
      );
}
