import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Use-case: Đăng nhập.
class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<LoginResult> call({
    required String emailOrPhone,
    required String password,
  }) {
    return _repository.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
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