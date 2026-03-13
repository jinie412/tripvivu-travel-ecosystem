import '../entities/user_entity.dart';

/// Contract for auth operations.
/// Presentation layer depends ONLY on this interface — never on implementation.
/// Swap mock → real API by changing only the data layer.
abstract class AuthRepository {
  /// Returns [UserEntity] on success, throws [Exception] on failure.
  Future<UserEntity> login({
    required String emailOrPhone,
    required String password,
  });

  Future<UserEntity> register({
    required String emailOrPhone,
    required String password,
  });

  Future<void> logout();
}
