import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../../cart/application/cart_controller.dart';
import '../../../products/domain/models/product.dart';
import '../../domain/store_payload.dart';
import 'customer_cart_screen.dart';

class CustomerCatalogScreen extends ConsumerWidget {
  const CustomerCatalogScreen({super.key, required this.payload});

  final StorePayload payload;

  /// يجمع عناصر الكتالوج حسب عائلتها: كل عائلة تحمل أكثر من حجم واحد
  /// تظهر كبطاقة واحدة فيها اختيار الحجم، وباقي العناصر (بلا عائلة
  /// أو بعائلة ذات حجم واحد فقط) تظهر كل واحد في بطاقته المستقلة.
  List<List<StorePayloadItem>> _groupItems() {
    final Map<int, List<StorePayloadItem>> byFamily = {};
    final List<List<StorePayloadItem>> ordered = [];

    for (final item in payload.items) {
      if (item.familyId == null) {
        ordered.add([item]);
        continue;
      }
      final group = byFamily.putIfAbsent(item.familyId!, () {
        final newGroup = <StorePayloadItem>[];
        ordered.add(newGroup);
        return newGroup;
      });
      group.add(item);
    }

    return ordered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartTotals = ref.watch(cartTotalsProvider);
    final theme = Theme.of(context);
    final groups = _groupItems();

    void addToCart(StorePayloadItem item) {
      final added = ref.read(cartControllerProvider.notifier).addProduct(productFromCatalogItem(item));
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن تجاوز الكمية المتاحة من "${item.name}"')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(payload.storeName.isEmpty ? 'متجر ${payload.storeCode}' : payload.storeName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => CustomerCartScreen(payload: payload)),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_bag_outlined),
        label: Text(cartTotals.totalQuantity > 0 ? 'الطلبية (${cartTotals.totalQuantity})' : 'الطلبية'),
      ),
      body: SafeArea(
        child: payload.items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('لا توجد منتجات متاحة حاليًا في هذا المتجر.', style: theme.textTheme.bodyLarge),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  if (group.length > 1) {
                    return _VariantGroupCard(
                      items: group,
                      storeCode: payload.storeCode,
                      onAdd: addToCart,
                    );
                  }
                  return _CatalogItemCard(
                    item: group.first,
                    storeCode: payload.storeCode,
                    onAdd: () => addToCart(group.first),
                  );
                },
              ),
      ),
    );
  }
}

/// يبني كائن [Product] من عنصر كتالوج، لإضافته إلى السلة. يُستخدم اسم
/// الزبون الكامل (مع تسمية الحجم إن وُجدت) حتى يظهر واضحًا في السلة
/// والطلبية النهائية.
Product productFromCatalogItem(StorePayloadItem item) {
  final now = DateTime.now();
  final displayName = item.variantLabel == null || item.variantLabel!.isEmpty
      ? item.name
      : '${item.name} - ${item.variantLabel}';
  return Product(
    name: displayName,
    price: item.price,
    barcode: item.internalCode,
    category: item.category,
    stockQuantity: item.stockQuantity,
    searchTerms: '',
    createdAt: now,
    updatedAt: now,
  );
}

/// بطاقة منتج له أكثر من حجم/وزن متوفر: تعرض صورة العائلة مرة واحدة،
/// مع قائمة اختيار للحجم (Chips) — يختار الزبون الحجم فيتحدث السعر
/// والمخزون المعروضان تبعًا لاختياره، بدل تكرار المنتج في عدة بطاقات.
class _VariantGroupCard extends StatefulWidget {
  const _VariantGroupCard({required this.items, required this.storeCode, required this.onAdd});

  final List<StorePayloadItem> items;
  final String storeCode;
  final void Function(StorePayloadItem item) onAdd;

  @override
  State<_VariantGroupCard> createState() => _VariantGroupCardState();
}

class _VariantGroupCardState extends State<_VariantGroupCard> {
  late StorePayloadItem _selected;

  @override
  void initState() {
    super.initState();
    // نختار افتراضيًا أول حجم متوفر بالمخزون، وإلا أول حجم مطلقًا.
    _selected = widget.items.firstWhere(
      (item) => item.stockQuantity > 0,
      orElse: () => widget.items.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedItems = [...widget.items]
      ..sort((a, b) => (a.variantLabel ?? '').compareTo(b.variantLabel ?? ''));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.items.first.familyId != null) ...[
            _FamilyThumbnail(storeCode: widget.storeCode, familyId: widget.items.first.familyId!),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.items.first.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  widget.items.first.category,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text('اختر الحجم:', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedItems.map((item) {
                    final isSelected = item.internalCode == _selected.internalCode;
                    final isAvailable = item.stockQuantity > 0;
                    return ChoiceChip(
                      label: Text(item.variantLabel ?? item.name),
                      selected: isSelected,
                      onSelected: isAvailable ? (_) => setState(() => _selected = item) : null,
                      selectedColor: AppColors.navy,
                      disabledColor: AppColors.canvas,
                      labelStyle: TextStyle(
                        color: !isAvailable
                            ? AppColors.textMuted
                            : (isSelected ? Colors.white : AppColors.textPrimary),
                        fontWeight: FontWeight.w600,
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                      ),
                      backgroundColor: AppColors.canvas,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppColors.navy : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  _selected.stockQuantity > 0 ? 'المتوفر: ${_selected.stockQuantity}' : 'نفد المخزون من هذا الحجم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _selected.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selected.price.toCurrency(),
                        style: theme.textTheme.titleLarge?.copyWith(color: AppColors.navy),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _selected.stockQuantity > 0 ? () => widget.onAdd(_selected) : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(_selected.stockQuantity > 0 ? 'إضافة' : 'غير متوفر'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({required this.item, required this.storeCode, required this.onAdd});

  final StorePayloadItem item;
  final String storeCode;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = item.variantLabel == null || item.variantLabel!.isEmpty
        ? item.name
        : '${item.name} - ${item.variantLabel}';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.familyId != null) ...[
            _FamilyThumbnail(storeCode: storeCode, familyId: item.familyId!),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(item.category, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(
                  item.stockQuantity > 0 ? 'المتوفر: ${item.stockQuantity}' : 'نفد المخزون',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.price.toCurrency(),
                        style: theme.textTheme.titleLarge?.copyWith(color: AppColors.navy),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: item.stockQuantity > 0 ? onAdd : null,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(item.stockQuantity > 0 ? 'إضافة' : 'غير متوفر'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyThumbnail extends StatelessWidget {
  const _FamilyThumbnail({required this.storeCode, required this.familyId});

  final String storeCode;
  final int familyId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'https://atmina-store-api.o2730884.workers.dev/store/$storeCode/images/$familyId',
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 64,
            height: 64,
            color: AppColors.canvas,
            child: const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 22),
        ),
      ),
    );
  }
}
