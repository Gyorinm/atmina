import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/support_developer.dart';
import '../../../backup/presentation/backup_restore_screen.dart';
import '../../../onboarding/application/app_role_controller.dart';

/// تبويب "المزيد" في شريط التاجر السفلي — يجمع الوظائف الثانوية
/// التي لا يحتاجها التاجر يوميًا (النسخ الاحتياطي، دعم المطور، تبديل
/// نوع الحساب) بعيدًا عن الشريط الرئيسي.
class MerchantMoreScreen extends ConsumerWidget {
  const MerchantMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MoreTile(
              icon: Icons.backup_outlined,
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'احفظ نسخة من بياناتك أو استعد نسخة سابقة',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Directionality(
                    textDirection: TextDirection.rtl,
                    child: BackupRestoreScreen(),
                  ),
                ),
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
