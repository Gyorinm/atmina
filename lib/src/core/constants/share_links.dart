/// روابط المشاركة (الطلبية / رابط المتجر) التي تُرسل خارج التطبيق عبر
/// واتساب أو أي وسيلة مشاركة أخرى. نستخدم نطاق خادم Cloudflare Worker
/// الخاص بالمشروع (رقمي، لا يحمل اسم حساب GitHub) بدل صفحات GitHub
/// Pages الشخصية، حتى لا يظهر اسم حساب GitHub لأي زبون أو تاجر يفتح
/// الرابط أو ينسخه.
abstract final class ShareLinks {
  static const String _baseUrl = 'https://atmina-store-api.o2730884.workers.dev/l';

  static String storeLink(String storeCode) => '$_baseUrl#store/$storeCode';

  /// رابط الطلبية يحمل رمزها القصير فقط (مثلاً 1755701234567-482)، بعد
  /// أن أصبحت بيانات الطلبية الكاملة تُنشر على الخادم أولاً بدل تضمينها
  /// مضغوطة داخل الرابط نفسه، مما يقصّره بشكل كبير.
  static String orderLink(String orderCode) => '$_baseUrl#order/$orderCode';
}
