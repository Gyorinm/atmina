import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../store/application/customer_session_controller.dart';
import '../../../store/application/store_opener.dart';
import '../../../store/presentation/screens/customer_store_access_screen.dart';
import '../../../store/presentation/screens/favorite_stores_screen.dart';
import '../../../store/presentation/screens/product_search_screen.dart';
import '../../../store/presentation/screens/shopping_list_screen.dart';

/// تبويب "الرئيسية" لدى الزبون: الدخول لمتجر عبر رمز QR أو رابط، أو
/// متابعة التسوق من آخر متجر تمت زيارته.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastStoreAsync = ref.watch(customerSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة الزبون'),
        actions: [
          IconButton(
            tooltip: 'البحث عن منتج',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProductSearchScreen()),
            ),
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
                  'امسح رمز المتجر أو الصق الرابط الذي أرسله لك التاجر عبر واتساب لتصفح منتجاته وإرسال طلبية مباشرة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ShortcutCard(
                        icon: Icons.favorite_rounded,
                        label: 'متاجري المفضلة',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const FavoriteStoresScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ShortcutCard(
                        icon: Icons.checklist_rounded,
                        label: 'قائمة تسوقي',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ShoppingListScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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

/// بطاقة اختصار صغيرة (مفضلتي / قائمة تسوقي) تظهر في أعلى شاشة الزبون
/// الرئيسية للوصول السريع للميزات التي تشجّع العودة المتكررة للتطبيق.
class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navy),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
