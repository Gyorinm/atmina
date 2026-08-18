import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../orders/presentation/sales_history_screen.dart';
import '../../../store/presentation/screens/merchant_store_screen.dart';
import 'home_screen.dart';
import 'merchant_more_screen.dart';

/// الغلاف الرئيسي لواجهة التاجر، يضم شريط تنقل سفلي بالأيقونات
/// (على غرار تطبيق فيسبوك) للتبديل بسرعة بين المنتجات، السلة، سجل
/// المبيعات، متجري (QR)، والمزيد — بدل القائمة الجانبية القديمة.
class MerchantHomeShell extends ConsumerStatefulWidget {
  const MerchantHomeShell({super.key});

  @override
  ConsumerState<MerchantHomeShell> createState() => _MerchantHomeShellState();
}

class _MerchantHomeShellState extends ConsumerState<MerchantHomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    CartScreen(),
    SalesHistoryScreen(),
    MerchantStoreScreen(),
    MerchantMoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartTotals = ref.watch(cartTotalsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: AppColors.navy.withValues(alpha: 0.1),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'المنتجات'),
            NavigationDestination(
              icon: Badge(
                label: Text('${cartTotals.totalQuantity}'),
                isLabelVisible: cartTotals.totalQuantity > 0,
                child: const Icon(Icons.point_of_sale_outlined),
              ),
              selectedIcon: Badge(
                label: Text('${cartTotals.totalQuantity}'),
                isLabelVisible: cartTotals.totalQuantity > 0,
                child: const Icon(Icons.point_of_sale_rounded),
              ),
              label: 'السلة',
            ),
            const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'المبيعات'),
            const NavigationDestination(icon: Icon(Icons.qr_code_outlined), selectedIcon: Icon(Icons.qr_code_rounded), label: 'متجري'),
            const NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_open_rounded), label: 'المزيد'),
          ],
        ),
      ),
    );
  }
}
