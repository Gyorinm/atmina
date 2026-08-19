import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/customer/presentation/screens/customer_home_shell.dart';
import '../features/onboarding/application/app_role_controller.dart';
import '../features/onboarding/application/user_name_controller.dart';
import '../features/onboarding/domain/app_role.dart';
import '../features/onboarding/presentation/name_entry_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/orders/domain/order_payload.dart';
import '../features/orders/presentation/order_link_screen.dart';
import '../features/products/presentation/screens/merchant_home_shell.dart';
import '../features/store/application/customer_session_controller.dart';
import '../features/store/application/store_api_service.dart';
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
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;
    final container = ProviderScope.containerOf(navContext, listen: false);
    if (uri.host == 'order') {
      _openOrderLink(navContext, container, uri.pathSegments.first);
    } else if (uri.host == 'store') {
      _openStoreLink(navContext, container, uri.pathSegments.first);
    }
  }

  /// يفتح رابط طلبية بحسب دور المستخدم الحالي:
  /// - التاجر: يفتح شاشة استلام الطلبية المعتادة لتجهيزها.
  /// - الزبون (أو دور غير محدد بعد): هذا الرابط هو نفس الرابط الذي
  ///   أرسله الزبون بنفسه إلى التاجر عبر واتساب، فلا معنى لفتح شاشة
  ///   "استلام الطلب" الخاصة بالتاجر لديه (وقد تسبب خطأ لأن منتجات
  ///   التاجر غير موجودة في قاعدة بيانات الزبون). نكتفي بتأكيد بسيط.
  void _openOrderLink(BuildContext context, ProviderContainer container, String encoded) {
    final OrderPayload payload;
    try {
      payload = OrderPayload.decode(encoded);
    } catch (_) {
      return; // رابط تالف أو غير صالح: نتجاهله بصمت.
    }

    final role = container.read(appRoleControllerProvider).valueOrNull;

    if (role != AppRole.merchant) {
      showDialog<void>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 40),
            title: const Text('تم إرسال الطلبية'),
            content: Text('طلبيتك رقم #${payload.code} أُرسلت بالفعل إلى التاجر. يمكنك متابعتها من "طلبياتي".'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    _navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => OrderLinkScreen(payload: payload)),
    );
  }

  Future<void> _openStoreLink(BuildContext context, ProviderContainer container, String code) async {
    try {
      final json = await StoreApiService().fetchCatalog(code);
      final payload = StorePayload.fromMap(json, fallbackCode: code);
      await container.read(customerSessionControllerProvider.notifier).saveLastStore(code, payload.storeName);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CustomerCatalogScreen(payload: payload)),
      );
    } catch (_) {
      // Ignore malformed or unreachable store links.
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
        if (role == null) return const RoleSelectionScreen();
        return const _NameGate();
      },
    );
  }
}

class _NameGate extends ConsumerWidget {
  const _NameGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(appRoleControllerProvider);
    final nameAsync = ref.watch(userNameControllerProvider);

    return nameAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const NameEntryScreen(),
      data: (name) {
        if (name == null || name.isEmpty) return const NameEntryScreen();
        return roleAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => const RoleSelectionScreen(),
          data: (role) {
            switch (role) {
              case AppRole.merchant:
                return const MerchantHomeShell();
              case AppRole.customer:
                return const CustomerHomeShell();
              case null:
                return const RoleSelectionScreen();
            }
          },
        );
      },
    );
  }
}
