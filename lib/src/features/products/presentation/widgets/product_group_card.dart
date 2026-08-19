import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/application/product_view_mode.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_family.dart';

/// بطاقة موحّدة لعرض "عائلة منتج" واحدة تحمل أكثر من حجم/متغيّر لدى
/// التاجر، بنفس شكل ظهورها لدى الزبون (صورة واحدة + اختيار الحجم عبر
/// شرائح)، بدل تكرار نفس المنتج في عدة بطاقات مستقلة. بخلاف واجهة
/// الزبون، يحتفظ التاجر هنا بصلاحيات الإدارة (تحديث الكمية والسعر،
/// الحذف) للحجم المختار حاليًا. تدعم أيضًا أوضاع العرض المريح/المضغوط
/// /الشبكي حسب اختيار التاجر.
class ProductGroupCard extends StatefulWidget {
  const ProductGroupCard({
    super.key,
    required this.products,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    this.family,
    this.mode = ProductViewMode.comfortable,
  });

  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onUpdateStock;
  final ValueChanged<Product> onDelete;

  /// عائلة المنتج (تحمل الصورة المشتركة)، قد تكون null إن لم تُحمَّل بعد.
  final ProductFamily? family;

  final ProductViewMode mode;

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

  List<Product> get _sorted {
    final sortedProducts = [...widget.products]
      ..sort((a, b) => (a.variantLabel ?? '').compareTo(b.variantLabel ?? ''));
    return sortedProducts;
  }

  String? get _imagePath => _selected.imagePath ?? widget.family?.imagePath;

  void _select(Product product) => setState(() => _selected = product);

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
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_imagePath != null) ...[
            _Thumb(path: _imagePath, size: 52),
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
                      child: Text(_selected.name, style: theme.textTheme.titleMedium?.copyWith(height: 1.35)),
                    ),
                    _menuButton(),
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
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text('اختر الحجم:', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                _variantChips(),
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
              _Thumb(path: _imagePath, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selected.name,
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
              _menuButton(),
            ],
          ),
          const SizedBox(height: 6),
          _variantChips(dense: true),
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
          Row(
            children: [
              Expanded(child: _Thumb(path: _imagePath, size: 56, radius: 12)),
              _menuButton(iconSize: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selected.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _sorted.map((product) {
                final isSelected = product.id == _selected.id;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text(product.variantLabel ?? product.name, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) => _select(product),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                    backgroundColor: AppColors.canvas,
                  ),
                );
              }).toList(),
            ),
          ),
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

  Widget _variantChips({bool dense = false}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _sorted.map((product) {
        final isSelected = product.id == _selected.id;
        final isAvailable = product.stockQuantity > 0;
        return ChoiceChip(
          label: Text(product.variantLabel ?? product.name),
          selected: isSelected,
          visualDensity: dense ? VisualDensity.compact : null,
          materialTapTargetSize: dense ? MaterialTapTargetSize.shrinkWrap : null,
          onSelected: (_) => _select(product),
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
      }).toList(),
    );
  }

  Widget _menuButton({double? iconSize}) {
    return PopupMenuButton<_GroupMenuAction>(
      tooltip: 'إدارة المنتج',
      padding: EdgeInsets.zero,
      iconSize: iconSize,
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
    );
  }
}

enum _GroupMenuAction { updateStock, delete }

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.size, this.radius = 14});

  final String? path;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(radius)),
        child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: size * 0.4),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppColors.canvas,
          child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: size * 0.4),
        ),
      ),
    );
  }
}

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
