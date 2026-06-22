import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_state.dart';
import 'package:travel_advisor_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter/foundation.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final RegisterTouristUseCase _registerTouristUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final CheckSessionUseCase _checkSessionUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterTouristUseCase registerTouristUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required CheckSessionUseCase checkSessionUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _registerTouristUseCase = registerTouristUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _updatePasswordUseCase = updatePasswordUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        _checkSessionUseCase = checkSessionUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthInitial());

  // ── Session ────────────────────────────────────────────────────────────────

  /// Kiểm tra session khi app khởi động.
  /// Emit [AuthChecking] → [AuthAuthenticated] hoặc [AuthUnauthenticated].
  Future<void> checkSession() async {
    emit(const AuthChecking());
    try {
      final user = await _checkSessionUseCase();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Đăng xuất: xóa token, signOut Supabase, emit [AuthUnauthenticated].
  Future<void> logout() async {
    try {
      await _logoutUseCase();
    } catch (e) {
      debugPrint('=== LỖI ĐĂNG XUẤT ===\n$e');
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _loginUseCase(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      emit(AuthSuccess(result));
    } catch (e, stackTrace) {
     debugPrint('--- LỖI ĐĂNG NHẬP ---\n$e\n$stackTrace');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final result = await _loginWithGoogleUseCase();
      emit(AuthSuccess(result));
    } catch (e, stackTrace) {
      debugPrint('--- LỖI ĐĂNG NHẬP GOOGLE ---\n$e\n$stackTrace');
      emit(AuthError('Đăng nhập Google thất bại. Vui lòng thử lại sau.'));
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _registerTouristUseCase(
        fullName: fullName,
        gender: gender,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      emit(const RegisterSuccess());
    } catch (e, stackTrace) {
      debugPrint('=== LỖI ĐĂNG KÝ TÀI KHOẢN ===\n$e\n$stackTrace');
      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  Future<void> forgotPassword(String email) async {
    emit(const AuthLoading());
    try {
      final message = await _forgotPasswordUseCase(email);
      emit(ForgotPasswordSuccess(message));
    } catch (e, stackTrace) {
      debugPrint('=== LỖI QUÊN MẬT KHẨU ===\n$e\n$stackTrace');
      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Update Password (deeplink) ─────────────────────────────────────────────

  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      await _updatePasswordUseCase(
        accessToken: accessToken,
        newPassword: newPassword,
      );
      emit(const UpdatePasswordSuccess());
    } catch (e, stackTrace) {
      debugPrint('=== LỖI CẬP NHẬT MẬT KHẨU MỚI ===\n$e\n$stackTrace');
      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      final message = await _changePasswordUseCase(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(ChangePasswordSuccess(message));
    } catch (e, stackTrace) {
      debugPrint('=== LỖI ĐỔI MẬT KHẨU ===\n$e\n$stackTrace');
      emit(AuthError(_cleanMessage(e)));
    }
  }

  void reset() => emit(const AuthInitial());

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
