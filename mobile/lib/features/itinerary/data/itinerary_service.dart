import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/auth_utils.dart';
import 'models/itinerary_response.dart';

class ItineraryService {
  static Future<ItineraryResponse> getMyItineraries() async {
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await ApiClient.get(
      '/itinerary/my-itineraries?userId=$userId',
    );

    if (kDebugMode) {
      debugPrint('Itinerary list status: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      return ItineraryResponse.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Failed to load itineraries');
    }
  }
}
