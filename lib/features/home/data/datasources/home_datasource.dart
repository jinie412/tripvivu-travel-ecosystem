import '../models/destination_model.dart';
import '../models/hotel_model.dart';
import '../models/trip_suggestion_model.dart';
import '../../../city_detail/domain/entities/city_entities.dart';

/// Contract for home screen data.
abstract class HomeDataSource {
  Future<List<TripSuggestionModel>> getSuggestions();
  Future<List<DestinationModel>> getDestinations();
  Future<List<HotelModel>> getHotels();
  Future<List<CityRestaurant>> getRestaurants();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — simulates API with picsum.photos image URLs.
// ─────────────────────────────────────────────────────────────────────────────
class MockHomeDataSource implements HomeDataSource {
  @override
  Future<List<TripSuggestionModel>> getSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      TripSuggestionModel(id: 'trip-001', title: 'Kỳ nghỉ Phú Quốc tuyệt phẩm', days: '3 ngày', location: 'Phú Quốc', views: '2.4k', likes: '512', imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=600&q=80', placeholderColor: 0xFF4A90D9),
      TripSuggestionModel(id: 'trip-002', title: 'Du lịch Hà Nội Hà Tây', days: '4 ngày', location: 'Hà Nội', views: '1.8k', likes: '324', imageUrl: 'https://vcdn1-dulich.vnecdn.net/2022/05/12/Hanoi2-1652338755-3632-1652338809.jpg?w=0&h=0&q=100&dpr=2&fit=crop&s=NxMN93PTvOTnHNryMx3xJw', placeholderColor: 0xFF6C9E5C),
      TripSuggestionModel(id: 'trip-003', title: 'Khám phá Quy Nhơn kỳ vĩ', days: '5 ngày', location: 'Quy Nhơn', views: '892', likes: '201', imageUrl: 'https://quynhontourist.com/wp-content/uploads/2020/11/tour-ky-co-eo-gio-1-ngay-du-lich-ky-co-quy-nhon-quy-nhon-tourist.jpg', placeholderColor: 0xFF5E7FA0),
      TripSuggestionModel(id: 'trip-004', title: 'Khám phá Đà Lạt mộng mơ', days: '3 ngày', location: 'Đà Lạt', views: '1.1k', likes: '287', imageUrl: 'https://samtenhills.vn/wp-content/uploads/2024/01/top-20-cac-diem-du-lich-da-lat-1024x576.jpg', placeholderColor: 0xFF7D5E92),
    ];
  }

  @override
  Future<List<DestinationModel>> getDestinations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DestinationModel(id: 'dest-001', name: 'Đỉnh Fansipan', imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1yCd0xZihK46J355FPzH8jZBXlnRRx-rzWw&s', placeholderColor: 0xFF4A8C5C),
      DestinationModel(id: 'dest-002', name: 'Phố cổ Hội An', imageUrl: 'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg', placeholderColor: 0xFF8B7355),
      DestinationModel(id: 'dest-003', name: 'Thung lũng Tình Yêu', imageUrl: 'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_630/w_80,x_15,y_15,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/t8ojjwnqqzgxuqr80k2o/V%C3%A9ThamQuanThungL%C5%A9ngT%C3%ACnhY%C3%AAu%E1%BB%9F%C4%90%C3%A0L%E1%BA%A1t-KlookVi%E1%BB%87tNam.jpg', placeholderColor: 0xFF3D7A5E),
      DestinationModel(id: 'dest-004', name: 'Vịnh Hạ Long', imageUrl: 'https://www.dulichhalong.net/wp-content/uploads/2020/07/Vinh-Ha-Long-Quang-Ninh.jpg', placeholderColor: 0xFF2E6B8A),
    ];
  }

  @override
  Future<List<HotelModel>> getHotels() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      HotelModel(id: 'hotel-001', name: 'Inter Phu Quoc', rating: 4.9, price: '2.500.000đ', imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80', placeholderColor: 0xFFD4C5B0),
      HotelModel(id: 'hotel-002', name: 'JW Marriott', rating: 4.8, price: '3.200.000đ', imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80', placeholderColor: 0xFF8DACC4),
      HotelModel(id: 'hotel-003', name: 'Pullman Vung Tau', rating: 4.7, price: '2.100.000đ', imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&q=80', placeholderColor: 0xFFB0C4D4),
      HotelModel(id: 'hotel-004', name: 'Vinpearl Nha Trang', rating: 4.9, price: '1.900.000đ', imageUrl: 'https://du-lich.chudu24.com/f/m/2306/16/vinpearl-nha-trang-resort-3.jpg?w=800&h=500', placeholderColor: 0xFFE5DED4),
    ];
  }

  @override
  Future<List<CityRestaurant>> getRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityRestaurant(
        id: 'res-001',
        name: 'Cơm tấm Ba Ghiền',
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
        rating: 4.8,
        reviewCount: 1200,
        address: 'Đặng Văn Ngữ, Phú Nhuận',
        status: 'Đang mở cửa',
      ),
      CityRestaurant(
        id: 'res-002',
        name: 'Phở Hòa Pasteur',
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
        rating: 4.7,
        reviewCount: 850,
        address: 'Pasteur, Quận 3',
        status: 'Đang mở cửa',
      ),
      CityRestaurant(
        id: 'res-003',
        name: 'Bún Chả Hương Liên',
        imageUrl: 'https://kenh14cdn.com/zoom/594_371/203336854389633024/2024/3/21/photo1711023527181-17110235273471578523867.jpg',
        rating: 4.9,
        reviewCount: 2100,
        address: 'Lê Văn Hưu, Hà Nội',
        status: 'Đang mở cửa',
      ),
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
