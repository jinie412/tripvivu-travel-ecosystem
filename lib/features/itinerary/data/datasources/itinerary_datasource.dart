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
import 'package:travel_advisor_mobile/features/itinerary/data/models/incurred_cost_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart'
    show CostType;
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/core/error/conflict_exception.dart';
import 'package:travel_advisor_mobile/core/error/budget_confirmation_required_exception.dart';
import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';

typedef ItineraryShareLinkData = ({
  String token,
  String deepLink,
  String shareUrl,
  String message,
  String? playStoreUrl,
});

typedef ItineraryShareRecipientData = ({
  String id,
  String fullName,
  String email,
  String? phoneNumber,
});

abstract class ItineraryDataSource {
  Future<List<ItineraryModel>> getItineraries({String? query});
  Future<ItineraryDetailModel> getItineraryDetail(String id);
  Future<void> deleteItinerary(String id);
  Future<void> toggleVisibility(String id, bool isPublic);
  Future<void> shareItinerary(String id, String recipient);
  Future<List<ItineraryShareRecipientData>> searchShareRecipients(
    String query,
  );
  Future<ItineraryShareLinkData> createShareLink(String id);
  Future<void> updateItineraryTitle(String id, String title);
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
    bool? allowReduceTime,
    bool? extendTime,
  });
  Future<void> deleteActivity(String itineraryId, String activityId);

  /// Gọi POST /itinerary/plan → trả về CreateItineraryResult (có gaItineraryId khi compare).
  Future<CreateItineraryResult> createItinerary(CreateItineraryRequestModel request);
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
    bool? allowReduceTime,
    bool? extendTime,
    bool? addExtraDay,
  });
  Future<CustomizeActivityResponseModel> replaceActivityInItinerary(
    String itineraryId,
    String activityId,
    String newPlaceId, {
    bool? allowReduceTime,
    bool? extendTime,
  });

  Future<({List<ItineraryActivityModel> optimized, List<String> reorderNotes})>
  optimizeDay(String itineraryId, Map<String, dynamic> payload);

  // ── Chi phí phát sinh (mục 1.6-1.7) ──────────────────────────────────
  Future<List<IncurredCostModel>> getIncurredCosts(
    String itineraryId, {
    String? placeId,
    int? dayNumber,
    String? filterUserId,
  });
  Future<List<EligiblePlaceModel>> getEligiblePlaces(String itineraryId);
  Future<CostBreakdownModel> getCostBreakdown(String itineraryId);
  Future<DayCostBreakdownModel> getDayCostBreakdown(
    String itineraryId,
    int dayNumber,
  );
  Future<IncurredCostModel> createIncurredCost(
    String itineraryId, {
    CostType type = CostType.other,
    required String note,
    required double amount,
    String? placeId,
    int? dayNumber,
    List<String>? chargedTo,
  });
  Future<IncurredCostModel> updateIncurredCost(
    String itineraryId,
    String costId, {
    CostType? type,
    String? note,
    double? amount,
    String? placeId,
    int? dayNumber,
    List<String>? chargedTo,
  });
  Future<void> deleteIncurredCost(String itineraryId, String costId);
  Future<IncurredCostModel> updatePlaceEffectivePrice(
    String itineraryId,
    String placeId,
    double amount,
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
  Future<void> shareItinerary(String id, String recipient) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/$id/share'),
      headers: headers,
      body: jsonEncode({'senderUserId': userId, 'recipient': recipient.trim()}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return;
    }

    var message = 'Không thể chia sẻ lịch trình';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['message'];
      message = raw is List ? raw.join('\n') : raw?.toString() ?? message;
    } catch (_) {
      message = '$message: ${res.statusCode}';
    }
    throw Exception(message);
  }

  @override
  Future<List<ItineraryShareRecipientData>> searchShareRecipients(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];

    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/share/recipients').replace(
        queryParameters: {
          'q': trimmed,
          'senderUserId': userId,
        },
      ),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final users = (data['users'] as List?) ?? const [];
      return users.whereType<Map<String, dynamic>>().map((item) {
        return (
          id: (item['id'] ?? '').toString(),
          fullName: (item['fullName'] ?? '').toString(),
          email: (item['email'] ?? '').toString(),
          phoneNumber: item['phoneNumber']?.toString(),
        );
      }).where((item) => item.id.isNotEmpty).toList();
    }

    var message = 'KhÃ´ng thá»ƒ tÃ¬m ngÆ°á»i dÃ¹ng';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['message'];
      message = raw is List ? raw.join('\n') : raw?.toString() ?? message;
    } catch (_) {
      message = '$message: ${res.statusCode}';
    }
    throw Exception(message);
  }

  @override
  Future<ItineraryShareLinkData> createShareLink(String id) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/$id/share-link'),
      headers: headers,
      body: jsonEncode({'senderUserId': userId}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        token: (data['token'] ?? '').toString(),
        deepLink: (data['deepLink'] ?? '').toString(),
        shareUrl: (data['shareUrl'] ?? data['deepLink'] ?? '').toString(),
        message: (data['message'] ?? data['deepLink'] ?? '').toString(),
        playStoreUrl: data['playStoreUrl']?.toString(),
      );
    }

    var message = 'Không thể tạo link chia sẻ';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = data['message'];
      message = raw is List ? raw.join('\n') : raw?.toString() ?? message;
    } catch (_) {
      message = '$message: ${res.statusCode}';
    }
    throw Exception(message);
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
    bool? allowReduceTime,
    bool? extendTime,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (arrivalTime != null) body['arrivalTime'] = arrivalTime;
    if (departureTime != null) body['departureTime'] = departureTime;
    if (actualCost != null) body['actualCost'] = actualCost;
    if (userNotes != null) body['userNotes'] = userNotes;
    if (isLocked != null) body['isLocked'] = isLocked;
    if (allowReduceTime != null) body['allowReduceTime'] = allowReduceTime;
    if (extendTime != null) body['extendTime'] = extendTime;

    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$itineraryId/activities/$activityId'),
      headers: headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 409) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ConflictException.fromJson(data);
    }
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

    if (kDebugMode) {
      debugPrint('DETAIL API STATUS: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      try {
        return ItineraryDetailModel.fromJson(data as Map<String, dynamic>);
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('DETAIL PARSE ERROR: $e');
          debugPrintStack(stackTrace: stack);
        }
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
    final headers = await _authHeaders();
    final List<Map<String, dynamic>> daysJson = days.map((day) {
      return {
        'dayNumber': day.dayNumber,
        'activities': day.activities
            .map(
              (act) => {
                'id': act.id,
                // Chỉ gửi placeId nếu có giá trị hợp lệ (UUID từ DB).
                // Không fallback sang act.id vì act.id có thể là timestamp tạm thời
                // → gây FK constraint violation khi backend INSERT.
                if (act.placeId != null && act.placeId!.isNotEmpty)
                  'placeId': act.placeId,
                'startTime': act.startTime,
                'endTime': act.endTime,
              },
            )
            .toList(),
      };
    }).toList();

    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$id/activities'),
      headers: headers,
      body: jsonEncode({'days': daysJson}),
    );

    if (res.statusCode != 200) {
      String message = 'Không thể cập nhật lịch trình';
      try {
        final errorBody = jsonDecode(res.body);
        final rawMessage = errorBody['message'];
        if (rawMessage is Map && rawMessage['message'] != null) {
          message = rawMessage['message'].toString();
        } else if (rawMessage != null) {
          message = rawMessage.toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  @override
  Future<CreateItineraryResult> createItinerary(
    CreateItineraryRequestModel request,
  ) async {
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
        debugPrint('Itinerary generation completed in ${executionTimeSeconds}s');
      }
      if (warning is String && warning.isNotEmpty) {
        debugPrint('Itinerary generation warning: $warning');
      }
      final id = data['id'] ?? data['itineraryId'] ?? data['itinerary_id'];
      if (id is! String || id.isEmpty) {
        throw Exception('Response tạo lịch trình không có id hợp lệ');
      }
      final gaId = data['gaItineraryId'] as String?;
      return CreateItineraryResult(
        itineraryId: id,
        gaItineraryId: (gaId != null && gaId.isNotEmpty) ? gaId : null,
      );
    }
    if (res.statusCode == 422) {
      try {
        final errBody = jsonDecode(res.body) as Map<String, dynamic>;
        if (errBody['code'] == 'BUDGET_CONFIRMATION_REQUIRED') {
          throw BudgetConfirmationRequiredException.fromJson(errBody);
        }
        if (errBody['code'] == 'REGION_ALLOCATION_REQUIRED') {
          throw RegionAllocationRequiredException.fromJson(errBody);
        }
      } on FormatException {
        // fall through to the generic error below
      }
    }
    String errMsg = 'Tạo lịch trình thất bại: ${res.statusCode}';
    try {
      final errBody = jsonDecode(res.body);
      if (errBody['message'] != null) {
        errMsg = errBody['message'].toString();
      }
    } catch (_) {
      errMsg = '$errMsg\n${res.body}';
    }
    throw Exception(errMsg);
  }

  @override
  Future<CustomizeActivityResponseModel> addActivityToItinerary(
    String itineraryId,
    int dayNumber,
    String placeId, {
    String? preferredTime,
    bool isLocked = false,
    bool? allowReduceTime,
    bool? extendTime,
    bool? addExtraDay,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'placeId': placeId,
      'dayNumber': dayNumber,
      if (preferredTime != null) 'preferredTime': preferredTime,
      'isLocked': isLocked,
      if (allowReduceTime != null) 'allowReduceTime': allowReduceTime,
      if (extendTime != null) 'extendTime': extendTime,
      if (addExtraDay != null) 'addExtraDay': addExtraDay,
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
    if (res.statusCode == 409) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ConflictException.fromJson(data);
    }
    throw Exception('Failed to add activity: ${res.statusCode}\n${res.body}');
  }

  @override
  Future<CustomizeActivityResponseModel> replaceActivityInItinerary(
    String itineraryId,
    String activityId,
    String newPlaceId, {
    bool? allowReduceTime,
    bool? extendTime,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'newPlaceId': newPlaceId,
      if (allowReduceTime != null) 'allowReduceTime': allowReduceTime,
      if (extendTime != null) 'extendTime': extendTime,
    };

    final res = await http.patch(
      Uri.parse(
        '$baseUrl/itinerary/$itineraryId/activities/$activityId/replace',
      ),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return CustomizeActivityResponseModel.fromJson(data);
    }
    if (res.statusCode == 409) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ConflictException.fromJson(data);
    }
    throw Exception(
      'Failed to replace activity: ${res.statusCode}\n${res.body}',
    );
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
      participantCount: _asInt(
        data['participantCount'] ?? data['participant_count'],
        1,
      ),
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

  @override
  Future<({List<ItineraryActivityModel> optimized, List<String> reorderNotes})>
  optimizeDay(String itineraryId, Map<String, dynamic> payload) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/optimize-day'),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final optimized = data['optimized'] as List;
      final reorderNotes =
          (data['reorderNotes'] as List?)?.map((e) => e.toString()).toList() ??
          [];
      return (
        optimized: optimized
            .map((json) => ItineraryActivityModel.fromJson(json))
            .toList(),
        reorderNotes: reorderNotes,
      );
    }
    if (res.statusCode == 409) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ConflictException.fromJson(data);
    }

    try {
      final data = jsonDecode(res.body);
      if (data['message'] == 'SCHEDULE_FULL') {
        throw Exception(
          'Lịch trình đã quá kín, không thể giảm thêm thời gian.',
        );
      }
      if (data['message'] != null) {
        throw Exception(data['message']);
      }
    } on FormatException catch (_) {
      // Bỏ qua lỗi parse JSON để ném lỗi mặc định bên dưới
    }

    throw Exception('Failed to optimize day: ${res.statusCode}');
  }

  // ── Chi phí phát sinh (mục 1.6-1.7) ──────────────────────────────────

  String _extractErrorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      final raw = data is Map ? data['message'] : null;
      if (raw is List) return raw.join('\n');
      if (raw != null) return raw.toString();
    } catch (_) {}
    return '$fallback: ${res.statusCode}';
  }

  @override
  Future<List<IncurredCostModel>> getIncurredCosts(
    String itineraryId, {
    String? placeId,
    int? dayNumber,
    String? filterUserId,
  }) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/$itineraryId/incurred-costs').replace(
        queryParameters: {
          'user_id': userId,
          if (placeId != null) 'place_id': placeId,
          if (dayNumber != null) 'day_number': dayNumber.toString(),
          if (filterUserId != null) 'filter_user_id': filterUserId,
        },
      ),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể tải danh sách chi phí phát sinh'),
      );
    }
    final list = jsonDecode(res.body) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(IncurredCostModel.fromJson)
        .toList();
  }

  @override
  Future<List<EligiblePlaceModel>> getEligiblePlaces(
    String itineraryId,
  ) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.get(
      Uri.parse(
        '$baseUrl/itinerary/$itineraryId/incurred-costs/eligible-places',
      ).replace(queryParameters: {'user_id': userId}),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể tải danh sách địa điểm'),
      );
    }
    final list = jsonDecode(res.body) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(EligiblePlaceModel.fromJson)
        .toList();
  }

  @override
  Future<CostBreakdownModel> getCostBreakdown(String itineraryId) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/$itineraryId/incurred-costs/breakdown'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể tải tổng hợp chi phí'),
      );
    }
    return CostBreakdownModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<DayCostBreakdownModel> getDayCostBreakdown(
    String itineraryId,
    int dayNumber,
  ) async {
    final headers = await _authHeaders();
    final res = await http.get(
      Uri.parse(
        '$baseUrl/itinerary/$itineraryId/incurred-costs/day-breakdown',
      ).replace(queryParameters: {'day_number': dayNumber.toString()}),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể tải chi phí theo ngày'),
      );
    }
    return DayCostBreakdownModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<IncurredCostModel> createIncurredCost(
    String itineraryId, {
    CostType type = CostType.other,
    required String note,
    required double amount,
    String? placeId,
    int? dayNumber,
    List<String>? chargedTo,
  }) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/$itineraryId/incurred-costs'),
      headers: headers,
      body: jsonEncode({
        'userId': userId,
        'type': type.toApi(),
        'note': note,
        'amount': amount,
        if (placeId != null) 'placeId': placeId,
        if (dayNumber != null) 'dayNumber': dayNumber,
        if (chargedTo != null) 'chargedTo': chargedTo,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể ghi nhận chi phí phát sinh'),
      );
    }
    return IncurredCostModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<IncurredCostModel> updateIncurredCost(
    String itineraryId,
    String costId, {
    CostType? type,
    String? note,
    double? amount,
    String? placeId,
    int? dayNumber,
    List<String>? chargedTo,
  }) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$itineraryId/incurred-costs/$costId'),
      headers: headers,
      body: jsonEncode({
        'userId': userId,
        if (type != null) 'type': type.toApi(),
        if (note != null) 'note': note,
        if (amount != null) 'amount': amount,
        if (placeId != null) 'placeId': placeId,
        if (dayNumber != null) 'dayNumber': dayNumber,
        if (chargedTo != null) 'chargedTo': chargedTo,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể cập nhật chi phí phát sinh'),
      );
    }
    return IncurredCostModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteIncurredCost(String itineraryId, String costId) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.delete(
      Uri.parse(
        '$baseUrl/itinerary/$itineraryId/incurred-costs/$costId',
      ).replace(queryParameters: {'user_id': userId}),
      headers: headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        _extractErrorMessage(res, 'Không thể xoá chi phí phát sinh'),
      );
    }
  }

  @override
  Future<IncurredCostModel> updatePlaceEffectivePrice(
    String itineraryId,
    String placeId,
    double amount,
  ) async {
    final headers = await _authHeaders();
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.patch(
      Uri.parse('$baseUrl/itinerary/$itineraryId/incurred-costs/place-price'),
      headers: headers,
      body: jsonEncode({'userId': userId, 'placeId': placeId, 'amount': amount}),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractErrorMessage(res, 'Không thể sửa giá địa điểm'));
    }
    return IncurredCostModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
