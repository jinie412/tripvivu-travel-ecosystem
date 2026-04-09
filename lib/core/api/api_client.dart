import 'package:http/http.dart' as http;
import 'package:travel_advisor_mobile/core/network/api_config.dart';

class ApiClient {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        // nếu có auth thì thêm
        'Authorization': 'Bearer TOKEN',
      },
    );
  }
}