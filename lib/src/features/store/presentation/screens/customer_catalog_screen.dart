import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/application/product_view_mode.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../../../core/widgets/view_mode_switcher.dart';
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
    final viewMode = ref.watch(customerViewModeProvider).valueOrNull ?? ProductViewMode.comfortable;

    void addToCart(StorePayloadItem item) {
      final added = ref.read(cartControllerProvider.notifier).addProduct(productFromCatalogItem(item));
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن تجاوز الكمية المتاحة من "${item.name}"')),
        );
      }
    }

    Widget buildTile(int index) {
      final group = groups[index];
      if (group.length > 1) {
        return _VariantGroupCard(
          items: group,
          storeCode: payload.storeCode,
          onAdd: addToCart,
          mode: viewMode,
        );
      }
      return _CatalogItemCard(
        item: group.first,
        storeCode: payload.storeCode,
        onAdd: () => addToCart(group.first),
        mode: viewMode,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(payload.storeName.isEmpty ? 'متجر ${payload.storeCode}' : payload.storeName),
        actions: [
          ViewModeSwitcher(
            mode: viewMode,
            onChanged: (mode) => ref.read(customerViewModeProvider.notifier).setMode(mode),
          ),
        ],
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
            : viewMode == ProductViewMode.grid
                ? GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) => buildTile(index),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                    itemCount: groups.length,
                    itemBuilder: (context, index) => buildTile(index),
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
/// تدعم أوضاع العرض الثلاثة (مريح/مضغوط/شبكي) حسب اختيار الزبون.
class _VariantGroupCard extends StatefulWidget {
  const _VariantGroupCard({
    required this.items,
    required this.storeCode,
    required this.onAdd,
    required this.mode,
  });

  final List<StorePayloadItem> items;
  final String storeCode;
  final void Function(StorePayloadItem item) onAdd;
  final ProductViewMode mode;

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

  List<StorePayloadItem> get _sorted {
    final sortedItems = [...widget.items]
      ..sort((a, b) => (a.variantLabel ?? '').compareTo(b.variantLabel ?? ''));
    return sortedItems;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ProductViewMode.comfortable:
        return _buildComfortable(context);
      case ProductViewMode.compact:
        return _buildCompact(context);
      case ProductViewMode.grid:
        return _buildGrid(context);
    }
  }

  Widget _buildComfortable(BuildContext context) {
    final theme = Theme.of(context);

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
            _FamilyThumbnail(storeCode: widget.storeCode, familyId: widget.items.first.familyId!, size: 64),
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
                _chips(),
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

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.items.first.familyId != null) ...[
                _FamilyThumbnail(storeCode: widget.storeCode, familyId: widget.items.first.familyId!, size: 38),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.items.first.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _selected.price.toCurrency(),
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: _selected.stockQuantity > 0 ? () => widget.onAdd(_selected) : null,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                color: AppColors.navy,
                tooltip: 'إضافة',
              ),
            ],
          ),
          const SizedBox(height: 6),
          _chips(dense: true),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.items.first.familyId != null)
            _FamilyThumbnail(storeCode: widget.storeCode, familyId: widget.items.first.familyId!, size: 56, radius: 12),
          const SizedBox(height: 4),
          Text(
            widget.items.first.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 4),
          SizedBox(height: 26, child: _chips(dense: true, scrollable: true)),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selected.price.toCurrency(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _selected.stockQuantity > 0 ? () => widget.onAdd(_selected) : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _selected.stockQuantity > 0 ? AppColors.navy : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chips({bool dense = false, bool scrollable = false}) {
    final chips = _sorted.map((item) {
      final isSelected = item.internalCode == _selected.internalCode;
      final isAvailable = item.stockQuantity > 0;
      return ChoiceChip(
        label: Text(item.variantLabel ?? item.name, style: dense ? const TextStyle(fontSize: 11) : null),
        selected: isSelected,
        visualDensity: dense ? VisualDensity.compact : null,
        materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
        onSelected: isAvailable ? (_) => setState(() => _selected = item) : null,
        selectedColor: AppColors.navy,
        disabledColor: AppColors.canvas,
        labelStyle: TextStyle(
          color: !isAvailable ? AppColors.textMuted : (isSelected ? Colors.white : AppColors.textPrimary),
          fontWeight: FontWeight.w600,
          decoration: isAvailable ? null : TextDecoration.lineThrough,
        ),
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.navy : AppColors.border),
        ),
      );
    }).toList();

    if (scrollable) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: chips.map((chip) => Padding(padding: const EdgeInsets.only(left: 4), child: chip)).toList(),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _CatalogItemCard extends StatelessWidget {
  const _CatalogItemCard({
    required this.item,
    required this.storeCode,
    required this.onAdd,
    required this.mode,
  });

  final StorePayloadItem item;
  final String storeCode;
  final VoidCallback onAdd;
  final ProductViewMode mode;

  String get _displayName => item.variantLabel == null || item.variantLabel!.isEmpty
      ? item.name
      : '${item.name} - ${item.variantLabel}';

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ProductViewMode.comfortable:
        return _buildComfortable(context);
      case ProductViewMode.compact:
        return _buildCompact(context);
      case ProductViewMode.grid:
        return _buildGrid(context);
    }
  }

  Widget _buildComfortable(BuildContext context) {
    final theme = Theme.of(context);
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
            _FamilyThumbnail(storeCode: storeCode, familyId: item.familyId!, size: 64),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName, style: theme.textTheme.titleMedium),
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

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (item.familyId != null) ...[
            _FamilyThumbnail(storeCode: storeCode, familyId: item.familyId!, size: 38),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  item.stockQuantity > 0 ? 'متوفر: ${item.stockQuantity}' : 'نفد المخزون',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.price.toCurrency(),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: item.stockQuantity > 0 ? onAdd : null,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            color: AppColors.navy,
            tooltip: 'إضافة',
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.familyId != null) _FamilyThumbnail(storeCode: storeCode, familyId: item.familyId!, size: 56, radius: 12),
          const SizedBox(height: 4),
          Text(
            _displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            item.stockQuantity > 0 ? 'متوفر: ${item.stockQuantity}' : 'نفد',
            style: theme.textTheme.labelSmall?.copyWith(
              color: item.stockQuantity > 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.price.toCurrency(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: item.stockQuantity > 0 ? onAdd : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.stockQuantity > 0 ? AppColors.navy : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyThumbnail extends StatelessWidget {
  const _FamilyThumbnail({
    required this.storeCode,
    required this.familyId,
    this.size = 64,
    this.radius = 16,
  });

  final String storeCode;
  final int familyId;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        'https://atmina-svc.o2730884.workers.dev/store/$storeCode/images/$familyId',
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.canvas,
            child: const Center(
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(radius)),
          child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: size * 0.35),
        ),
      ),
    );
  }
}
