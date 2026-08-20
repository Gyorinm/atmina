import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/favorite_stores_controller.dart';
import '../../application/store_opener.dart';

/// تعرض قائمة المتاجر التي أضافها الزبون إلى مفضلته، مع إمكانية فتح أي
/// منها مباشرة أو إزالته من القائمة.
class FavoriteStoresScreen extends ConsumerWidget {
  const FavoriteStoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteStoresControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('متاجري المفضلة')),
      body: SafeArea(
        child: favoritesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('حدث خطأ: $error')),
          data: (favorites) {
            if (favorites.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد متاجر مفضلة بعد. اضغط على أيقونة القلب داخل أي متجر لإضافته هنا.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final store = favorites[index];
                final displayName = store.name.isEmpty ? store.code : store.name;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.storefront_rounded, color: AppColors.navy),
                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                      tooltip: 'إزالة من المفضلة',
                      onPressed: () => ref.read(favoriteStoresControllerProvider.notifier).remove(store.code),
                    ),
                    onTap: () => openStoreByCode(context, ref, store.code),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
