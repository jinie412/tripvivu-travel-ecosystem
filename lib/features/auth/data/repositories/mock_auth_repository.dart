import 'package:travel_advisor_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository].
/// Depends on [AuthDataSource] — swap Mock ↔ Remote in injection_container.dart.
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final model = await _dataSource.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String emailOrPhone,
    required String password,
  }) async {
    final model = await _dataSource.register(
      emailOrPhone: emailOrPhone,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<void> logout() => _dataSource.logout();
}