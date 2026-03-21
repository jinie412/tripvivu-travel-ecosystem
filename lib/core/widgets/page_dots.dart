import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int current;

  const PageDots({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
