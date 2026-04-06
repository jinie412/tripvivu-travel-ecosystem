import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_state.dart';
import 'package:travel_advisor_mobile/features/auth/domain/usecases/auth_usecases.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterTouristUseCase _registerTouristUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterTouristUseCase registerTouristUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerTouristUseCase = registerTouristUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _updatePasswordUseCase = updatePasswordUseCase,
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
    } catch (e) {
      emit(AuthError(_cleanMessage(e)));
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
    } catch (e) {
      emit(AuthError(_cleanMessage(e)));
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    emit(const AuthLoading());
    try {
      final message = await _forgotPasswordUseCase(email);
      emit(ForgotPasswordSuccess(message));
    } catch (e) {
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
    } catch (e) {
      emit(AuthError(_cleanMessage(e)));
    }
  }

  void reset() => emit(const AuthInitial());

  String _cleanMessage(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}