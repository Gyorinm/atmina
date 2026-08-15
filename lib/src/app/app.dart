import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/customer/presentation/screens/customer_home_screen.dart';
import '../features/onboarding/application/app_role_controller.dart';
import '../features/onboarding/domain/app_role.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/orders/domain/order_payload.dart';
import '../features/orders/presentation/order_link_screen.dart';
import '../features/products/presentation/screens/home_screen.dart';
import '../features/store/domain/store_payload.dart';
import '../features/store/presentation/screens/customer_catalog_screen.dart';

class AtminaApp extends StatefulWidget {
  const AtminaApp({super.key});

  @override
  State<AtminaApp> createState() => _AtminaAppState();
}

class _AtminaAppState extends State<AtminaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(_openLink);
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _openLink(initial);
    } catch (_) {
      // Ignore malformed or unavailable initial links.
    }
  }

  void _openLink(Uri uri) {
    if (uri.scheme != 'atmina' || uri.pathSegments.isEmpty) return;
    if (uri.host != 'order' && uri.host != 'store') return;
    if (_navigatorKey.currentState == null) {
      _pendingUri = uri;
      return;
    }
    _navigateToLink(uri);
  }

  void _navigateToLink(Uri uri) {
    try {
      if (uri.host == 'order') {
        final payload = OrderPayload.decode(uri.pathSegments.first);
        _navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => OrderLinkScreen(payload: payload)),
        );
      } else if (uri.host == 'store') {
        final payload = StorePayload.decode(uri.pathSegments.first);
        _navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => CustomerCatalogScreen(payload: payload)),
        );
      }
    } catch (_) {
      // Ignore malformed links.
    }
  }

  void _flushPendingLink() {
    final uri = _pendingUri;
    if (uri == null || _navigatorKey.currentState == null) return;
    _pendingUri = null;
    _navigateToLink(uri);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushPendingLink());

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Atmina POS',
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(appRoleControllerProvider);

    return roleAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const RoleSelectionScreen(),
      data: (role) {
        switch (role) {
          case AppRole.merchant:
            return const HomeScreen();
          case AppRole.customer:
            return const CustomerHomeScreen();
          case null:
            return const RoleSelectionScreen();
        }
      },
    );
  }
}
