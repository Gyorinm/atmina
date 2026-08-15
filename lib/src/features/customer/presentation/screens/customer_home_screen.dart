import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../onboarding/application/app_role_controller.dart';
import '../../../store/presentation/screens/customer_store_access_screen.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة الزبون'),
        actions: [
          IconButton(
            tooltip: 'تبديل نوع الحساب',
            onPressed: () => ref.read(appRoleControllerProvider.notifier).clearRole(),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ],
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
                  'الصق الرابط الذي أرسله لك التاجر عبر واتساب لتصفح منتجاته وإرسال طلبية مباشرة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CustomerStoreAccessScreen()),
                  ),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('إدخال رابط المتجر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
