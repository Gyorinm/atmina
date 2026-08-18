import 'dart:convert';

import 'package:http/http.dart' as http;

class StoreApiException implements Exception {
  const StoreApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StoreApiService {
  static const String _baseUrl = 'https://atmina-store-api.o2730884.workers.dev';

  Future<void> publishCatalog({
    required String storeCode,
    required String secret,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_baseUrl/store/$storeCode');
    late final http.Response response;
    try {
      response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json', 'X-Store-Secret': secret},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const StoreApiException('تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.');
    }
    if (response.statusCode == 403) {
      throw const StoreApiException('هذا الكود مستخدم من طرف متجر آخر.');
    }
    if (response.statusCode != 200) {
      throw StoreApiException('تعذر نشر بيانات المتجر (${response.statusCode}).');
    }
  }

  Future<Map<String, dynamic>> fetchCatalog(String storeCode) async {
    final uri = Uri.parse('$_baseUrl/store/$storeCode');
    late final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const StoreApiException('تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.');
    }
    if (response.statusCode == 404) {
      throw const StoreApiException('لم يتم العثور على هذا المتجر. تأكد من الرمز أو الرابط.');
    }
    if (response.statusCode != 200) {
      throw StoreApiException('تعذر تحميل بيانات المتجر (${response.statusCode}).');
    }
  /// يرفع صورة عائلة منتج مضغوطة (Base64) إلى الخادم لتصبح مرئية
  /// للزبائن ضمن كتالوج المتجر.
  Future<void> uploadFamilyImage({
    required String storeCode,
    required String secret,
    required int familyId,
    required String base64Image,
  }) async {
    final uri = Uri.parse('$_baseUrl/store/$storeCode/images/$familyId');
    late final http.Response response;
    try {
      response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json', 'X-Store-Secret': secret},
            body: jsonEncode({'image_base64': base64Image}),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const StoreApiException('تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.');
    }
    if (response.statusCode != 200) {
      throw StoreApiException('تعذر رفع الصورة إلى الخادم (${response.statusCode}).');
    }
  }

  /// يحذف صورة عائلة منتج من الخادم.
  Future<void> deleteFamilyImage({
    required String storeCode,
    required String secret,
    required int familyId,
  }) async {
    final uri = Uri.parse('$_baseUrl/store/$storeCode/images/$familyId');
    late final http.Response response;
    try {
      response = await http
          .delete(uri, headers: {'X-Store-Secret': secret})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const StoreApiException('تعذر الاتصال بالخادم. تأكد من اتصالك بالإنترنت.');
    }
    if (response.statusCode != 200 && response.statusCode != 404) {
      throw StoreApiException('تعذر حذف الصورة من الخادم (${response.statusCode}).');
    }
  }
}
