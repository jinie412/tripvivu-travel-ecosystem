import 'package:travel_advisor_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    return _dataSource.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
  }

  @override
  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    await _dataSource.registerTourist(
      fullName: fullName,
      gender: gender,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
  }

  @override
  Future<String> forgotPassword(String email) {
    return _dataSource.forgotPassword(email);
  }

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) {
    return _dataSource.updatePassword(
      accessToken: accessToken,
      newPassword: newPassword,
    );
  }
}
