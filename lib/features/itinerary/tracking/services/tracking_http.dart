import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/services/auth_storage.dart';

/// Dựng một Dio "đứng một mình" cho các isolate nền (geofence callback /
/// AlarmManager) — nơi không có DI của app và `flutter_dotenv` chưa load.
/// Token đọc trực tiếp từ secure storage (platform keystore, dùng được xuyên isolate).
Future<Dio> buildTrackingDio(String baseUrl) async {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));
  try {
    final token = await AuthStorage.read('access_token');
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  } catch (_) {}
  return dio;
}
