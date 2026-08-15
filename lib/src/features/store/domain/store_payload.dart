import 'dart:convert';

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

  factory StorePayload.fromMap(Map<String, dynamic> map) => StorePayload(
        storeCode: map['store_code'] as String,
        storeName: (map['store_name'] as String?) ?? '',
        whatsappNumber: (map['whatsapp_number'] as String?) ?? '',
        generatedAt: (map['generated_at'] as String?) ?? '',
        items: (map['items'] as List)
            .map((e) => StorePayloadItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(growable: false),
      );

  String encode() => base64UrlEncode(utf8.encode(jsonEncode(toMap()))).replaceAll('=', '');

  static StorePayload decode(String value) {
    final padded = value.padRight((value.length + 3) ~/ 4 * 4, '=');
    return StorePayload.fromMap(Map<String, dynamic>.from(jsonDecode(utf8.decode(base64Url.decode(padded))) as Map));
  }
}

class StorePayloadItem {
  const StorePayloadItem({
    required this.internalCode,
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
  });

  final String internalCode;
  final String name;
  final String category;
  final double price;
  final int stockQuantity;

  Map<String, dynamic> toMap() => {
        'internal_code': internalCode,
        'name': name,
        'category': category,
        'price': price,
        'stock_quantity': stockQuantity,
      };

  factory StorePayloadItem.fromMap(Map<String, dynamic> map) => StorePayloadItem(
        internalCode: map['internal_code'] as String,
        name: map['name'] as String,
        category: (map['category'] as String?) ?? '',
        price: (map['price'] as num).toDouble(),
        stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      );
}
