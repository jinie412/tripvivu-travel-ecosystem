/// Re-export toàn bộ AppColors từ theme để giữ tương thích import cũ.
/// Bổ sung thêm các màu hardcoded phổ biến trong features/.
export '../theme/app_colors.dart';

import 'package:flutter/material.dart';

/// Các màu bổ sung tìm thấy trong features/ — chưa có trong AppColors gốc.
class AppColorsExt {
  AppColorsExt._();

  /// Màu chữ đậm sử dụng ở Profile, Support, Edit
  static const Color textDark = Color(0xFF113D3C);

  /// Hint / placeholder / inactive bottom nav
  static const Color textHint = Color(0xFF9E9E9E);

  /// Chip sở thích active (Edit Profile)
  static const Color chipActive = Color(0xFF14DFBC);

  /// Giá trị profile (tên, SĐT khi không edit)
  static const Color profileBlue = Color(0xFF50B5D9);

  /// Giá trị profile khi đang edit
  static const Color profileEditBlue = Color(0xFF1A6EBD);

  /// Lỗi / validation
  static const Color error = Color(0xFFE53935);

  /// Đường phân cách
  static const Color divider = Color(0xFFE0E0E0);

  /// Nền thanh tìm kiếm
  static const Color searchBarBg = Color(0xFFF1F3F4);

  /// Badge thông báo
  static const Color notificationDot = Color(0xFFFF0000);

  /// Auth background blobs
  static const Color authBgLight = Color(0xFFEBF5FF);
}
