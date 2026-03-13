import '../models/user_model.dart';

/// Contract for auth data operations.
/// [MockAuthDataSource] implements this now.
/// [RemoteAuthDataSource] will implement this when backend is ready.
abstract class AuthDataSource {
  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  });

  Future<UserModel> register({
    required String emailOrPhone,
    required String password,
  });

  Future<void> logout();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock implementation — simulates API with hardcoded credentials.
/// Replace with [RemoteAuthDataSource] in injection_container.dart.
// ─────────────────────────────────────────────────────────────────────────────
class MockAuthDataSource implements AuthDataSource {
  static const _mockEmail = 'demo@gp.com';
  static const _mockPassword = '123456';

  @override
  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (emailOrPhone.trim() != _mockEmail || password != _mockPassword) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
    return const UserModel(
      id: 'mock-001',
      email: _mockEmail,
      displayName: 'Người dùng Demo',
    );
  }

  @override
  Future<UserModel> register({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return UserModel(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      email: emailOrPhone.trim(),
      displayName: 'Người dùng mới',
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote implementation placeholder — activate when backend is ready.
/// Uncomment and inject [DioClient] in injection_container.dart.
// ─────────────────────────────────────────────────────────────────────────────
// class RemoteAuthDataSource implements AuthDataSource {
//   final DioClient _client;
//   RemoteAuthDataSource(this._client);
//
//   @override
//   Future<UserModel> login({required String emailOrPhone, required String password}) async {
//     final res = await _client.dio.post('/auth/login', data: {
//       'email_or_phone': emailOrPhone,
//       'password': password,
//     });
//     return UserModel.fromJson(res.data['user']);
//   }
//   ...
// }
