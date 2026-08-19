/// روابط المشاركة (الطلبية / رابط المتجر) التي تُرسل خارج التطبيق عبر
/// واتساب أو أي وسيلة مشاركة أخرى. نستخدم نطاق خادم Cloudflare Worker
/// الخاص بالمشروع (رقمي، لا يحمل اسم حساب GitHub) بدل صفحات GitHub
/// Pages الشخصية، حتى لا يظهر اسم حساب GitHub لأي زبون أو تاجر يفتح
/// الرابط أو ينسخه.
abstract final class ShareLinks {
  static const String _baseUrl = 'https://atmina-store-api.o2730884.workers.dev/l';

  static String storeLink(String encodedPayload) => '$_baseUrl#store/$encodedPayload';

  static String orderLink(String encodedPayload) => '$_baseUrl#order/$encodedPayload';
}
