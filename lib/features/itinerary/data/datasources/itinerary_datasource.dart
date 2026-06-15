import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/create_itinerary_request_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_activity_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_day_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_detail_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_model.dart';
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
}

// // ─────────────────────────────────────────────────────────────────────────────
// /// Mock — trả dữ liệu giả giống hệt Figma.
// // ─────────────────────────────────────────────────────────────────────────────
// class MockItineraryDataSource implements ItineraryDataSource {
//   /// Danh sách lưu trữ nội bộ để hỗ trợ thao tác xóa trên mock.
//   // final List<ItineraryModel> _items = [];
//   final List<ItineraryModel> _items = [
//     // ── Sắp đi (upcoming) ─────────────────────────────────────────────────
//     ItineraryModel(
//       id: 'itin-001',
//       title: 'Sài Gòn 3N2Đ',
//       imageUrl:
//           'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
//       startDate: DateTime(2024, 10, 15),
//       endDate: DateTime(2024, 10, 17),
//       estimatedCost: 5200000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 0.8,
//       status: 'upcoming',
//       placeholderColor: 0xFF42A5F5,
//     ),
//     ItineraryModel(
//       id: 'itin-002',
//       title: 'Đà Nẵng - Hội An 5N',
//       imageUrl:
//           'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=600&q=80',
//       startDate: DateTime(2024, 11, 1),
//       endDate: DateTime(2024, 11, 5),
//       estimatedCost: 8500000,
//       currency: 'VNĐ',
//       durationDays: 5,
//       progress: 0.45,
//       status: 'upcoming',
//       placeholderColor: 0xFF26A69A,
//     ),
//     // ── Đã đi (completed) ─────────────────────────────────────────────────
//     ItineraryModel(
//       id: 'itin-000',
//       title: 'Hội An Memories',
//       imageUrl:
//           'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=600&q=80',
//       startDate: DateTime(2024, 9, 10),
//       endDate: DateTime(2024, 9, 12),
//       estimatedCost: 3500000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       placeholderColor: 0xFFFFB300,
//     ),
//     ItineraryModel(
//       id: 'itin-003',
//       title: 'Vịnh Di Sản',
//       imageUrl:
//           'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
//       startDate: DateTime(2024, 8, 20),
//       endDate: DateTime(2024, 8, 23),
//       estimatedCost: 6800000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.8,
//       placeholderColor: 0xFF66BB6A,
//     ),
//     ItineraryModel(
//       id: 'itin-004',
//       title: 'Phú Quốc Island',
//       imageUrl:
//           'https://images.unsplash.com/photo-1550608682-1a415d862f1c?w=600&q=80',
//       startDate: DateTime(2024, 7, 10),
//       endDate: DateTime(2024, 7, 14),
//       estimatedCost: 9200000,
//       currency: 'VNĐ',
//       durationDays: 4,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.5,
//       placeholderColor: 0xFF29B6F6,
//     ),
//     ItineraryModel(
//       id: 'itin-005',
//       title: 'Sapa Trekking',
//       imageUrl:
//           'https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?w=600&q=80',
//       startDate: DateTime(2024, 6, 5),
//       endDate: DateTime(2024, 6, 8),
//       estimatedCost: 4500000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.9,
//       placeholderColor: 0xFF4CAF50,
//     ),
//     ItineraryModel(
//       id: 'itin-006',
//       title: 'Đà Lạt Mộng Mơ',
//       imageUrl:
//           'https://images.unsplash.com/photo-1596401037688-69cb907abf12?w=600&q=80',
//       startDate: DateTime(2024, 5, 1),
//       endDate: DateTime(2024, 5, 3),
//       estimatedCost: 3800000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.6,
//       placeholderColor: 0xFF7E57C2,
//     ),
//     ItineraryModel(
//       id: 'itin-007',
//       title: 'Nha Trang Beach',
//       imageUrl:
//           'https://images.unsplash.com/photo-1583483425010-c566a31bc9f8?w=600&q=80',
//       startDate: DateTime(2024, 4, 15),
//       endDate: DateTime(2024, 4, 18),
//       estimatedCost: 5000000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.3,
//       placeholderColor: 0xFF26C6DA,
//     ),
//     ItineraryModel(
//       id: 'itin-008',
//       title: 'Huế Cố Đô',
//       imageUrl:
//           'https://images.unsplash.com/photo-1559592413-73138379c13b?w=600&q=80',
//       startDate: DateTime(2024, 3, 10),
//       endDate: DateTime(2024, 3, 13),
//       estimatedCost: 4200000,
//       currency: 'VNĐ',
//       durationDays: 3,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.7,
//       placeholderColor: 0xFFFF7043,
//     ),
//     ItineraryModel(
//       id: 'itin-009',
//       title: 'Quy Nhơn Biển Xanh',
//       imageUrl:
//           'https://images.unsplash.com/photo-1622306911579-2afb847fe8f8?w=600&q=80',
//       startDate: DateTime(2024, 2, 20),
//       endDate: DateTime(2024, 2, 22),
//       estimatedCost: 3500000,
//       currency: 'VNĐ',
//       durationDays: 2,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.4,
//       placeholderColor: 0xFF5C6BC0,
//     ),
//     ItineraryModel(
//       id: 'itin-010',
//       title: 'Cần Thơ miền Tây',
//       imageUrl:
//           'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
//       startDate: DateTime(2024, 1, 5),
//       endDate: DateTime(2024, 1, 7),
//       estimatedCost: 2800000,
//       currency: 'VNĐ',
//       durationDays: 2,
//       progress: 1.0,
//       status: 'completed',
//       rating: 4.2,
//       placeholderColor: 0xFFEC407A,
//     ),
//     // ── Nháp (draft) ──────────────────────────────────────────────────────
//     ItineraryModel(
//       id: 'itin-011',
//       title: 'Hà Giang Loop',
//       imageUrl: null,
//       estimatedCost: 0,
//       durationDays: 4,
//       progress: 0.2,
//       status: 'draft',
//       placeholderColor: 0xFFBDBDBD,
//     ),
//     ItineraryModel(
//       id: 'itin-012',
//       title: 'Côn Đảo Heritage',
//       imageUrl: null,
//       estimatedCost: 0,
//       durationDays: 3,
//       progress: 0.1,
//       status: 'draft',
//       placeholderColor: 0xFFBDBDBD,
//     ),
//   ];

//   @override
//   Future<List<ItineraryModel>> getItineraries() async {
//     // Giả lập độ trễ mạng.
//     await Future.delayed(const Duration(milliseconds: 500));
//     return List.unmodifiable(_items);
//   }

//   @override
//   Future<void> deleteItinerary(String id) async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     _items.removeWhere((item) => item.id == id);
//   }

//   @override
//   Future<ItineraryDetailModel> getItineraryDetail(String id) async {
//     await Future.delayed(const Duration(milliseconds: 800));

//     // Trả về dữ liệu mock cho các trip từ màn hình Explore hoặc màn hình Lịch trình
//     if (id == 'itin-001' || id == 'trip-002') {
//       return _mockSaigonDetail(id);
//     } else if (id == 'trip-001' || id == 'itin-004') {
//       return _mockPhuQuocDetail(id);
//     } else if (id == 'trip-004' || id == 'itin-006') {
//       return _mockDalatDetail(id);
//     }

//     // Default mock data for others
//     return _mockDefaultDetail(id);
//   }

//   ItineraryDetailModel _mockSaigonDetail(String id) {
//     return ItineraryDetailModel(
//       id: id,
//       title: 'Khám phá Sài Gòn 3 ngày',
//       destination: 'Sài Gòn',
//       startDate: DateTime(2024, 10, 15),
//       endDate: DateTime(2024, 10, 17),
//       status: 'DANG DIEN RA',
//       isPublic: true,
//       durationDays: 3,
//       activitiesCount: 12,
//       hotelsCount: 1,
//       transportTurns: 4,
//       estimatedBudget: 5000000,
//       spentBudget: 1200000,
//       currency: 'VNĐ',
//       notes: [
//         'Mang theo hộ chiếu/ CCCD và bảo hiểm du lịch.',
//         'Chuẩn bị quần áo phù hợp với thời tiết nắng nóng.',
//         'Cẩn thận với tài sản cá nhân ở nơi đông người.',
//         'Nên thử cà phê bệt ở Nhà thờ Đức Bà.',
//       ],
//       centerCoordinate: [10.7769, 106.7009],
//       visitedRestaurants: const [
//         VisitedRestaurantModel(
//           name: 'Cơm tấm Ba Ghiền',
//           dishes: [
//             VisitedDishModel(name: 'Cơm tấm sườn bì chả', price: 85000, quantity: 1),
//             VisitedDishModel(name: 'Trà đá', price: 5000, quantity: 2),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&q=80',
//         ),
//         VisitedRestaurantModel(
//           name: 'Phở Hòa Pasteur',
//           dishes: [
//             VisitedDishModel(name: 'Phở bò tái nạm', price: 95000, quantity: 1),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=200&q=80',
//         ),
//       ],
//       days: [
//         ItineraryDayModel(
//           dayNumber: 1,
//           date: DateTime(2024, 10, 15),
//           temperature: 32,
//           totalDuration: '6 tiếng 30 phút',
//           locationsCount: 4,
//           dayBudget: 1200000,
//           activities: [
//             _activity('act-001', 'Chợ Hoa Hồ Thị Kỷ', '08:00', '09:30', 'Quận 10', true, lat: 10.7675, lng: 106.6783, status: 'daDi'),
//             _activity('act-002', 'Bảo tàng Mỹ thuật', '10:00', '11:30', 'Quận 1', false, price: 30000, lat: 10.7725, lng: 106.6980, status: 'dangDi'),
//             _activity('act-003', 'Cơm tấm Ba Ghiền', '11:30', '12:30', 'Phú Nhuận', false, price: 85000, lat: 10.7937, lng: 106.6750, status: 'chuaDi'),
//           ],
//         ),
//       ],
//     );
//   }

//   ItineraryDetailModel _mockPhuQuocDetail(String id) {
//     return ItineraryDetailModel(
//       id: id,
//       title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm',
//       destination: 'Phú Quốc',
//       startDate: DateTime(2024, 7, 10),
//       endDate: DateTime(2024, 7, 14),
//       status: 'HOAN THANH',
//       durationDays: 4,
//       activitiesCount: 15,
//       hotelsCount: 1,
//       transportTurns: 6,
//       estimatedBudget: 9500000,
//       spentBudget: 8200000,
//       visitedRestaurants: const [
//         VisitedRestaurantModel(
//           name: 'Bún quậy Kiến Xây',
//           dishes: [
//             VisitedDishModel(name: 'Bún quậy đặc biệt', price: 75000, quantity: 2),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200&q=80',
//         ),
//         VisitedRestaurantModel(
//           name: 'Nhà hàng Xin Chào',
//           dishes: [
//             VisitedDishModel(name: 'Gỏi cá trích', price: 180000, quantity: 1),
//             VisitedDishModel(name: 'Nước dừa', price: 35000, quantity: 2),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=200&q=80',
//         ),
//       ],
//       notes: ['Nên đặt trước vé VinWonders', 'Mang theo kem chống nắng'],
//       days: [
//         ItineraryDayModel(
//           dayNumber: 1,
//           date: DateTime(2024, 7, 10),
//           temperature: 29,
//           totalDuration: '8 tiếng',
//           locationsCount: 3,
//           dayBudget: 2500000,
//           activities: [
//             _activity('pq-001', 'Bãi Sao', '09:00', '12:00', 'Nam đảo', true, lat: 10.0538, lng: 104.0375, status: 'daDi'),
//             _activity('pq-002', 'Sunset Sanato', '16:30', '18:30', 'Dương Tơ', false, price: 100000, lat: 10.1837, lng: 103.9680, status: 'daDi'),
//           ],
//         ),
//       ],
//     );
//   }

//   ItineraryDetailModel _mockDalatDetail(String id) {
//     return ItineraryDetailModel(
//       id: id,
//       title: 'Khám phá Đà Lạt mộng mơ',
//       destination: 'Đà Lạt',
//       startDate: DateTime(2024, 5, 1),
//       endDate: DateTime(2024, 5, 3),
//       status: 'HOAN THANH',
//       durationDays: 3,
//       activitiesCount: 10,
//       hotelsCount: 1,
//       transportTurns: 3,
//       estimatedBudget: 4200000,
//       spentBudget: 3800000,
//       visitedRestaurants: const [
//         VisitedRestaurantModel(
//           name: 'Lẩu gà lá é Tao Ngộ',
//           dishes: [
//             VisitedDishModel(name: 'Lẩu gà lá é (Lớn)', price: 350000, quantity: 1),
//             VisitedDishModel(name: 'Bún thêm', price: 10000, quantity: 2),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1547928576-a4a332306003?w=200&q=80',
//         ),
//         VisitedRestaurantModel(
//           name: 'Bánh mì Liên Hoa',
//           dishes: [
//             VisitedDishModel(name: 'Bánh mì xíu mại', price: 25000, quantity: 3),
//           ],
//           imageUrl: 'https://images.unsplash.com/photo-1619096249114-162137930819?w=200&q=80',
//         ),
//       ],
//       notes: ['Đà Lạt khá lạnh về đêm'],
//       days: [
//         ItineraryDayModel(
//           dayNumber: 1,
//           date: DateTime(2024, 5, 1),
//           temperature: 18,
//           totalDuration: '5 tiếng',
//           locationsCount: 2,
//           dayBudget: 800000,
//           activities: [
//             _activity('dl-001', 'Hồ Tuyền Lâm', '08:00', '10:00', 'Lâm Đồng', true, lat: 11.8942, lng: 108.4358, status: 'daDi'),
//             _activity('dl-002', 'Làng Cù Lần', '14:00', '17:00', 'Lạc Dương', false, price: 60000, lat: 12.0125, lng: 108.3450, status: 'daDi'),
//           ],
//         ),
//       ],
//     );
//   }

//   ItineraryDetailModel _mockDefaultDetail(String id) {
//     return ItineraryDetailModel(
//       id: id,
//       title: 'Kế hoạch du lịch chi tiết',
//       destination: 'Địa điểm du lịch',
//       startDate: DateTime.now(),
//       endDate: DateTime.now().add(const Duration(days: 3)),
//       status: 'DRAF',
//       durationDays: 4,
//       activitiesCount: 5,
//       hotelsCount: 1,
//       transportTurns: 2,
//       estimatedBudget: 3000000,
//       spentBudget: 0,
//       notes: ['Cần cập nhật thêm chi tiết'],
//       days: [
//         ItineraryDayModel(
//           dayNumber: 1,
//           date: DateTime.now(),
//           locationsCount: 1,
//           dayBudget: 500000,
//           totalDuration: '2 tiếng',
//           activities: [_activity('d-001', 'Địa điểm tham quan', '09:00', '10:00', 'Khu vực trung tâm', true, lat: 21.0285, lng: 105.8542, status: 'chuaDi')],
//         ),
//       ],
//     );
//   }

//   ItineraryActivityModel _activity(String id, String title, String start, String end, String addr, bool free, {double price = 0, double? lat, double? lng, String? status}) {
//     return ItineraryActivityModel(
//       id: id,
//       title: title,
//       startTime: start,
//       endTime: end,
//       locationName: title,
//       address: addr,
//       imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80',
//       isFree: free,
//       price: price,
//       transportInfo: '10-20 phút di chuyển',
//       latitude: lat,
//       longitude: lng,
//       status: status,
//     );
//   }
// }

class RemoteItineraryDataSource implements ItineraryDataSource {
  String get baseUrl => ApiConfig.baseUrl;

  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<ItineraryModel>> getItineraries({String? query}) async {
    final userId = await AuthUtils.requireCurrentUserId();
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/$id'),
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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');

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
      startDate: startDate,
      endDate: endDate,
      status: (data['status'] ?? 'DRAFT').toString(),
      isPublic: data['isPublic'] == true || data['is_public'] == true,
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
      spentBudget: _asDouble(data['spentBudget']),
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
