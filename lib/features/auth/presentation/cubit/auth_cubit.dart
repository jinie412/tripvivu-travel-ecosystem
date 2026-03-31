import 'auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/auth/domain/usecases/auth_usecases.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        super(const AuthInitial());

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _loginUseCase(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> register({
    required String emailOrPhone,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _registerUseCase(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void reset() => emit(const AuthInitial());
}