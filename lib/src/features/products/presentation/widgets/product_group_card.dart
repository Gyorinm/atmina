import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_family.dart';

/// بطاقة موحّدة لعرض "عائلة منتج" واحدة تحمل أكثر من حجم/متغيّر لدى
/// التاجر، بنفس شكل ظهورها لدى الزبون (صورة واحدة + اختيار الحجم عبر
/// شرائح)، بدل تكرار نفس المنتج في عدة بطاقات مستقلة. بخلاف واجهة
/// الزبون، يحتفظ التاجر هنا بصلاحيات الإدارة (تحديث الكمية والسعر،
/// الحذف) للحجم المختار حاليًا.
class ProductGroupCard extends StatefulWidget {
  const ProductGroupCard({
    super.key,
    required this.products,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    this.family,
  });

  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onUpdateStock;
  final ValueChanged<Product> onDelete;

  /// عائلة المنتج (تحمل الصورة المشتركة)، قد تكون null إن لم تُحمَّل بعد.
  final ProductFamily? family;

  @override
  State<ProductGroupCard> createState() => _ProductGroupCardState();
}

class _ProductGroupCardState extends State<ProductGroupCard> {
  late Product _selected;

  @override
  void initState() {
    super.initState();
    _selected = _pickDefault();
  }

  @override
  void didUpdateWidget(covariant ProductGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // نحافظ على نفس الحجم المختار بعد أي تحديث (كمية/سعر) بمطابقة الـ id،
    // وإلا نعيد اختيار حجم افتراضي (مثلًا بعد حذف الحجم المختار).
    final stillExists = widget.products.where((p) => p.id == _selected.id);
    _selected = stillExists.isNotEmpty ? stillExists.first : _pickDefault();
  }

  Product _pickDefault() {
    return widget.products.firstWhere(
      (p) => p.stockQuantity > 0,
      orElse: () => widget.products.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedProducts = [...widget.products]
      ..sort((a, b) => (a.variantLabel ?? '').compareTo(b.variantLabel ?? ''));
    final effectiveImagePath = _selected.imagePath ?? widget.family?.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (effectiveImagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(effectiveImagePath),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52,
                  height: 52,
                  color: AppColors.canvas,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _selected.name,
                        style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
                      ),
                    ),
                    PopupMenuButton<_GroupMenuAction>(
                      tooltip: 'إدارة المنتج',
                      onSelected: (action) {
                        switch (action) {
                          case _GroupMenuAction.updateStock:
                            widget.onUpdateStock(_selected);
                          case _GroupMenuAction.delete:
                            widget.onDelete(_selected);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _GroupMenuAction.updateStock,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.inventory_2_outlined),
                            title: Text('تحديث الكمية والسعر'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _GroupMenuAction.delete,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline_rounded),
                            title: Text('حذف هذا الحجم'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selected.category,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('اختر الحجم:', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sortedProducts.map((product) {
                    final isSelected = product.id == _selected.id;
                    final isAvailable = product.stockQuantity > 0;
                    return ChoiceChip(
                      label: Text(product.variantLabel ?? product.name),
                      selected: isSelected,
                      // بخلاف واجهة الزبون، يمكن للتاجر اختيار حجم نافد أيضًا
                      // ليتمكن من تعديل كميته أو سعره من قائمة الإدارة.
                      onSelected: (_) => setState(() => _selected = product),
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
                const SizedBox(height: 12),
                _MetaChip(
                  icon: _selected.stockQuantity > 0 ? Icons.inventory_2_outlined : Icons.warning_amber_rounded,
                  label: _selected.stockQuantity > 0
                      ? 'المخزون: ${_selected.stockQuantity}'
                      : 'نفد المخزون من هذا الحجم',
                  accentColor: _selected.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(height: 16),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('إضافة'),
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

enum _GroupMenuAction { updateStock, delete }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.accentColor = AppColors.accent,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
