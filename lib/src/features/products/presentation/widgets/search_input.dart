import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو التصنيف',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: () {
              controller.clear();
              onChanged('');
            },
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }
}
