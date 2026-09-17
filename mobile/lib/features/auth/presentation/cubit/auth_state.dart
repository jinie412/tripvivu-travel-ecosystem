import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

// ── Session states (dùng cho AuthGate) ──────────────────────────────────────

/// App đang kiểm tra session trong storage — hiển thị splash screen.
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// Session hợp lệ — user đã đăng nhập (từ storage hoặc login thủ công).
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// Không có session hợp lệ — điều hướng về LoginScreen.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// ── Action states (dùng cho LoginScreen, RegisterScreen, v.v.) ──────────────

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login thành công — chứa user info và tokens
class AuthSuccess extends AuthState {
  final LoginResult result;
  const AuthSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

/// Đăng ký thành công (cần xác thực email)
class RegisterSuccess extends AuthState {
  const RegisterSuccess();
}

/// Gửi email quên mật khẩu thành công
class ForgotPasswordSuccess extends AuthState {
  final String message;
  const ForgotPasswordSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// Đặt lại mật khẩu thành công
class UpdatePasswordSuccess extends AuthState {
  const UpdatePasswordSuccess();
}

/// Đổi mật khẩu thành công
class ChangePasswordSuccess extends AuthState {
  final String message;
  const ChangePasswordSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
