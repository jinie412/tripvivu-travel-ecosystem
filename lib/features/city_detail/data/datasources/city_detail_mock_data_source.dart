import 'package:travel_advisor_mobile/features/city_detail/data/models/city_models.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';

abstract class CityDetailDataSource {
  Future<List<CityItineraryModel>> getItineraries(String cityId);
  Future<List<CityActivityModel>> getActivities(String cityId);
  Future<List<CityRestaurantModel>> getRestaurants(String cityId);
  Future<List<CityHotelModel>> getHotels(String cityId);
}

class CityDetailMockDataSource implements CityDetailDataSource {
  @override
  Future<List<CityItineraryModel>> getItineraries(String cityId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityItineraryModel(
        id: 'i1',
        title: 'Khám phá Sài Gòn 3 ngày từ Quận 1 đến Chợ Lớn',
        authorName: 'Minh Anh',
        authorAvatar: 'https://i.pravatar.cc/150?u=minhanh',
        imageUrl:
            'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800&q=80',
        duration: '3 NGÀY',
        views: '1.2k',
        likes: '458',
      ),
      CityItineraryModel(
        id: 'i2',
        title: 'Food Tour Sài Gòn: 10 món phải thử trong 24h',
        authorName: 'Linh Trần',
        authorAvatar: 'https://i.pravatar.cc/150?u=linhtran',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
        duration: '1 NGÀY',
        views: '3.5k',
        likes: '920',
      ),
      CityItineraryModel(
        id: 'i3',
        title: 'Di sản Sài Gòn: Hành trình qua những công trình cổ',
        authorName: 'Hoàng Nam',
        authorAvatar: 'https://i.pravatar.cc/150?u=hoangnam',
        imageUrl:
            'https://images.unsplash.com/photo-1596541223130-5d31a73fb6c6?w=800&q=80',
        duration: '2 NGÀY',
        views: '856',
        likes: '124',
      ),
      CityItineraryModel(
        id: 'i4',
        title: 'Góc nhỏ Sài Gòn: Những quán cafe cực chill',
        authorName: 'Quốc Bảo',
        authorAvatar: 'https://i.pravatar.cc/150?u=quocbao',
        imageUrl:
            'https://cdn2.tuoitre.vn/471584752817336320/data/teen360/pictures/2018/11/28/1543423457_cafe-sg-81.jpg',
        duration: '1 NGÀY',
        views: '1.5k',
        likes: '310',
      ),
    ];
  }

  @override
  Future<List<CityActivityModel>> getActivities(String cityId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityActivityModel(
        id: 'a1',
        title: 'Chợ Bến Thành',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Ben_Thanh_market_2.jpg/330px-Ben_Thanh_market_2.jpg',
        rating: 4.5,
        reviewCount: 1200,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        category: 'cultural_history',
        priceType: 'free',
        district: 'Quận 1',
      ),
      CityActivityModel(
        id: 'a2',
        title: 'Bưu điện Trung tâm',
        imageUrl:
            'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/2e/8c/e2/12/caption.jpg?w=900&h=500&s=1',
        rating: 4.7,
        reviewCount: 3500,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        isFavorite: true,
        // === Filter fields ===
        category: 'cultural_history',
        priceType: 'free',
        district: 'Quận 1',
      ),
      CityActivityModel(
        id: 'a3',
        title: 'Dinh Độc Lập',
        imageUrl:
            'https://ik.imagekit.io/tvlk/blog/2025/04/dinh-doc-lap.jpg?tr=q-70,c-at_max,w-1000,h-600',
        rating: 4.6,
        reviewCount: 2800,
        address: 'Quận 1, TP.HCM',
        status: 'Đã đóng cửa',
        // === Filter fields ===
        category: 'cultural_history',
        priceType: 'paid',
        district: 'Quận 1',
      ),
      CityActivityModel(
        id: 'a4',
        title: 'Nhà thờ Đức Bà',
        imageUrl:
            'https://image.vietgoing.com/destination/large/vietgoing_mzh2503128324.webp',
        rating: 4.4,
        reviewCount: 1900,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        category: 'cultural_history',
        priceType: 'free',
        district: 'Quận 1',
      ),
      CityActivityModel(
        id: 'a5',
        title: 'Thảo Cầm Viên',
        imageUrl:
            'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?w=500',
        rating: 4.2,
        reviewCount: 950,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        category: 'nature',
        priceType: 'paid',
        district: 'Quận 1',
      ),
      CityActivityModel(
        id: 'a6',
        title: 'Đầm Sen Park',
        imageUrl:
            'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=500',
        rating: 4.0,
        reviewCount: 680,
        address: 'Quận 11, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        category: 'entertainment',
        priceType: 'paid',
        district: 'Quận 11',
      ),
    ];
  }

  @override
  Future<List<CityRestaurantModel>> getRestaurants(String cityId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityRestaurantModel(
        id: 'r1',
        name: 'Secret Garden Restaurant',
        imageUrl:
            'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/1a/e5/d3/a8/the-rooftop-ambience.jpg?w=900&h=500&s=1',
        rating: 4.8,
        reviewCount: 1240,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        cuisine: 'vietnamese',
        priceLevel: 'mid_range',
        amenities: ['air_con'],
      ),
      CityRestaurantModel(
        id: 'r2',
        name: "Pizza 4P's Bến Thành",
        imageUrl:
            'https://doanhnhanplus.vn/wp-content/uploads/2018/05/DN-nha-hang-pizza-4P-Ben-Thanh-Tin-030518-21.jpg',
        rating: 4.9,
        reviewCount: 3500,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        cuisine: 'foreign',
        priceLevel: 'mid_range',
        amenities: ['air_con', 'kid_friendly'],
      ),
      CityRestaurantModel(
        id: 'r3',
        name: 'Nha Hang Ngon',
        imageUrl:
            'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=500',
        rating: 4.4,
        reviewCount: 850,
        address: 'Quận 1, TP.HCM',
        status: 'Đã đóng cửa',
        // === Filter fields ===
        cuisine: 'vietnamese',
        priceLevel: 'budget',
        amenities: ['parking', 'air_con'],
      ),
      CityRestaurantModel(
        id: 'r4',
        name: 'Cuc Gach Quan',
        imageUrl:
            'https://ta-img.tatinta.com/resize/1024/webp/destination/file-1627375450588.jpg',
        rating: 4.3,
        reviewCount: 420,
        address: 'Quận 1, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        cuisine: 'vietnamese',
        priceLevel: 'premium',
        amenities: ['air_con', 'parking'],
      ),
      CityRestaurantModel(
        id: 'r5',
        name: 'Hum Vegetarian',
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500',
        rating: 4.6,
        reviewCount: 310,
        address: 'Quận 3, TP.HCM',
        status: 'Đang mở cửa',
        // === Filter fields ===
        cuisine: 'vegetarian',
        priceLevel: 'mid_range',
        amenities: ['air_con'],
      ),
    ];
  }

  @override
  Future<List<CityHotelModel>> getHotels(String cityId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      CityHotelModel(
        id: 'h1',
        name: 'The Reverie Saigon',
        imageUrl:
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=500',
        rating: 5.0,
        reviewCount: 1250,
        price: '5.450.000đ',
        // === Filter fields ===
        starRating: 5,
        priceValue: 5450000,
        accommodationType: 'hotel',
        amenities: ['pool', 'wifi', 'breakfast', 'gym'],
      ),
      CityHotelModel(
        id: 'h2',
        name: 'Park Hyatt Saigon',
        imageUrl:
            'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=500',
        rating: 4.8,
        reviewCount: 850,
        price: '4.200.000đ',
        // === Filter fields ===
        starRating: 5,
        priceValue: 4200000,
        accommodationType: 'hotel',
        amenities: ['pool', 'wifi', 'breakfast', 'gym'],
      ),
      CityHotelModel(
        id: 'h3',
        name: 'Caravelle Saigon',
        imageUrl:
            'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=500',
        rating: 4.6,
        reviewCount: 620,
        price: '1.500.000đ',
        // === Filter fields ===
        starRating: 4,
        priceValue: 1500000,
        accommodationType: 'hotel',
        amenities: ['pool', 'wifi', 'breakfast'],
      ),
      CityHotelModel(
        id: 'h4',
        name: 'InterContinental Saigon',
        imageUrl:
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=500',
        rating: 4.7,
        reviewCount: 940,
        price: '1.800.000đ',
        // === Filter fields ===
        starRating: 5,
        priceValue: 1800000,
        accommodationType: 'hotel',
        amenities: ['pool', 'wifi', 'breakfast', 'gym'],
      ),
      CityHotelModel(
        id: 'h5',
        name: 'Saigon Homestay Cozy',
        imageUrl:
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=500',
        rating: 4.3,
        reviewCount: 180,
        price: '450.000đ',
        // === Filter fields ===
        starRating: 2,
        priceValue: 450000,
        accommodationType: 'homestay',
        amenities: ['wifi'],
      ),
      CityHotelModel(
        id: 'h6',
        name: 'Fusion Resort Saigon',
        imageUrl:
            'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=500',
        rating: 4.9,
        reviewCount: 520,
        price: '3.200.000đ',
        // === Filter fields ===
        starRating: 4,
        priceValue: 3200000,
        accommodationType: 'resort',
        amenities: ['pool', 'wifi', 'breakfast', 'gym'],
      ),
    ];
  }
}

class RemoteCityDetailDataSource implements CityDetailDataSource {
  final DioClient _client;

  RemoteCityDetailDataSource(this._client);

  final Map<String, Future<Map<String, dynamic>>> _overviewCache = {};

  Future<Map<String, dynamic>> _fetchOverview(String cityId) {
    return _overviewCache.putIfAbsent(cityId, () async {
      final response = await _client.dio.get('/explore/cities/$cityId/overview');
      return (response.data as Map).cast<String, dynamic>();
    });
  }

  List<Map<String, dynamic>> _asList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
  }

  @override
  Future<List<CityItineraryModel>> getItineraries(String cityId) async {
    final data = await _fetchOverview(cityId);
    return _asList(data['itineraries'])
        .map(CityItineraryModel.fromJson)
        .toList();
  }

  @override
  Future<List<CityActivityModel>> getActivities(String cityId) async {
    final data = await _fetchOverview(cityId);
    return _asList(data['activities'])
        .map(CityActivityModel.fromJson)
        .toList();
  }

  @override
  Future<List<CityRestaurantModel>> getRestaurants(String cityId) async {
    final data = await _fetchOverview(cityId);
    return _asList(data['restaurants'])
        .map(CityRestaurantModel.fromJson)
        .toList();
  }

  @override
  Future<List<CityHotelModel>> getHotels(String cityId) async {
    final data = await _fetchOverview(cityId);
    return _asList(data['hotels'])
        .map(CityHotelModel.fromJson)
        .toList();
  }
}