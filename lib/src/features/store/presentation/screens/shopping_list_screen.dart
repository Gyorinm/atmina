import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/shopping_list_controller.dart';

/// قائمة تسوّق يديرها الزبون بنفسه: يضيف أسماء منتجات ينوي شراءها من
/// أي حانوت، ويشطبها عند اقتنائها. تبقى محفوظة على جهازه بين الجلسات.
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final TextEditingController _controller = TextEditingController();

  void _addItem() {
    ref.read(shoppingListControllerProvider.notifier).add(_controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة تسوقي'),
        actions: [
          listAsync.maybeWhen(
            data: (items) => items.any((i) => i.done)
                ? IconButton(
                    tooltip: 'حذف المُشترى',
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => ref.read(shoppingListControllerProvider.notifier).clearDone(),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addItem(),
                      decoration: InputDecoration(
                        hintText: 'أضف منتجًا (مثال: خبز، بيض...)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: listAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('حدث خطأ: $error')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'قائمتك فارغة. أضف أول منتج تريد شراءه.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }
                  final sorted = [...items]..sort((a, b) => a.done == b.done ? 0 : (a.done ? 1 : -1));
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = sorted[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => ref.read(shoppingListControllerProvider.notifier).remove(item.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: CheckboxListTile(
                            value: item.done,
                            onChanged: (_) => ref.read(shoppingListControllerProvider.notifier).toggleDone(item.id),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            activeColor: AppColors.navy,
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: item.done ? TextDecoration.lineThrough : null,
                                color: item.done ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
