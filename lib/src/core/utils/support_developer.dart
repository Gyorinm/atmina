import 'package:url_launcher/url_launcher.dart';

Future<void> launchSupportDeveloper() async {
  final uri = Uri.parse(
    'https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=brahim0619087436%40gmail.com&currency_code=MAD&item_name=Atmina%20POS%20Developer%20Support',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
