import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_detail_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_day_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_activity_model.dart';
import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hợp đồng cho nguồn dữ liệu lịch trình.
abstract class ItineraryDataSource {
  Future<List<ItineraryModel>> getItineraries();
  Future<ItineraryDetailModel> getItineraryDetail(String id);
  Future<void> deleteItinerary(String id);
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — trả dữ liệu giả giống hệt Figma.
// ─────────────────────────────────────────────────────────────────────────────
class MockItineraryDataSource implements ItineraryDataSource {
  final List<ItineraryModel> _items = [
    // ── Sắp đi (upcoming) ─────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-001',
      description: 'Sài Gòn 3N2Đ',
      destination: 'Sài Gòn',
      startDate: '2024-10-15',
      endDate: '2024-10-17',
      days: 3,
      progress: 80,
      status: 'upcoming',
    ),
    ItineraryModel(
      id: 'itin-002',
      description: 'Đà Nẵng - Hội An 5N',
      destination: 'Đà Nẵng',
      startDate: '2024-11-01',
      endDate: '2024-11-05',
      days: 5,
      progress: 45,
      status: 'upcoming',
    ),
    // ── Đã đi (completed) ─────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-000',
      description: 'Hội An Memories',
      destination: 'Hội An',
      startDate: '2024-09-10',
      endDate: '2024-09-12',
      days: 3,
      progress: 100,
      status: 'completed',
    ),
    ItineraryModel(
      id: 'itin-003',
      description: 'Vịnh Di Sản',
      destination: 'Hạ Long',
      startDate: '2024-08-20',
      endDate: '2024-08-23',
      days: 3,
      progress: 100,
      status: 'completed',
    ),
    ItineraryModel(
      id: 'itin-004',
      description: 'Phú Quốc Island',
      destination: 'Phú Quốc',
      startDate: '2024-07-10',
      endDate: '2024-07-14',
      days: 4,
      progress: 100,
      status: 'completed',
    ),
  ];

  @override
  Future<List<ItineraryModel>> getItineraries() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_items);
  }

  @override
  Future<void> deleteItinerary(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<ItineraryDetailModel> getItineraryDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (id == 'itin-001' || id == 'trip-002') {
      return _mockSaigonDetail(id);
    } else if (id == 'trip-001' || id == 'itin-004') {
      return _mockPhuQuocDetail(id);
    }

    return _mockDefaultDetail(id);
  }

  ItineraryDetailModel _mockSaigonDetail(String id) {
    return ItineraryDetailModel(
      id: id,
      title: 'Khám phá Sài Gòn 3 ngày',
      destination: 'Sài Gòn',
      startDate: DateTime(2024, 10, 15),
      endDate: DateTime(2024, 10, 17),
      status: 'DANG DIEN RA',
      isPublic: true,
      durationDays: 3,
      activitiesCount: 12,
      hotelsCount: 1,
      transportTurns: 4,
      estimatedBudget: 5000000,
      spentBudget: 1200000,
      currency: 'VNĐ',
      notes: [
        'Mang theo hộ chiếu/ CCCD và bảo hiểm du lịch.',
        'Chuẩn bị quần áo phù hợp với thời tiết nắng nóng.',
      ],
      centerCoordinate: [10.7769, 106.7009],
      visitedRestaurants: const [
        VisitedRestaurantModel(
          name: 'Cơm tấm Ba Ghiền',
          dishes: [
            VisitedDishModel(name: 'Cơm tấm sườn bì chả', price: 85000, quantity: 1),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&q=80',
        ),
      ],
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: DateTime(2024, 10, 15),
          temperature: 32,
          totalDuration: '6 tiếng 30 phút',
          locationsCount: 4,
          dayBudget: 1200000,
          activities: [
            _activity('act-001', 'Chợ Hoa Hồ Thị Kỷ', '08:00', '09:30', 'Quận 10', true, lat: 10.7675, lng: 106.6783, status: 'daDi'),
            _activity('act-002', 'Bảo tàng Mỹ thuật', '10:00', '11:30', 'Quận 1', false, price: 30000, lat: 10.7725, lng: 106.6980, status: 'dangDi'),
          ],
        ),
      ],
    );
  }

  ItineraryDetailModel _mockPhuQuocDetail(String id) {
    return ItineraryDetailModel(
      id: id,
      title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm',
      destination: 'Phú Quốc',
      startDate: DateTime(2024, 7, 10),
      endDate: DateTime(2024, 7, 14),
      status: 'HOAN THANH',
      durationDays: 4,
      activitiesCount: 15,
      hotelsCount: 1,
      transportTurns: 6,
      estimatedBudget: 9500000,
      spentBudget: 8200000,
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: DateTime(2024, 7, 10),
          temperature: 29,
          totalDuration: '8 tiếng',
          locationsCount: 3,
          dayBudget: 2500000,
          activities: [
            _activity('pq-001', 'Bãi Sao', '09:00', '12:00', 'Nam đảo', true, lat: 10.0538, lng: 104.0375, status: 'daDi'),
          ],
        ),
      ],
    );
  }

  ItineraryDetailModel _mockDefaultDetail(String id) {
    final now = DateTime.now();
    return ItineraryDetailModel(
      id: id,
      title: 'Hành trình di sản Đà Nẵng - Hội An 4N3Đ',
      destination: 'Đà Nẵng & Hội An',
      startDate: now,
      endDate: now.add(const Duration(days: 3)),
      status: 'DANG DIEN RA',
      durationDays: 4,
      activitiesCount: 8,
      hotelsCount: 1,
      transportTurns: 4,
      estimatedBudget: 8500000,
      spentBudget: 4200000,
      centerCoordinate: [16.0544, 108.2022], // Tâm tại Đà Nẵng
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: now,
          temperature: 28,
          totalDuration: '5 tiếng',
          locationsCount: 2,
          dayBudget: 1500000,
          activities: [
            _activity('act-dn-1', 'Cầu Rồng Đà Nẵng', '08:00', '09:30', 'An Hải Tây, Sơn Trà, Đà Nẵng', true, lat: 16.0610, lng: 108.2269, status: 'daDi'),
            _activity('act-dn-2', 'Biển Mỹ Khê', '15:00', '18:00', 'Phước Mỹ, Sơn Trà, Đà Nẵng', true, lat: 16.0664, lng: 108.2464, status: 'daDi'),
          ],
        ),
        ItineraryDayModel(
          dayNumber: 2,
          date: now.add(const Duration(days: 1)),
          temperature: 24,
          totalDuration: '8 tiếng',
          locationsCount: 1,
          dayBudget: 2500000,
          activities: [
            _activity('act-dn-3', 'Bà Nà Hills', '08:30', '16:30', 'Hòa Ninh, Hòa Vang, Đà Nẵng', false, price: 900000, lat: 15.9995, lng: 107.9944, status: 'dangDi'),
          ],
        ),
        ItineraryDayModel(
          dayNumber: 3,
          date: now.add(const Duration(days: 2)),
          temperature: 27,
          totalDuration: '6 tiếng',
          locationsCount: 2,
          dayBudget: 1200000,
          activities: [
            _activity('act-dn-4', 'Chùa Linh Ứng', '09:00', '11:00', 'Bán đảo Sơn Trà, Đà Nẵng', true, lat: 16.1001, lng: 108.2775, status: 'chuaDi'),
            _activity('act-dn-5', 'Ngũ Hành Sơn', '14:30', '17:00', 'Hòa Hải, Ngũ Hành Sơn, Đà Nẵng', false, price: 40000, lat: 16.0026, lng: 108.2619, status: 'chuaDi'),
          ],
        ),
        ItineraryDayModel(
          dayNumber: 4,
          date: now.add(const Duration(days: 3)),
          temperature: 29,
          totalDuration: '7 tiếng',
          locationsCount: 2,
          dayBudget: 2000000,
          activities: [
            _activity('act-ha-1', 'Chùa Cầu Hội An', '10:00', '11:30', 'Phường Minh An, Hội An', true, lat: 15.8770, lng: 108.3262, status: 'chuaDi'),
            _activity('act-ha-2', 'Chợ Đêm Hội An', '18:30', '21:00', 'Nguyễn Hoàng, Hội An', true, lat: 15.8762, lng: 108.3250, status: 'chuaDi'),
          ],
        ),
      ],
    );
  }

  ItineraryActivityModel _activity(String id, String title, String start, String end, String addr, bool free, {double price = 0, double? lat, double? lng, String? status}) {
    return ItineraryActivityModel(
      id: id,
      title: title,
      startTime: start,
      endTime: end,
      locationName: title,
      address: addr,
      imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80',
      isFree: free,
      price: price,
      transportInfo: '10-20 phút di chuyển',
      latitude: lat,
      longitude: lng,
      status: status,
    );
  }
}

class RemoteItineraryDataSource implements ItineraryDataSource {
  String get baseUrl => ApiConfig.baseUrl;

  @override
  Future<List<ItineraryModel>> getItineraries() async {
    final userId = await AuthUtils.requireCurrentUserId();
    final res = await http.get(
      Uri.parse('$baseUrl/itinerary/my-itineraries').replace(
        queryParameters: {'userId': userId},
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data['itineraries'] as List;
      return list.map<ItineraryModel>((e) => ItineraryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load itineraries');
    }
  }

  @override
  Future<void> deleteItinerary(String id) async {
    await http.delete(
      Uri.parse('$baseUrl/itinerary/$id'),
    );
  }

  @override
  Future<ItineraryDetailModel> getItineraryDetail(String id) {
    throw UnimplementedError();
  }
}
