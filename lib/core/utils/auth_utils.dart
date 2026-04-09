import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared utility for authentication-related operations
class AuthUtils {
  static const _storage = FlutterSecureStorage();

  /// Get the current authenticated user's ID from the JWT token stored in secure storage.
  /// 
  /// Returns the user ID if available, null otherwise.
  /// Decodes the JWT payload to extract the userId or sub claim.
  static Future<String?> getCurrentUserId() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null || accessToken.isEmpty) return null;

      final parts = accessToken.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));

      if (payload is Map<String, dynamic>) {
        final userId = payload['userId'] ?? payload['sub'];
        return userId?.toString();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  /// Get the current authenticated user's ID and throw if not available.
  /// 
  /// Throws an exception if the user ID cannot be obtained.
  static Future<String> requireCurrentUserId() async {
    final userId = await getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw StateError(
        'User not authenticated. Please log in first to perform this action.',
      );
    }
    return userId;
  }
}
