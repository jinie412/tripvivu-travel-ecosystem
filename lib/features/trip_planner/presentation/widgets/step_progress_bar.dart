import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: index == 1 ? 4 : 0)
                .copyWith(
                  left: index == 0 ? 0 : 4,
                  right: index == totalSteps - 1 ? 0 : 4,
                ),
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.premiumBlue
                  : AppColors.premiumBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
