import 'dart:convert';
import 'package:http/http.dart' as http;

class CityApi {
  final String baseUrl = "http://192.168.1.62:3000";

  Future<List<dynamic>> getPlaces({
    required String city,
    required String category,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/search/filter",
    ).replace(queryParameters: {"city": city, "category": category});

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load places");
    }
  }
}
