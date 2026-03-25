import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Nút bấm chuẩn cho toàn bộ ứng dụng.
/// Hỗ trợ primary, secondary, loading state và tùy chỉnh màu sắc.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double? width;
  final double height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.width,
    this.height = AppSizes.buttonHeight,
    this.borderRadius,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        (isSecondary ? AppColors.surface : AppColors.primary);
    final fgColor = textColor ??
        (isSecondary ? AppColors.primary : Colors.white);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.6),
          elevation: 0,
          side: isSecondary
              ? const BorderSide(color: AppColors.primary, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(borderRadius ?? AppSizes.r12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStylesExt.button.copyWith(color: fgColor),
              ),
      ),
    );
  }
}
