import '../models/destination_model.dart';
import '../models/hotel_model.dart';
import '../models/trip_suggestion_model.dart';

/// Contract for home screen data.
abstract class HomeDataSource {
  Future<List<TripSuggestionModel>> getSuggestions();
  Future<List<DestinationModel>> getDestinations();
  Future<List<HotelModel>> getHotels();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — simulates API with picsum.photos image URLs.
// ─────────────────────────────────────────────────────────────────────────────
class MockHomeDataSource implements HomeDataSource {
  @override
  Future<List<TripSuggestionModel>> getSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      TripSuggestionModel(id: 'trip-001', title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm', days: '3 ngày', location: 'Kiên Giang', views: '2.4k', likes: '512', imageUrl: 'https://images.unsplash.com/photo-1589782182703-2aad69637b3b?w=600&q=80', placeholderColor: 0xFF4A90D9),
      TripSuggestionModel(id: 'trip-002', title: 'Du lịch Hà Nội Hà Tây', days: '4 ngày', location: 'Hà Nội', views: '1.8k', likes: '324', imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80', placeholderColor: 0xFF6C9E5C),
      TripSuggestionModel(id: 'trip-003', title: 'Khám phá Quy Nhơn kỳ vĩ', days: '5 ngày', location: 'Bình Định', views: '892', likes: '201', imageUrl: 'https://images.unsplash.com/photo-1583483425010-c566a31bc9f8?w=600&q=80', placeholderColor: 0xFF5E7FA0),
      TripSuggestionModel(id: 'trip-004', title: 'Khám phá Đà Lạt mộng mơ', days: '3 ngày', location: 'Lâm Đồng', views: '1.1k', likes: '287', imageUrl: 'https://images.unsplash.com/photo-1596392916540-8f9216067da1?w=600&q=80', placeholderColor: 0xFF7D5E92),
      TripSuggestionModel(id: 'trip-005', title: 'Hành trình di sản Hội An', days: '2 ngày', location: 'Quảng Nam', views: '3.5k', likes: '1.2k', imageUrl: 'https://images.unsplash.com/photo-1588094978307-77e11c3b24a6?w=600&q=80', placeholderColor: 0xFF8B7355),
      TripSuggestionModel(id: 'trip-006', title: 'Sapa – Thành phố trong sương', days: '4 ngày', location: 'Lào Cai', views: '2.1k', likes: '645', imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=600&q=80', placeholderColor: 0xFF4A8C5C),
    ];
  }

  @override
  Future<List<DestinationModel>> getDestinations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DestinationModel(id: 'dest-001', name: 'Sapa', imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=300&q=80', placeholderColor: 0xFF4A8C5C),
      DestinationModel(id: 'dest-002', name: 'Hội An', imageUrl: 'https://images.unsplash.com/photo-1588094978307-77e11c3b24a6?w=300&q=80', placeholderColor: 0xFF8B7355),
      DestinationModel(id: 'dest-003', name: 'Đà Lạt', imageUrl: 'https://images.unsplash.com/photo-1596401037688-69cb907abf12?w=300&q=80', placeholderColor: 0xFF3D7A5E),
      DestinationModel(id: 'dest-004', name: 'Hạ Long', imageUrl: 'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=300&q=80', placeholderColor: 0xFF2E6B8A),
      DestinationModel(id: 'dest-005', name: 'Đà Nẵng', imageUrl: 'https://plus.unsplash.com/premium_photo-1675826774815-35b8a48ddc2c?w=300&q=80', placeholderColor: 0xFF1565C0),
      DestinationModel(id: 'dest-006', name: 'Ninh Bình', imageUrl: 'https://images.unsplash.com/photo-1610444583737-25e4f4a3e6de?w=300&q=80', placeholderColor: 0xFF4E7A3D),
      DestinationModel(id: 'dest-007', name: 'Huế', imageUrl: 'https://images.unsplash.com/photo-1599708153386-62ea1f23722e?w=300&q=80', placeholderColor: 0xFF7D5E92),
      DestinationModel(id: 'dest-008', name: 'Mũi Né', imageUrl: 'https://images.unsplash.com/photo-1506461883276-594a12b11cf3?w=300&q=80', placeholderColor: 0xFFE0C492),
    ];
  }

  @override
  Future<List<HotelModel>> getHotels() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      HotelModel(id: 'hotel-001', name: 'Inter Phu Quoc', rating: 4.9, price: '2.500.000đ', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80', placeholderColor: 0xFFD4C5B0),
      HotelModel(id: 'hotel-002', name: 'JW Marriott', rating: 4.8, price: '3.200.000đ', imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&q=80', placeholderColor: 0xFF8DACC4),
      HotelModel(id: 'hotel-003', name: 'Pullman Vung Tau', rating: 4.7, price: '2.100.000đ', imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&q=80', placeholderColor: 0xFFB0C4D4),
      HotelModel(id: 'hotel-004', name: 'Vinpearl Nha Trang', rating: 4.9, price: '1.900.000đ', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80', placeholderColor: 0xFFE5DED4),
      HotelModel(id: 'hotel-005', name: 'Mường Thanh Luxury', rating: 4.5, price: '1.500.000đ', imageUrl: 'https://images.unsplash.com/photo-1551882547-ff43c63efe8c?w=400&q=80', placeholderColor: 0xFFD4E5DE),
      HotelModel(id: 'hotel-006', name: 'Saigon Prince Hotel', rating: 4.6, price: '1.800.000đ', imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&q=80', placeholderColor: 0xFFDED4E5),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote placeholder — activate when backend is ready.
// ─────────────────────────────────────────────────────────────────────────────
// class RemoteHomeDataSource implements HomeDataSource {
//   final DioClient _client;
//   RemoteHomeDataSource(this._client);
//
//   @override
//   Future<List<TripSuggestionModel>> getSuggestions() async {
//     final res = await _client.dio.get('/home/suggestions');
//     return (res.data as List).map((e) => TripSuggestionModel.fromJson(e)).toList();
//   }
//   ...
// }
