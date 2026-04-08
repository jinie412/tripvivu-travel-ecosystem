import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/features/auth/data/models/user_model.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Contract for auth data operations.
// ─────────────────────────────────────────────────────────────────────────────
abstract class AuthDataSource {
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  });

  Future<LoginResult> loginWithGoogle();

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

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote implementation — calls the real NestJS backend.
// ─────────────────────────────────────────────────────────────────────────────
class RemoteAuthDataSource implements AuthDataSource {
  final DioClient _client;
  final FlutterSecureStorage _storage;

  RemoteAuthDataSource(this._client, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final res = await _client.dio.post(
        '/auth/login',
        data: {'emailOrPhone': emailOrPhone, 'password': password},
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
  Future<LoginResult> loginWithGoogle() async {
    try {
      // 1. Mở popup Đăng nhập Google (Native)
      // Lưu ý: Cần truyền serverClientId (Web Client ID) lấy từ Google Cloud Console
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId:
            '210635344590-5pfnhbdh1s392h1jduvq6lkkv20j0rdn.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Người dùng đã hủy đăng nhập');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null || idToken == null) {
        throw 'Không lấy được Token từ Google';
      }

      // 2. Gửi Token cho Supabase để xác thực
      final AuthResponse supabaseResponse = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

      final supabaseToken = supabaseResponse.session?.accessToken;
      if (supabaseToken == null) {
        throw Exception('Lỗi xác thực với Supabase');
      }

      // 3. Gọi Backend NestJS để đồng bộ DB
      // Truyền trực tiếp token ban đầu vào headers
      final syncRes = await _client.dio.post(
        '/auth/sync-oauth',
        data: {'requestedRole': 'TOURIST'},
        options: Options(headers: {'Authorization': 'Bearer $supabaseToken'}),
      );

      // 4. Refresh Session để lấy token mới nhất với đầy đủ Metadata
      // (Backend có thể đã cập nhật user_metadata sau sync-oauth)
      final refreshed = await Supabase.instance.client.auth.refreshSession();
      final freshToken =
          refreshed.session?.accessToken ?? supabaseToken;
      final freshRefreshToken =
          refreshed.session?.refreshToken ??
          supabaseResponse.session?.refreshToken ??
          '';
      final freshUser = refreshed.user ?? supabaseResponse.user;

      // Lưu token mới nhất vào SecureStorage
      await _storage.write(key: 'access_token', value: freshToken);
      await _storage.write(key: 'refresh_token', value: freshRefreshToken);

      // 5. Trả về LoginResult với token và metadata mới nhất
      final user = UserModel.fromJson({
        'id': freshUser?.id,
        'email': freshUser?.email,
        'display_name':
            freshUser?.userMetadata?['full_name'] ?? 'Người dùng Google',
        'role': syncRes.data['role'] ?? 'TOURIST',
      });

      return LoginResult(
        user: user.toEntity(),
        accessToken: freshToken,
        refreshToken: freshRefreshToken,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Lỗi đồng bộ Backend';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: $e');
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
        data: {'email': email, 'returnUrl': 'gptraveladvisor://reset-password'},
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
        data: {'accessToken': accessToken, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Đổi mật khẩu thất bại';
      throw Exception(msg);
    }
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _client.dio.put(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] as String?) ?? 'Đổi mật khẩu thành công';
      }

      return 'Đổi mật khẩu thành công';
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Đổi mật khẩu thất bại'),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      if (message is List && message.isNotEmpty) {
        return message
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .join('\n');
      }
    }

    return fallback;
  }
}
