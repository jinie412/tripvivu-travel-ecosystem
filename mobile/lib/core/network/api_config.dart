import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    final webUrl = dotenv.env['BASE_URL_WEB']?.trim();
    final mobileUrl = dotenv.env['BASE_URL_MOBILE']?.trim();
    final fallbackUrl = dotenv.env['BASE_URL']?.trim();

    final selectedUrl = kIsWeb
        ? (webUrl?.isNotEmpty == true ? webUrl : fallbackUrl)
        : (mobileUrl?.isNotEmpty == true ? mobileUrl : fallbackUrl);

    if (selectedUrl == null || selectedUrl.isEmpty) {
      throw Exception(
        'Base URL is not set. Configure BASE_URL_WEB/BASE_URL_MOBILE (or BASE_URL) in .env file.',
      );
    }

    return selectedUrl;
  }
}