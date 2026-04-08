import 'dart:convert';
import '../../../core/api/api_client.dart';
import 'models/itinerary_response.dart';

class ItineraryService {
  static Future<ItineraryResponse> getMyItineraries(String userId) async {
    final res = await ApiClient.get(
      '/itinerary/my-itineraries?userId=$userId',
    );

    print('STATUS: ${res.statusCode}');
    print('BODY: ${res.body}');

    if (res.statusCode == 200) {
      return ItineraryResponse.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to load itineraries');
    }
  }
}