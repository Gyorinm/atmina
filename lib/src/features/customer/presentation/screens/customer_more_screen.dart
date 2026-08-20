import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/support_developer.dart';
import '../../../onboarding/application/app_role_controller.dart';
import '../../../store/presentation/screens/favorite_stores_screen.dart';
import '../../../store/presentation/screens/product_search_screen.dart';
import '../../../store/presentation/screens/shopping_list_screen.dart';

/// تبويب "المزيد" في شريط الزبون السفلي.
class CustomerMoreScreen extends ConsumerWidget {
  const CustomerMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MoreTile(
              icon: Icons.favorite_rounded,
              title: 'متاجري المفضلة',
              subtitle: 'الوصول السريع للحوانيت التي تحبها',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FavoriteStoresScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MoreTile(
              icon: Icons.checklist_rounded,
              title: 'قائمة تسوقي',
              subtitle: 'المنتجات التي تنوي شراءها',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ShoppingListScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MoreTile(
              icon: Icons.search_rounded,
              title: 'البحث الشامل عن منتج',
              subtitle: 'ابحث عن منتج عبر كل المتاجر',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProductSearchScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MoreTile(
              icon: Icons.favorite_border_rounded,
              title: 'دعم المطور',
              subtitle: 'ساهم في استمرار تطوير التطبيق',
              onTap: () => showSupportDeveloperSheet(context),
            ),
            const SizedBox(height: 12),
            _MoreTile(
              icon: Icons.swap_horiz_rounded,
              title: 'تبديل نوع الحساب',
              subtitle: 'التبديل بين وضع التاجر ووضع الزبون',
              onTap: () => ref.read(appRoleControllerProvider.notifier).clearRole(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: AppColors.navy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
