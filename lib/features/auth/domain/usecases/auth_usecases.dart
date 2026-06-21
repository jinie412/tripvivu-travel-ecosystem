import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Use-case: Đăng nhập.
class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<LoginResult> call({
    required String emailOrPhone,
    required String password,
  }) {
    return _repository.login(emailOrPhone: emailOrPhone, password: password);
  }
}

/// Use-case: Đăng ký tài khoản du khách.
class RegisterTouristUseCase {
  final AuthRepository _repository;
  RegisterTouristUseCase(this._repository);

  Future<void> call({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) {
    return _repository.registerTourist(
      fullName: fullName,
      gender: gender,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}

/// Use-case: Gửi email magic link quên mật khẩu.
class ForgotPasswordUseCase {
  final AuthRepository _repository;
  ForgotPasswordUseCase(this._repository);

  Future<String> call(String email) {
    return _repository.forgotPassword(email);
  }
}

/// Use-case: Đặt lại mật khẩu mới với token từ deeplink.
class UpdatePasswordUseCase {
  final AuthRepository _repository;
  UpdatePasswordUseCase(this._repository);

  Future<void> call({
    required String accessToken,
    required String newPassword,
  }) {
    return _repository.updatePassword(
      accessToken: accessToken,
      newPassword: newPassword,
    );
  }
}

/// Use-case: Đổi mật khẩu trong app.
class ChangePasswordUseCase {
  final AuthRepository _repository;
  ChangePasswordUseCase(this._repository);

  Future<String> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

/// Use-case: Đăng nhập bằng Google.
class LoginWithGoogleUseCase {
  final AuthRepository repository;
  LoginWithGoogleUseCase(this.repository);

  Future<LoginResult> call() async {
    return await repository.loginWithGoogle();
  }
}

/// Use-case: Kiểm tra và khôi phục session khi app khởi động.
/// Trả về UserEntity nếu session hợp lệ, null nếu chưa đăng nhập.
class CheckSessionUseCase {
  final AuthRepository _repository;
  CheckSessionUseCase(this._repository);

  Future<UserEntity?> call() => _repository.checkSession();
}

/// Use-case: Đăng xuất — xóa token, signOut Supabase.
class LogoutUseCase {
  final AuthRepository _repository;
  LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}
