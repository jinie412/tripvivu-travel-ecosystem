/// Re-export AppTextStyles từ app_theme.dart (nơi class đang nằm).
export '../theme/app_theme.dart' show AppTextStyles;

import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

/// Bổ sung các TextStyle chưa có trong AppTextStyles gốc.
/// Sử dụng class riêng để không xung đột với class hiện tại.
class AppTextStylesExt {
  AppTextStylesExt._();

  /// 18sp, SemiBold — AppBar title, tiêu đề phụ
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// 16sp, Regular — nội dung chính, search hint
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// 14sp, Regular — alias cho body
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// 12sp, Regular — thông tin phụ
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// 10sp, Regular — bottom nav label
  static const TextStyle captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Color(0xFF9E9E9E),
  );

  /// 16sp, Bold, trắng — nút bấm
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// 9sp, SemiBold — "VỊ TRÍ CỦA BẠN" trong header
  static const TextStyle overline = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );
}