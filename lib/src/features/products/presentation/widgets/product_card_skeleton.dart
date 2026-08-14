import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.85),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(height: 18, width: 220),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _Block(height: 44)),
                    SizedBox(width: 10),
                    Expanded(child: _Block(height: 44)),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _Block(height: 24, width: 100),
                    Spacer(),
                    _Block(height: 48, width: 116),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.height,
    this.width = double.infinity,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
