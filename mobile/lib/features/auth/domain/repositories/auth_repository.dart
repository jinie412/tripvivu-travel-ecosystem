import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';

/// Contract for auth operations.
/// Presentation layer depends ONLY on this interface — never on implementation.
abstract class AuthRepository {
  /// Đăng nhập bằng email/SĐT + password.
  /// Token được lưu tự động vào SecureStorage trong datasource.
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  });

  /// Đăng ký tài khoản du khách.
  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Gửi email magic link khôi phục mật khẩu. Trả về message thành công.
  Future<String> forgotPassword(String email);

  /// Đặt lại mật khẩu mới bằng accessToken từ deeplink email.
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  });

  /// Đổi mật khẩu trong app bằng mật khẩu hiện tại.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Đăng nhập bằng Google.
  Future<LoginResult> loginWithGoogle();

  /// Khôi phục session từ storage khi app khởi động.
  /// Tự động refresh token nếu cần.
  /// Trả về UserEntity nếu hợp lệ, null nếu chưa đăng nhập hoặc token hết hạn.
  Future<UserEntity?> checkSession();

  /// Đăng xuất: xóa token, signOut Supabase.
  Future<void> logout();
}
