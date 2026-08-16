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
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
