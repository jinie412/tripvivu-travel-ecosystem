import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/services/auth_storage.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/create_itinerary_request_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_activity_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_day_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_detail_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/customize_activity_response_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

abstract class ItineraryDataSource {
  Future<List<ItineraryModel>> getItineraries({String? query});
  Future<ItineraryDetailModel> getItineraryDetail(String id);
  Future<void> deleteItinerary(String id);
  Future<void> toggleVisibility(String id, bool isPublic);
  Future<void> updateItineraryTitle(String id, String title);
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  });
  Future<void> deleteActivity(String itineraryId, String activityId);

  /// Gọi POST /itinerary/plan → trả về itineraryId.
  Future<String> createItinerary(CreateItineraryRequestModel request);
  Future<void> updateItineraryActivities(
    String id,
    List<ItineraryDayEntity> days,
  );
  Future<CustomizeActivityResponseModel> addActivityToItinerary(
    String itineraryId,
    int dayNumber,
    String placeId, {
    String? preferredTime,
    bool isLocked = false,
  });
  Future<CustomizeActivityResponseModel> replaceActivityInItinerary(
    String itineraryId,
    String activityId,
    String newPlaceId,
  );
}

class RemoteItineraryDataSource implements ItineraryDataSource {
  String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.read('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<ItineraryModel>> getItineraries({String? query}) async {
    final userId = await AuthUtils.requireCurrentUserId();
    final token = await AuthStorage.read('access_token');
    final trimmedQuery = query?.trim();

    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/my-itineraries').replace(
        queryParameters: {
          'userId': userId,
          if (trimmedQuery != null && trimmedQuery.isNotEmpty)
            'q': trimmedQuery,
        },
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data['itineraries'] as List?) ?? [];
      return list
          .map<ItineraryModel>((e) => ItineraryModel.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load itineraries');
    }
  }

  @override
  Future<void> deleteItinerary(String id) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/itinerary/$id'),
      headers: headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete itinerary: ${res.statusCode}');
    }
  }

  @override
  Future<void> toggleVisibility(String id, bool isPublic) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$id/visibility'),
      headers: headers,
      body: jsonEncode({'isPublic': isPublic}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to toggle visibility: ${res.statusCode}');
    }
  }

  @override
  Future<void> updateItineraryTitle(String id, String title) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$id'),
      headers: headers,
      body: jsonEncode({'description': title}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update itinerary: ${res.statusCode}');
    }
  }

  @override
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (arrivalTime != null) body['arrivalTime'] = arrivalTime;
    if (departureTime != null) body['departureTime'] = departureTime;
    if (actualCost != null) body['actualCost'] = actualCost;
    if (userNotes != null) body['userNotes'] = userNotes;
    if (isLocked != null) body['isLocked'] = isLocked;

    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$itineraryId/activities/$activityId'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception(
        'Failed to update activity: ${res.statusCode}\n${res.body}',
      );
    }
  }

  @override
  Future<void> deleteActivity(String itineraryId, String activityId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/itinerary/$itineraryId/activities/$activityId'),
      headers: headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete activity: ${res.statusCode}');
    }
  }

  @override
  Future<ItineraryDetailModel> getItineraryDetail(String id) async {
    final token = await AuthStorage.read('access_token');
    final touristId = await AuthUtils.getCurrentUserId();

    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/$id').replace(
        queryParameters: {
          if (touristId != null && touristId.isNotEmpty)
            'tourist_id': touristId,
        },
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('DETAIL API STATUS: ${res.statusCode}');
    print('DETAIL API BODY: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      try {
        return ItineraryDetailModel.fromJson(data as Map<String, dynamic>);
      } catch (e, stack) {
        print('DETAIL PARSE ERROR: $e');
        print('DETAIL PARSE STACK: $stack');
        rethrow;
      }
    } else {
      throw Exception(
        'Failed to load itinerary detail: ${res.statusCode}\n${res.body}',
      );
    }
  }

  @override
  Future<void> updateItineraryActivities(
    String id,
    List<ItineraryDayEntity> days,
  ) async {
    final List<Map<String, dynamic>> daysJson = days.map((day) {
      return {
        'dayNumber': day.dayNumber,
        'activities': day.activities
            .map(
              (act) => {
                'id': act.id,
                'placeId': act.placeId ?? act.id,
                'startTime': act.startTime,
                'endTime': act.endTime,
              },
            )
            .toList(),
      };
    }).toList();

    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$id/activities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'days': daysJson}),
    );

    if (res.statusCode != 200) {
      throw Exception('Không thể cập nhật lịch trình');
    }
  }

  @override
  Future<String> createItinerary(CreateItineraryRequestModel request) async {
    final token = await AuthStorage.read('access_token');

    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/plan'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final executionTimeSeconds = data['executionTimeSeconds'];
      final warning = data['warning'];
      if (executionTimeSeconds != null) {
        debugPrint(
          'Itinerary generation completed in ${executionTimeSeconds}s',
        );
      }
      if (warning is String && warning.isNotEmpty) {
        debugPrint('Itinerary generation warning: $warning');
      }
      final id = data['id'] ?? data['itineraryId'] ?? data['itinerary_id'];
      if (id is String && id.isNotEmpty) return id;
      throw Exception('Response tạo lịch trình không có id hợp lệ');
    }
    throw Exception('Tạo lịch trình thất bại: ${res.statusCode}\n${res.body}');
  }

  @override
  Future<CustomizeActivityResponseModel> addActivityToItinerary(
    String itineraryId,
    int dayNumber,
    String placeId, {
    String? preferredTime,
    bool isLocked = false,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'placeId': placeId,
      'dayNumber': dayNumber,
      if (preferredTime != null) 'preferredTime': preferredTime,
      'isLocked': isLocked,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/$itineraryId/activities'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CustomizeActivityResponseModel.fromJson(data);
    }
    throw Exception('Failed to add activity: ${res.statusCode}\n${res.body}');
  }

  @override
  Future<CustomizeActivityResponseModel> replaceActivityInItinerary(
    String itineraryId,
    String activityId,
    String newPlaceId,
  ) async {
    final headers = await _authHeaders();
    final body = {
      'newPlaceId': newPlaceId,
    };

    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$itineraryId/activities/$activityId/replace'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CustomizeActivityResponseModel.fromJson(data);
    }
    throw Exception('Failed to replace activity: ${res.statusCode}\n${res.body}');
  }

  ItineraryDetailModel _parseItineraryDetail(Map<String, dynamic> data) {
    final startDate = _parseDate(data['startDate'] ?? data['start_date']);
    final endDate = _parseDate(data['endDate'] ?? data['end_date']);
    final days = ((data['days'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((day) => _parseItineraryDay(day, startDate))
        .toList();

    return ItineraryDetailModel(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? data['destination'] ?? 'Lịch trình').toString(),
      destination: (data['destination'] ?? '').toString(),
      tripIntent: (data['tripIntent'] ?? data['trip_intent'])?.toString(),
      startDate: startDate,
      endDate: endDate,
      status: (data['status'] ?? 'DRAFT').toString(),
      isPublic: data['isPublic'] == true || data['is_public'] == true,
      isFavorite: data['isFavorite'] == true || data['is_favorite'] == true,
      durationDays: _asInt(
        data['totalDays'] ?? data['durationDays'],
        days.length,
      ),
      activitiesCount: _asInt(
        data['totalPlaces'] ?? data['activitiesCount'],
        days.fold<int>(0, (sum, day) => sum + day.activities.length),
      ),
      hotelsCount: _asInt(data['hotelsCount'], 0),
      transportTurns: _asInt(data['transportTurns'], 0),
      estimatedBudget: _asDouble(
        data['totalBudget'] ?? data['estimatedBudget'],
      ),
      spentBudget: _asDouble(data['spentBudget'] ?? data['spent_budget']),
      placeCost: _asDouble(data['placeCost'] ?? data['place_cost']),
      hotelCost: _asDouble(data['hotelCost'] ?? data['hotel_cost']),
      transportCost: _asDouble(data['transportCost'] ?? data['transport_cost']),
      rideHailingTransportCost: _asDouble(
        data['rideHailingTransportCost'] ?? data['ride_hailing_transport_cost'],
      ),
      days: days,
      notes: ((data['notes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      centerCoordinate: _centerCoordinate(days),
    );
  }

  ItineraryDayModel _parseItineraryDay(
    Map<String, dynamic> data,
    DateTime startDate,
  ) {
    final activities = ((data['activities'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseItineraryActivity)
        .toList();
    final dayNumber = _asInt(data['dayNumber'] ?? data['day_number'], 1);

    return ItineraryDayModel(
      dayNumber: dayNumber,
      // UI uses the itinerary start_date as the source of truth.
      // Keep any legacy day date/dateLabel columns in DB untouched.
      date: startDate.add(Duration(days: dayNumber - 1)),
      temperature: _asInt(data['weatherTemp'] ?? data['temperature'], 0),
      totalDuration: (data['activeTimeStr'] ?? data['total_duration'] ?? '')
          .toString(),
      locationsCount: _asInt(data['locationsCount'], activities.length),
      dayBudget: _asDouble(data['dayBudget'] ?? data['day_budget']),
      activities: activities,
    );
  }

  ItineraryActivityModel _parseItineraryActivity(Map<String, dynamic> data) {
    final priceLabel = (data['priceLabel'] ?? '').toString();
    final price = _asDouble(data['price'] ?? data['estimatedCost']);

    return ItineraryActivityModel(
      id: (data['id'] ?? '').toString(),
      placeId: data['placeId']?.toString() ?? data['place_id']?.toString(),
      title: (data['title'] ?? data['placeName'] ?? data['location_name'] ?? '')
          .toString(),
      startTime: (data['startTime'] ?? data['start_time'] ?? '').toString(),
      endTime: (data['endTime'] ?? data['end_time'] ?? '').toString(),
      locationName: (data['locationName'] ?? data['placeName'] ?? '')
          .toString(),
      address: (data['address'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['image_url'] ?? '').toString(),
      price: price,
      isFree: price <= 0 && priceLabel.toUpperCase().contains('MIỄN PHÍ'),
      category: data['category']?.toString(),
      latitude: _asNullableDouble(data['latitude']),
      longitude: _asNullableDouble(data['longitude']),
      rating: _asNullableDouble(data['rating']),
      status: data['status']?.toString(),
    );
  }

  DateTime _parseDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _asDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  List<double> _centerCoordinate(List<ItineraryDayModel> days) {
    for (final day in days) {
      for (final activity in day.activities) {
        if (activity.latitude != null && activity.longitude != null) {
          return [activity.latitude!, activity.longitude!];
        }
      }
    }
    return const [];
  }
}
