import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/orders/domain/order_payload.dart';
import '../features/orders/presentation/order_link_screen.dart';
import '../features/products/presentation/screens/home_screen.dart';

class AtminaApp extends StatefulWidget { const AtminaApp({super.key}); @override State<AtminaApp> createState() => _AtminaAppState(); }
class _AtminaAppState extends State<AtminaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  @override void initState() { super.initState(); _linkSubscription = AppLinks().uriLinkStream.listen(_openLink); }
  @override void dispose() { _linkSubscription?.cancel(); super.dispose(); }
  void _openLink(Uri uri) {
    if (uri.scheme != 'atmina' || uri.host != 'order' || uri.pathSegments.isEmpty) return;
    try { final payload = OrderPayload.decode(uri.pathSegments.first); _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => OrderLinkScreen(payload: payload))); } catch (_) {}
  }
  @override Widget build(BuildContext context) => MaterialApp(navigatorKey: _navigatorKey, debugShowCheckedModeBanner: false, title: 'Atmina POS', theme: AppTheme.lightTheme, locale: const Locale('ar'), supportedLocales: const [Locale('ar'), Locale('en')], localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate], home: const Directionality(textDirection: TextDirection.rtl, child: HomeScreen()));
}
