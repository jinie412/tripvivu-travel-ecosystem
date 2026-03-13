import '../models/itinerary_model.dart';

/// Hợp đồng cho nguồn dữ liệu lịch trình.
abstract class ItineraryDataSource {
  Future<List<ItineraryModel>> getItineraries();
  Future<void> deleteItinerary(String id);
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — trả dữ liệu giả giống hệt Figma.
// ─────────────────────────────────────────────────────────────────────────────
class MockItineraryDataSource implements ItineraryDataSource {
  /// Danh sách lưu trữ nội bộ để hỗ trợ thao tác xóa trên mock.
  final List<ItineraryModel> _items = [
    // ── Sắp đi (upcoming) ─────────────────────────────────────────────────
    ItineraryModel(
      id: 'itin-001',
      title: 'Sài Gòn 3N2Đ',
      imageUrl:
          'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80',
      startDate: DateTime(2024, 10, 15),
      endDate: DateTime(2024, 10, 17),
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
      startDate: DateTime(2024, 11, 1),
      endDate: DateTime(2024, 11, 5),
      estimatedCost: 8500000,
      currency: 'VNĐ',
      durationDays: 5,
      progress: 0.45,
      status: 'upcoming',
      placeholderColor: 0xFF26A69A,
    ),
    // ── Đã đi (completed) ─────────────────────────────────────────────────
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
