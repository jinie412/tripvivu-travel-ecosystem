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

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterTouristUseCase registerTouristUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  }) : _loginUseCase = loginUseCase,
       _loginWithGoogleUseCase = loginWithGoogleUseCase,
       _registerTouristUseCase = registerTouristUseCase,
       _forgotPasswordUseCase = forgotPasswordUseCase,
       _updatePasswordUseCase = updatePasswordUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       super(const AuthInitial());

  // ── Login ──────────────────────────────────────────────────────────────────
  /// Token được lưu tự động trong RemoteAuthDataSource sau khi server xác thực.
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
      debugPrint('--- LỖI ĐĂNG NHẬP ---');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      // Báo lỗi thân thiện cho User
      emit(AuthError('Sai thông tin đăng nhập hoặc tài khoản không tồn tại.'));
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
      // Bắn log ra màn hình console cho dev
      debugPrint('=== LỖI ĐĂNG KÝ TÀI KHOẢN ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      // Hiển thị lỗi từ server cho người dùng (vd: Email đã tồn tại)
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
      debugPrint('=== LỖI QUÊN MẬT KHẨU ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Update Password (dùng accessToken từ deeplink) ─────────────────────────
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
      debugPrint('=== LỖI CẬP NHẬT MẬT KHẨU MỚI ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      emit(AuthError(_cleanMessage(e)));
    }
  }

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
      debugPrint('=== LỖI ĐỔI MẬT KHẨU ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      emit(AuthError(_cleanMessage(e)));
    }
  }

  // Trong AuthCubit
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final result = await _loginWithGoogleUseCase();
      emit(AuthSuccess(result));
    } catch (e, stackTrace) {
      // Log lỗi kỹ thuật (PlatformException, SupabaseException...) cho Dev
      debugPrint('--- LỖI ĐĂNG NHẬP GOOGLE ---');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      // Báo lỗi thân thiện cho User
      emit(AuthError('Đăng nhập Google thất bại. Vui lòng thử lại sau.'));
    }
  }

  void reset() => emit(const AuthInitial());

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
