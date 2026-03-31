import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_activity_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_day_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_detail_model.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/models/itinerary_model.dart';

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
  /// Danh sách lưu trữ nội bộ để hỗ trợ thao tác xóa trên mock.
  // final List<ItineraryModel> _items = [];
  final List<ItineraryModel> _items = [
    // ── Sắp đi (upcoming) ─────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-001',
      title: 'Sài Gòn 3N2Đ',
      imageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 2)),
      estimatedCost: 5200000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 0.8,
      status: 'upcoming',
      placeholderColor: 0xFF42A5F5,
    ),
    ItineraryModel(
      id: 'itin-002',
      title: 'Đà Nẵng - Hội An 5N',
      imageUrl:
          'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=600&q=80',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 4)),
      estimatedCost: 8500000,
      currency: 'VNĐ',
      durationDays: 5,
      progress: 0.45,
      status: 'upcoming',
      placeholderColor: 0xFF26A69A,
    ),
    // ── Đã đi (completed) ─────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-000',
      title: 'Hội An Memories',
      imageUrl:
          'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?w=600&q=80',
      startDate: DateTime(2024, 9, 10),
      endDate: DateTime(2024, 9, 12),
      estimatedCost: 3500000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      placeholderColor: 0xFFFFB300,
    ),
    ItineraryModel(
      id: 'itin-003',
      title: 'Vịnh Di Sản',
      imageUrl:
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80',
      startDate: DateTime(2024, 8, 20),
      endDate: DateTime(2024, 8, 23),
      estimatedCost: 6800000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      rating: 4.8,
      placeholderColor: 0xFF66BB6A,
    ),
    ItineraryModel(
      id: 'itin-004',
      title: 'Phú Quốc Island',
      imageUrl:
          'https://images.unsplash.com/photo-1550608682-1a415d862f1c?w=600&q=80',
      startDate: DateTime(2024, 7, 10),
      endDate: DateTime(2024, 7, 14),
      estimatedCost: 9200000,
      currency: 'VNĐ',
      durationDays: 4,
      progress: 1.0,
      status: 'completed',
      rating: 4.5,
      placeholderColor: 0xFF29B6F6,
    ),
    ItineraryModel(
      id: 'itin-005',
      title: 'Sapa Trekking',
      imageUrl:
          'https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?w=600&q=80',
      startDate: DateTime(2024, 6, 5),
      endDate: DateTime(2024, 6, 8),
      estimatedCost: 4500000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      rating: 4.9,
      placeholderColor: 0xFF4CAF50,
    ),
    ItineraryModel(
      id: 'itin-006',
      title: 'Đà Lạt Mộng Mơ',
      imageUrl:
          'https://images.unsplash.com/photo-1596401037688-69cb907abf12?w=600&q=80',
      startDate: DateTime(2024, 5, 1),
      endDate: DateTime(2024, 5, 3),
      estimatedCost: 3800000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      rating: 4.6,
      placeholderColor: 0xFF7E57C2,
    ),
    ItineraryModel(
      id: 'itin-007',
      title: 'Nha Trang Beach',
      imageUrl:
          'https://images.unsplash.com/photo-1583483425010-c566a31bc9f8?w=600&q=80',
      startDate: DateTime(2024, 4, 15),
      endDate: DateTime(2024, 4, 18),
      estimatedCost: 5000000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      rating: 4.3,
      placeholderColor: 0xFF26C6DA,
    ),
    ItineraryModel(
      id: 'itin-008',
      title: 'Huế Cố Đô',
      imageUrl:
          'https://images.unsplash.com/photo-1559592413-73138379c13b?w=600&q=80',
      startDate: DateTime(2024, 3, 10),
      endDate: DateTime(2024, 3, 13),
      estimatedCost: 4200000,
      currency: 'VNĐ',
      durationDays: 3,
      progress: 1.0,
      status: 'completed',
      rating: 4.7,
      placeholderColor: 0xFFFF7043,
    ),
    ItineraryModel(
      id: 'itin-009',
      title: 'Quy Nhơn Biển Xanh',
      imageUrl:
          'https://images.unsplash.com/photo-1622306911579-2afb847fe8f8?w=600&q=80',
      startDate: DateTime(2024, 2, 20),
      endDate: DateTime(2024, 2, 22),
      estimatedCost: 3500000,
      currency: 'VNĐ',
      durationDays: 2,
      progress: 1.0,
      status: 'completed',
      rating: 4.4,
      placeholderColor: 0xFF5C6BC0,
    ),
    ItineraryModel(
      id: 'itin-010',
      title: 'Cần Thơ miền Tây',
      imageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
      startDate: DateTime(2024, 1, 5),
      endDate: DateTime(2024, 1, 7),
      estimatedCost: 2800000,
      currency: 'VNĐ',
      durationDays: 2,
      progress: 1.0,
      status: 'completed',
      rating: 4.2,
      placeholderColor: 0xFFEC407A,
    ),
    // ── Nháp (draft) ──────────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-011',
      title: 'Hà Giang Loop',
      imageUrl: null,
      estimatedCost: 0,
      durationDays: 4,
      progress: 0.2,
      status: 'draft',
      placeholderColor: 0xFFBDBDBD,
    ),
    ItineraryModel(
      id: 'itin-012',
      title: 'Côn Đảo Heritage',
      imageUrl: null,
      estimatedCost: 0,
      durationDays: 3,
      progress: 0.1,
      status: 'draft',
      placeholderColor: 0xFFBDBDBD,
    ),
  ];

  @override
  Future<List<ItineraryModel>> getItineraries() async {
    // Giả lập độ trễ mạng.
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
    
    // Trả về dữ liệu mock cho các trip từ màn hình Explore hoặc màn hình Lịch trình
    if (id == 'itin-001' || id == 'trip-002') {
      return _mockSaigonDetail(id);
    } else if (id == 'trip-001' || id == 'itin-004') {
      return _mockPhuQuocDetail(id);
    } else if (id == 'trip-004' || id == 'itin-006') {
      return _mockDalatDetail(id);
    }

    // Default mock data for others
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
        'Cẩn thận với tài sản cá nhân ở nơi đông người.',
        'Nên thử cà phê bệt ở Nhà thờ Đức Bà.',
      ],
      centerCoordinate: [10.7769, 106.7009],
      visitedRestaurants: const [
        VisitedRestaurantModel(
          name: 'Cơm tấm Ba Ghiền',
          dishes: [
            VisitedDishModel(name: 'Cơm tấm sườn bì chả', price: 85000, quantity: 1),
            VisitedDishModel(name: 'Trà đá', price: 5000, quantity: 2),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200&q=80',
        ),
        VisitedRestaurantModel(
          name: 'Phở Hòa Pasteur',
          dishes: [
            VisitedDishModel(name: 'Phở bò tái nạm', price: 95000, quantity: 1),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=200&q=80',
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
            _activity('act-001', 'Chợ Hoa Hồ Thị Kỷ', '08:00', '09:30', 'Hẻm 52 Hồ Thị Kỷ, P. 1, Q. 10, TP.HCM', true, lat: 10.7675, lng: 106.6783, status: 'daDi', rating: 4.5, reviewCount: 3679),
            _activity('act-002', 'Bảo tàng Mỹ thuật', '10:00', '11:30', '97A Phó Đức Chính, P. Nguyễn Thái Bình, Q. 1, TP.HCM', false, price: 30000, lat: 10.7725, lng: 106.6980, status: 'dangDi', rating: 4.2, reviewCount: 850),
            _activity('act-003', 'Cơm tấm Ba Ghiền', '11:30', '12:30', '84 Đặng Văn Ngữ, P. 10, Q. Phú Nhuận, TP.HCM', false, price: 85000, lat: 10.7937, lng: 106.6750, status: 'chuaDi', rating: 4.7, reviewCount: 12500),
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
      visitedRestaurants: const [
        VisitedRestaurantModel(
          name: 'Bún quậy Kiến Xây',
          dishes: [
            VisitedDishModel(name: 'Bún quậy đặc biệt', price: 75000, quantity: 2),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=200&q=80',
        ),
        VisitedRestaurantModel(
          name: 'Nhà hàng Xin Chào',
          dishes: [
            VisitedDishModel(name: 'Gỏi cá trích', price: 180000, quantity: 1),
            VisitedDishModel(name: 'Nước dừa', price: 35000, quantity: 2),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=200&q=80',
        ),
      ],
      notes: ['Nên đặt trước vé VinWonders', 'Mang theo kem chống nắng'],
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: DateTime(2024, 7, 10),
          temperature: 29,
          totalDuration: '8 tiếng',
          locationsCount: 3,
          dayBudget: 2500000,
          activities: [
            _activity('pq-001', 'Bãi Sao', '09:00', '12:00', 'Bãi Sao, An Thới, TP. Phú Quốc, Kiên Giang', true, lat: 10.0538, lng: 104.0375, status: 'daDi', rating: 4.8, reviewCount: 5200),
            _activity('pq-002', 'Sunset Sanato', '16:30', '18:30', 'Bắc Bãi Trường, Dương Tơ, TP. Phú Quốc, Kiên Giang', false, price: 100000, lat: 10.1837, lng: 103.9680, status: 'daDi', rating: 4.3, reviewCount: 1200),
          ],
        ),
      ],
    );
  }

  ItineraryDetailModel _mockDalatDetail(String id) {
    return ItineraryDetailModel(
      id: id,
      title: 'Khám phá Đà Lạt mộng mơ',
      destination: 'Đà Lạt',
      startDate: DateTime(2024, 5, 1),
      endDate: DateTime(2024, 5, 3),
      status: 'HOAN THANH',
      durationDays: 3,
      activitiesCount: 10,
      hotelsCount: 1,
      transportTurns: 3,
      estimatedBudget: 4200000,
      spentBudget: 3800000,
      visitedRestaurants: const [
        VisitedRestaurantModel(
          name: 'Lẩu gà lá é Tao Ngộ',
          dishes: [
            VisitedDishModel(name: 'Lẩu gà lá é (Lớn)', price: 350000, quantity: 1),
            VisitedDishModel(name: 'Bún thêm', price: 10000, quantity: 2),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1547928576-a4a332306003?w=200&q=80',
        ),
        VisitedRestaurantModel(
          name: 'Bánh mì Liên Hoa',
          dishes: [
            VisitedDishModel(name: 'Bánh mì xíu mại', price: 25000, quantity: 3),
          ],
          imageUrl: 'https://images.unsplash.com/photo-1619096249114-162137930819?w=200&q=80',
        ),
      ],
      notes: ['Đà Lạt khá lạnh về đêm'],
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: DateTime(2024, 5, 1),
          temperature: 18,
          totalDuration: '5 tiếng',
          locationsCount: 2,
          dayBudget: 800000,
          activities: [
            _activity('dl-001', 'Hồ Tuyền Lâm', '08:00', '10:00', 'P. 4, TP. Đà Lạt, Lâm Đồng', true, lat: 11.8942, lng: 108.4358, status: 'daDi', rating: 4.9, reviewCount: 3500),
            _activity('dl-002', 'Làng Cù Lần', '14:00', '17:00', 'Lát, Lạc Dương, Lâm Đồng', false, price: 60000, lat: 12.0125, lng: 108.3450, status: 'daDi', rating: 4.4, reviewCount: 1800),
          ],
        ),
      ],
    );
  }

  ItineraryDetailModel _mockDefaultDetail(String id) {
    return ItineraryDetailModel(
      id: id,
      title: 'Kế hoạch du lịch chi tiết',
      destination: 'Địa điểm du lịch',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
      status: 'DRAF',
      durationDays: 4,
      activitiesCount: 5,
      hotelsCount: 1,
      transportTurns: 2,
      estimatedBudget: 3000000,
      spentBudget: 0,
      notes: ['Cần cập nhật thêm chi tiết'],
      days: [
        ItineraryDayModel(
          dayNumber: 1,
          date: DateTime.now(),
          locationsCount: 1,
          dayBudget: 500000,
          totalDuration: '2 tiếng',
          activities: [_activity('d-001', 'Địa điểm tham quan', '09:00', '10:00', 'Địa chỉ cụ thể, TP.HCM', true, lat: 21.0285, lng: 105.8542, status: 'chuaDi', rating: 4.0, reviewCount: 100)],
        ),
      ],
    );
  }

  ItineraryActivityModel _activity(
    String id, 
    String title, 
    String start, 
    String end, 
    String specificAddr, 
    bool free, {
    double price = 0, 
    double? lat, 
    double? lng, 
    String? status,
    double? rating,
    int? reviewCount,
  }) {
    return ItineraryActivityModel(
      id: id,
      title: title,
      startTime: start,
      endTime: end,
      locationName: title,
      address: specificAddr,
      imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80',
      isFree: free,
      price: price,
      transportInfo: '10-20 phút di chuyển',
      latitude: lat,
      longitude: lng,
      status: status,
      rating: rating,
      reviewCount: reviewCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote placeholder — kích hoạt khi có backend.
// ─────────────────────────────────────────────────────────────────────────────
// class RemoteItineraryDataSource implements ItineraryDataSource {
//   final DioClient _client;
//   RemoteItineraryDataSource(this._client);
//
//   @override
//   Future<List<ItineraryModel>> getItineraries() async {
//     final res = await _client.dio.get('/itineraries');
//     return (res.data as List)
//         .map((e) => ItineraryModel.fromJson(e))
//         .toList();
//   }
//
//   @override
//   Future<void> deleteItinerary(String id) async {
//     await _client.dio.delete('/itineraries/$id');
//   }
// }