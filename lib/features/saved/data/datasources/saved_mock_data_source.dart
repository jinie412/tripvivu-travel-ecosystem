import '../../../city_detail/domain/entities/city_entities.dart';
import '../../../home/domain/entities/destination.dart';

class SavedMockDataSource {
  Future<List<CityItinerary>> getFavoriteItineraries() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const CityItinerary(
        id: '1',
        title: 'Kỳ nghỉ Quy Nhơn',
        authorName: 'Hanh Spring',
        authorAvatar: 'https://i.pravatar.cc/150?u=hanh',
        imageUrl: 'https://phetravel.com/uploads/avani-quy-nhon-resort-spa-2.jpg.webp',
        duration: '4 ngày',
        views: '1.2k',
        likes: '248',
        location: 'Quy Nhơn',
      ),
      const CityItinerary(
        id: '2',
        title: 'Khám phá Đà Lạt mộng mơ',
        authorName: 'Admin',
        authorAvatar: 'https://i.pravatar.cc/150?u=admin',
        imageUrl: 'https://statics.vinpearl.com/doi-mong-mo-da-lat_1748357420.jpg',
        duration: '3 ngày',
        views: '850',
        likes: '156',
        location: 'Đà Lạt',
      ),
    ];
  }

  Future<List<Destination>> getFavoritePlaces() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const Destination(
        id: '1',
        name: 'Cầu Vàng, Đà Nẵng',
        imageUrl: 'https://hellodanang.vn/wp-content/uploads/2024/09/cau-vang-bieu-tuong-kien-truc-an-tuong-tai-da-nang-1.jpg',
        placeholderColor: 0xFFE0F7FA,
      ),
      const Destination(
        id: '2',
        name: 'Phố cổ Hội An',
        imageUrl: 'https://lalago.vn/wp-content/uploads/2025/08/pho-co-hoi-an-ve-dem-3.jpg',
        placeholderColor: 0xFFFFF3E0,
      ),
      const Destination(
        id: '3',
        name: 'Nhà thờ Đức Bà',
        imageUrl: 'https://image.vietgoing.com/destination/large/vietgoing_mzh2503128324.webp',
        placeholderColor: 0xFFFBE9E7,
      ),
      const Destination(
        id: '4',
        name: 'Vịnh Hạ Long',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=1000&auto=format&fit=crop',
        placeholderColor: 0xFFE1F5FE,
      ),
    ];
  }
}
