import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../application/app_role_controller.dart';
import '../domain/app_role.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _isSaving = false;

  Future<void> _choose(AppRole role) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(appRoleControllerProvider.notifier).selectRole(role);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_rounded, size: 64, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'مرحبًا بك في Atmina',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'كيفاش بغيتي تستعمل التطبيق؟',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 36),
              _RoleCard(
                icon: Icons.point_of_sale_rounded,
                title: 'أنا تاجر',
                subtitle: 'إدارة المنتجات، المخزون، المبيعات، ومشاركة متجرك مع الزبناء.',
                onTap: _isSaving ? null : () => _choose(AppRole.merchant),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.shopping_bag_outlined,
                title: 'مستخدم عادي (زبون)',
                subtitle: 'تصفح منتجات متجر معيّن وإرسال طلبية للتاجر مباشرة.',
                onTap: _isSaving ? null : () => _choose(AppRole.customer),
              ),
              if (_isSaving) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.navy, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
