import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://192.168.1.62:3000';

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');

    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        // nếu có auth thì thêm
        // 'Authorization': 'Bearer TOKEN',
      },
    );
  }
}