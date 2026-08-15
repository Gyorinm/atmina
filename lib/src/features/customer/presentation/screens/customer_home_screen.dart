import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../onboarding/application/app_role_controller.dart';

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
                Text('تصفح المتجر قريبًا', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'قريبًا هنا: إدخال كود المتجر أو مسح الباركود لتصفح منتجات التاجر وإرسال طلبية مباشرة عبر واتساب.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
