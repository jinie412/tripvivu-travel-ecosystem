/// Hằng số kích thước chuẩn cho toàn bộ ứng dụng.
/// Tuân theo Material Design 3 — 4dp grid system.
class AppSizes {
  AppSizes._();

  // ─── Spacing ──────────────────────────────────────────────────────
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;
  static const double s80 = 80.0;
  static const double s100 = 100.0;

  // ─── Border Radius ────────────────────────────────────────────────
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  // ─── Component Sizes (chuẩn Android) ──────────────────────────────
  /// ElevatedButton height chuẩn (Material: 40-56dp)
  static const double buttonHeight = 52.0;

  /// TextField height
  static const double inputHeight = 52.0;

  /// AppBar height chuẩn Android
  static const double appBarHeight = 56.0;

  /// BottomNavigationBar height (Material 3: 80dp)
  static const double bottomNavHeight = 80.0;

  /// FAB size ở bottom nav
  static const double fabSize = 44.0;

  /// Nút tròn (header icon buttons)
  static const double iconButtonSize = 40.0;

  /// Thanh tìm kiếm height
  static const double searchBarHeight = 48.0;

  /// Avatar sizes
  static const double avatarSmall = 40.0;
  static const double avatarMedium = 64.0;
  static const double avatarLarge = 92.0;

  // ─── Icon Sizes (Material 3) ──────────────────────────────────────
  /// 14dp — location indicator, lock icon
  static const double iconXs = 14.0;

  /// 16dp — compact icons
  static const double iconSm = 16.0;

  /// 20dp — default thin icons (search, edit, etc.)
  static const double iconMd = 20.0;

  /// 24dp — Material 3 default icon size
  static const double iconDefault = 24.0;

  /// 28dp — emphasis icons (menu items)
  static const double iconLg = 28.0;
}