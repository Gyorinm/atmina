import 'package:intl/intl.dart';

extension CurrencyFormatting on num {
  String toCurrency() {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: 'en',
      decimalDigits: 2,
    );
    return '${formatter.format(this)} MAD';
  }
}
