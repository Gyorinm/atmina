import 'package:flutter/material.dart';

import '../application/product_view_mode.dart';

/// زر في الشريط العلوي يتيح للمستخدم (تاجر أو زبون) اختيار طريقة عرض
/// المنتجات بحرية كاملة من بين كل الطرق المتاحة.
class ViewModeSwitcher extends StatelessWidget {
  const ViewModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ProductViewMode mode;
  final ValueChanged<ProductViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductViewMode>(
      tooltip: 'طريقة العرض: ${mode.label}',
      icon: Icon(mode.icon),
      onSelected: onChanged,
      itemBuilder: (context) => ProductViewMode.values
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.icon,
                  color: option == mode ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: option == mode ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: option == mode ? const Icon(Icons.check_rounded, size: 18) : null,
              ),
            ),
          )
          .toList(),
    );
  }
}
