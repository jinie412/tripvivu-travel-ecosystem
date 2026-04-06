import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/auth/data/models/user_model.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Contract for auth data operations.
// ─────────────────────────────────────────────────────────────────────────────
abstract class AuthDataSource {
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  });

  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<String> forgotPassword(String email);

  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote implementation — calls the real NestJS backend.
// ─────────────────────────────────────────────────────────────────────────────
class RemoteAuthDataSource implements AuthDataSource {
  final DioClient _client;
  final FlutterSecureStorage _storage;

  RemoteAuthDataSource(this._client,
      {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );
      // Response: { message, accessToken, refreshToken, user: {...} }
      final data = res.data as Map<String, dynamic>;

      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      // Lưu tokens vào SecureStorage
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      return LoginResult(
        user: user.toEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đăng nhập thất bại';
      throw Exception(msg);
    }
  }

  @override
  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      await _client.dio.post(
        '/auth/register/tourist',
        data: {
          'fullName': fullName,
          'gender': gender,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đăng ký thất bại';
      throw Exception(msg);
    }
  }

  @override
Future<String> forgotPassword(String email) async {
  try {
    final res = await _client.dio.post(
      '/auth/forgot-password',
      data: {
        'email': email,
        'returnUrl': 'gptraveladvisor://reset-password', 
      },
    );
    return (res.data['message'] as String?) ??
        'Vui lòng kiểm tra hộp thư email';
  } on DioException catch (e) {
    final msg =
        e.response?.data?['message'] ?? 'Không thể gửi email khôi phục';
    throw Exception(msg);
  }
}
  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        '/auth/update-password',
        data: {
          'accessToken': accessToken,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đổi mật khẩu thất bại';
      throw Exception(msg);
    }
  }
}