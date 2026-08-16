abstract final class ShareLinks {
  static const String _baseUrl = 'https://gyorinm.github.io/atmina/l.html';

  static String storeLink(String encodedPayload) => '$_baseUrl#store/$encodedPayload';

  static String orderLink(String encodedPayload) => '$_baseUrl#order/$encodedPayload';
}
