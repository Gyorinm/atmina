import 'dart:io';

import 'package:flutter/material.dart';

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
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onUpdateStock;
  final VoidCallback onDelete;

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
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(product.imagePath!),
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
                child: Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.35),
                ),
              ),
              PopupMenuButton<_ProductMenuAction>(
                tooltip: 'إدارة المنتج',
                onSelected: (action) {
                  switch (action) {
                    case _ProductMenuAction.updateStock:
                      onUpdateStock();
                    case _ProductMenuAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
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
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              product.category,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _MetaChip(
            icon: product.stockQuantity > 0
                ? Icons.inventory_2_outlined
                : Icons.warning_amber_rounded,
            label: product.stockQuantity > 0
                ? 'المخزون: ${product.stockQuantity}'
                : 'نفد المخزون',
            accentColor: product.stockQuantity > 0
                ? AppColors.success
                : AppColors.danger,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.price.toCurrency(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: product.stockQuantity > 0 ? onAdd : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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

enum _ProductMenuAction {
  updateStock,
  delete,
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
