import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/application/product_view_mode.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../domain/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    this.familyImagePath,
    this.mode = ProductViewMode.comfortable,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;

  /// صورة "عائلة المنتج" التي ينتمي إليها هذا المنتج، تُستخدم كبديل
  /// عند عدم وجود صورة خاصة بهذا المنتج تحديدًا.
  final String? familyImagePath;

  /// طريقة العرض التي اختارها التاجر بحرية (مريح / مضغوط / شبكي).
  final ProductViewMode mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ProductViewMode.comfortable:
        return _ComfortableProductCard(
          product: product,
          onAdd: onAdd,
          onUpdateStock: onUpdateStock,
          onDelete: onDelete,
          imagePath: product.imagePath ?? familyImagePath,
        );
      case ProductViewMode.compact:
        return _CompactProductRow(
          product: product,
          onAdd: onAdd,
          onUpdateStock: onUpdateStock,
          onDelete: onDelete,
          imagePath: product.imagePath ?? familyImagePath,
        );
      case ProductViewMode.grid:
        return _GridProductTile(
          product: product,
          onAdd: onAdd,
          onUpdateStock: onUpdateStock,
          onDelete: onDelete,
          imagePath: product.imagePath ?? familyImagePath,
        );
    }
  }
}

enum _ProductMenuAction { updateStock, delete }

List<PopupMenuEntry<_ProductMenuAction>> _menuEntries() => const [
      PopupMenuItem(
        value: _ProductMenuAction.updateStock,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.inventory_2_outlined),
          title: Text('تحديث المخزون'),
        ),
      ),
      PopupMenuItem(
        value: _ProductMenuAction.delete,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.delete_outline_rounded),
          title: Text('حذف المنتج'),
        ),
      ),
    ];

void _handleMenuAction(_ProductMenuAction action, VoidCallback onUpdateStock, VoidCallback onDelete) {
  switch (action) {
    case _ProductMenuAction.updateStock:
      onUpdateStock();
    case _ProductMenuAction.delete:
      onDelete();
  }
}

/// الشكل الافتراضي الكامل: صورة، فئة، كمية، سعر وزر إضافة كبير.
class _ComfortableProductCard extends StatelessWidget {
  const _ComfortableProductCard({
    required this.product,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    required this.imagePath,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagePath != null) ...[
                _ProductThumb(path: imagePath, size: 52),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(product.name, style: theme.textTheme.titleMedium?.copyWith(height: 1.35)),
              ),
              PopupMenuButton<_ProductMenuAction>(
                tooltip: 'إدارة المنتج',
                onSelected: (action) => _handleMenuAction(action, onUpdateStock, onDelete),
                itemBuilder: (context) => _menuEntries(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              product.category,
              style: theme.textTheme.labelLarge?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          _MetaChip(
            icon: product.stockQuantity > 0 ? Icons.inventory_2_outlined : Icons.warning_amber_rounded,
            label: product.stockQuantity > 0 ? 'المخزون: ${product.stockQuantity}' : 'نفد المخزون',
            accentColor: product.stockQuantity > 0 ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.price.toCurrency(),
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColors.navy),
                ),
              ),
              FilledButton.icon(
                onPressed: product.stockQuantity > 0 ? onAdd : null,
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
    );
  }
}

/// شكل مضغوط: صف أفقي رفيع لكل منتج، يسمح برؤية عدد أكبر من المنتجات
/// دفعة واحدة دون الحاجة للتمرير كثيرًا.
class _CompactProductRow extends StatelessWidget {
  const _CompactProductRow({
    required this.product,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    required this.imagePath,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
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
          _ProductThumb(path: imagePath, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  product.stockQuantity > 0 ? 'متوفر: ${product.stockQuantity}' : 'نفد المخزون',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: product.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            product.price.toCurrency(),
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: product.stockQuantity > 0 ? onAdd : null,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            color: AppColors.navy,
            tooltip: 'إضافة',
          ),
          PopupMenuButton<_ProductMenuAction>(
            tooltip: 'إدارة المنتج',
            padding: EdgeInsets.zero,
            onSelected: (action) => _handleMenuAction(action, onUpdateStock, onDelete),
            itemBuilder: (context) => _menuEntries(),
          ),
        ],
      ),
    );
  }
}

/// شكل شبكي: بطاقة صغيرة تُعرض جنبًا إلى جنب مع بطاقة أخرى، مناسبة
/// لمن يريد أصغر مساحة ممكنة لكل منتج مع رؤية شبكية سريعة.
class _GridProductTile extends StatelessWidget {
  const _GridProductTile({
    required this.product,
    required this.onAdd,
    required this.onUpdateStock,
    required this.onDelete,
    required this.imagePath,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: _ProductThumb(path: imagePath, size: 56, radius: 12)),
              PopupMenuButton<_ProductMenuAction>(
                tooltip: 'إدارة المنتج',
                padding: EdgeInsets.zero,
                iconSize: 18,
                onSelected: (action) => _handleMenuAction(action, onUpdateStock, onDelete),
                itemBuilder: (context) => _menuEntries(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            product.stockQuantity > 0 ? 'متوفر: ${product.stockQuantity}' : 'نفد',
            style: theme.textTheme.labelSmall?.copyWith(
              color: product.stockQuantity > 0 ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.price.toCurrency(),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.navy, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: product.stockQuantity > 0 ? onAdd : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: product.stockQuantity > 0 ? AppColors.navy : AppColors.border,
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.path, required this.size, this.radius = 14});

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
