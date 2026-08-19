import 'dart:math';

import '../../products/domain/models/product.dart';
import '../domain/store_payload.dart';

class StoreService {
  static final Random _random = Random.secure();

  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static String generateStoreCode() {
    final buffer = StringBuffer('ATM-');
    var checksum = 0;
    for (var i = 0; i < 8; i++) {
      final index = _random.nextInt(_codeAlphabet.length);
      checksum = (checksum + index * (i + 1)) % _codeAlphabet.length;
      buffer.write(_codeAlphabet[index]);
    }
    buffer.write(_codeAlphabet[checksum]);
    return buffer.toString();
  }

  StorePayload buildPayload({
    required String storeCode,
    required String storeName,
    required String whatsappNumber,
    required List<Product> products,
  }) {
    return StorePayload(
      storeCode: storeCode,
      storeName: storeName,
      whatsappNumber: whatsappNumber,
      generatedAt: DateTime.now().toIso8601String(),
      items: products
          .map((p) => StorePayloadItem(
                internalCode: p.barcode,
                name: p.name,
                category: p.category,
                price: p.price,
                stockQuantity: p.stockQuantity,
                familyId: p.familyId,
                variantLabel: p.variantLabel,
              ))
          .toList(growable: false),
    );
  }
}
