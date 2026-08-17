import 'dart:convert';

import 'package:archive/archive.dart';

class OrderPayload {
  const OrderPayload({required this.code, required this.createdAt, required this.items, this.note = '', this.customerName = ''});
  final String code;
  final String createdAt;
  final String note;
  final String customerName;
  final List<OrderPayloadItem> items;
  Map<String, dynamic> toMap() => {'code': code, 'created_at': createdAt, 'note': note, 'customer_name': customerName, 'items': items.map((e) => e.toMap()).toList()};
  factory OrderPayload.fromMap(Map<String, dynamic> map) => OrderPayload(code: map['code'] as String, createdAt: map['created_at'] as String, note: (map['note'] as String?) ?? '', customerName: (map['customer_name'] as String?) ?? '', items: (map['items'] as List).map((e) => OrderPayloadItem.fromMap(Map<String, dynamic>.from(e as Map))).toList(growable: false));
  String encode() {
    final jsonBytes = utf8.encode(jsonEncode(toMap()));
    final compressed = const ZLibEncoder().encode(jsonBytes);
    return base64UrlEncode(compressed).replaceAll('=', '');
  }
  static OrderPayload decode(String value) { final padded = value.padRight((value.length + 3) ~/ 4 * 4, '='); final compressed = base64Url.decode(padded); final jsonBytes = const ZLibDecoder().decodeBytes(compressed); return OrderPayload.fromMap(Map<String, dynamic>.from(jsonDecode(utf8.decode(jsonBytes)) as Map)); }
}
class OrderPayloadItem {
  const OrderPayloadItem({required this.barcode, required this.name, required this.unitPrice, required this.quantity});
  final String barcode; final String name; final double unitPrice; final int quantity;
  Map<String, dynamic> toMap() => {'barcode': barcode, 'name': name, 'unit_price': unitPrice, 'quantity': quantity};
  factory OrderPayloadItem.fromMap(Map<String, dynamic> map) => OrderPayloadItem(barcode: map['barcode'] as String, name: map['name'] as String, unitPrice: (map['unit_price'] as num).toDouble(), quantity: (map['quantity'] as num).toInt());
}
