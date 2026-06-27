import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/services/auth_storage.dart';
import 'package:travel_advisor_mobile/features/auth/data/models/user_model.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';
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

  /// Đọc session từ storage, refresh token nếu cần.
  /// Trả về UserEntity nếu session hợp lệ, null nếu không.
  Future<UserEntity?> restoreSession();

  /// Xóa toàn bộ token + đăng xuất Supabase.
  Future<void> logout();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote implementation — calls the real NestJS backend.
// ─────────────────────────────────────────────────────────────────────────────
class RemoteAuthDataSource implements AuthDataSource {
  final DioClient _client;

  RemoteAuthDataSource(this._client);

  // ── Storage keys ────────────────────────────────────────────────────────────
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kCachedUser = 'cached_user';

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
      final data = res.data as Map<String, dynamic>;

      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userModel = UserModel.fromJson(
        data['user'] as Map<String, dynamic>,
      );

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userModel: userModel,
      );

      return LoginResult(
        user: userModel.toEntity(),
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, fallback: 'Đăng nhập thất bại'));
    }
  }

  @override
  Future<LoginResult> loginWithGoogle() async {
    try {
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

      final syncRes = await _client.dio.post(
        '/auth/sync-oauth',
        data: {'requestedRole': 'TOURIST'},
        options: Options(headers: {'Authorization': 'Bearer $supabaseToken'}),
      );

      // Refresh để lấy token mới nhất sau khi backend đã cập nhật metadata
      final refreshed = await Supabase.instance.client.auth.refreshSession();
      final freshToken = refreshed.session?.accessToken ?? supabaseToken;
      final freshRefreshToken =
          refreshed.session?.refreshToken ??
          supabaseResponse.session?.refreshToken ??
          '';
      final freshUser = refreshed.user ?? supabaseResponse.user;

      final userModel = UserModel.fromJson({
        'id': freshUser?.id,
        'email': freshUser?.email,
        'fullName':
            freshUser?.userMetadata?['full_name'] ?? 'Người dùng Google',
        'role': syncRes.data['role'] ?? 'TOURIST',
      });

      await _saveSession(
        accessToken: freshToken,
        refreshToken: freshRefreshToken,
        userModel: userModel,
      );

      return LoginResult(
        user: userModel.toEntity(),
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

  @override
  Future<UserEntity?> restoreSession() async {
    final accessToken = await AuthStorage.read(_kAccessToken);
    final refreshToken = await AuthStorage.read(_kRefreshToken);
    final cachedUserJson = await AuthStorage.read(_kCachedUser);

    // Không có token hoặc user cache → chưa đăng nhập
    if (accessToken == null || refreshToken == null || cachedUserJson == null) {
      return null;
    }

    // Access token hết hạn (hoặc sắp hết trong vòng 60s) → refresh trước
    if (_isTokenExpiredOrNearExpiry(accessToken)) {
      try {
        final refreshRes = await _client.dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
          // Đánh dấu để interceptor không tự refresh lại khi endpoint này trả 401
          options: Options(extra: {'_retried': true}),
        );

        final newAccess = refreshRes.data['accessToken'] as String?;
        final newRefresh = refreshRes.data['refreshToken'] as String?;

        if (newAccess == null || newAccess.isEmpty) return null;

        await Future.wait([
          AuthStorage.write(_kAccessToken, newAccess),
          if (newRefresh != null && newRefresh.isNotEmpty)
            AuthStorage.write(_kRefreshToken, newRefresh),
        ]);
      } catch (_) {
        await _clearStorage();
        return null;
      }
    }

    // Parse user từ cache
    try {
      final userMap = jsonDecode(cachedUserJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    await _clearStorage();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required UserModel userModel,
  }) async {
    await Future.wait([
      AuthStorage.write(_kAccessToken, accessToken),
      AuthStorage.write(_kRefreshToken, refreshToken),
      AuthStorage.write(_kCachedUser, jsonEncode(userModel.toJson())),
    ]);
  }

  Future<void> _clearStorage() async {
    await Future.wait([
      AuthStorage.delete(_kAccessToken),
      AuthStorage.delete(_kRefreshToken),
      AuthStorage.delete(_kCachedUser),
    ]);
  }

  /// Decode JWT payload (base64url) không cần thư viện ngoài.
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      return jsonDecode(utf8.decode(base64Url.decode(payload)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Trả về true nếu token đã hết hạn hoặc sẽ hết trong [bufferSeconds] giây.
  bool _isTokenExpiredOrNearExpiry(String token, {int bufferSeconds = 60}) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return true;
    final expSeconds = (exp is int) ? exp : (exp as num).toInt();
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= expSeconds - bufferSeconds;
  }

  String _normalizeLoginErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('invalid login credential') ||
        lowerMessage.contains('invalid login credentials') ||
        message.contains('Đăng nhập thất bại')) {
      return 'Tài khoản hoặc mật khẩu không đúng.';
    }

    return message;
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return _normalizeLoginErrorMessage(message);
      }
      if (message is List && message.isNotEmpty) {
        return message
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .join('\n');
      }
    }

      if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Không thể kết nối đến máy chủ ${e.requestOptions.baseUrl}. '
          'Vui lòng kiểm tra backend và thử lại.';
    }

      return fallback;
  }
}
