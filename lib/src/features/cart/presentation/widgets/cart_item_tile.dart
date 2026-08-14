import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_formatting.dart';
import '../../application/cart_controller.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartLine item;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.product.barcode,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'المتوفر في المخزون: ${item.product.stockQuantity}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.lineTotal.toCurrency(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.remove_rounded,
                onPressed: onDecrement,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${item.quantity}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onPressed: canIncrement ? onIncrement : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? AppColors.border
          : AppColors.navy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: onPressed == null ? AppColors.textMuted : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
