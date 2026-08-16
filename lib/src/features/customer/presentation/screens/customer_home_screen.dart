import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/support_developer.dart';
import '../../../onboarding/application/app_role_controller.dart';
import '../../../store/application/customer_session_controller.dart';
import '../../../store/application/store_opener.dart';
import '../../../store/presentation/screens/customer_orders_screen.dart';
import '../../../store/presentation/screens/customer_store_access_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastStoreAsync = ref.watch(customerSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('واجهة الزبون')),
      drawer: _CustomerDrawer(
        onMyOrders: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CustomerOrdersScreen()),
        ),
        onSupportDeveloper: launchSupportDeveloper,
        onSwitchRole: () => ref.read(appRoleControllerProvider.notifier).clearRole(),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront_outlined, size: 56, color: AppColors.navy),
                const SizedBox(height: 16),
                Text('تسوّق من متجرك المفضل', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'امسح رمز المتجر أو الصق الرابط الذي أرسله لك التاجر عبر واتساب لتصفح منتجاته وإرسال طلبية مباشرة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                lastStoreAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (lastStore) {
                    if (lastStore == null) return const SizedBox.shrink();
                    final storeName = lastStore.name.isEmpty ? lastStore.code : lastStore.name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FilledButton.icon(
                        onPressed: () => openStoreByCode(context, ref, lastStore.code),
                        icon: const Icon(Icons.storefront_rounded),
                        label: Text('متابعة التسوق من $storeName'),
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CustomerStoreAccessScreen()),
                  ),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('الدخول إلى متجر آخر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerDrawer extends StatelessWidget {
  const _CustomerDrawer({
    required this.onMyOrders,
    required this.onSupportDeveloper,
    required this.onSwitchRole,
  });

  final VoidCallback onMyOrders;
  final VoidCallback onSupportDeveloper;
  final VoidCallback onSwitchRole;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.navy,
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'حساب الزبون',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('طلبياتي'),
              onTap: () {
                Navigator.pop(context);
                onMyOrders();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('دعم المطور'),
              onTap: () {
                Navigator.pop(context);
                onSupportDeveloper();
              },
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('تبديل نوع الحساب'),
              onTap: () {
                Navigator.pop(context);
                onSwitchRole();
              },
            ),
          ],
        ),
      ),
    );
  }
}
