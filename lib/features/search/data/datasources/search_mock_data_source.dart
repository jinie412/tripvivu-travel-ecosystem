import '../models/search_location_model.dart';

abstract class SearchMockDataSource {
  Future<List<SearchLocationModel>> getRecentSearches();
  Future<List<SearchLocationModel>> searchLocations(String query);
}

class SearchMockDataSourceImpl implements SearchMockDataSource {
  final List<SearchLocationModel> _mockData = const [
    SearchLocationModel(
      id: '1',
      name: 'Thủ đô Hà Nội',
      imageUrl: 'https://nhn.1cdn.vn/2025/01/14/1657cnru.png',
      type: 'city',
    ),
    SearchLocationModel(
      id: '2',
      name: 'Vịnh Hạ Long',
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=500&q=80',
      type: 'city',
    ),
    SearchLocationModel(
      id: 'nh-001',
      name: 'Nhà hát Thành phố Hồ Chí Minh',
      imageUrl: 'https://kyhoatourist.com.vn/uploadwb/image/tintuc/nha-hat-lon-2.jpg',
      type: 'place',
    ),
    SearchLocationModel(
      id: '4',
      name: 'TP. Hồ Chí Minh',
      imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=500&q=80',
      type: 'city',
    ),
    SearchLocationModel(
      id: '5',
      name: 'TP. Đà Nẵng',
      imageUrl: 'https://picsum.photos/seed/danang/500/500',
      type: 'city',
    ),
    SearchLocationModel(
      id: '6',
      name: 'Hội An',
      imageUrl: 'https://vcdn1-dulich.vnecdn.net/2022/06/01/Hoi-An-VnExpress-5851-16488048-4863-2250-1654057244.jpg?w=0&h=0&q=100&dpr=2&fit=crop&s=k1SeSD7zn2e69TSWKfpoag',
      type: 'city',
    ),
    SearchLocationModel(
      id: '7',
      name: 'Đà Lạt',
      imageUrl: 'https://samtenhills.vn/wp-content/uploads/2024/01/top-20-cac-diem-du-lich-da-lat-1024x576.jpg',
      type: 'city',
    ),
    SearchLocationModel(
      id: '8',
      name: 'Nha Trang',
      imageUrl: 'https://baokhanhhoa.vn/file/e7837c02857c8ca30185a8c39b582c03/012025/z6223362576777_15a21ef00a73b25851a3972d86795475_20250113104122.jpg',
      type: 'city',
    ),
    SearchLocationModel(
      id: 'pl-related-001',
      name: 'Bảo tàng Mỹ thuật',
      imageUrl: 'https://cdn2.fptshop.com.vn/unsafe/1920x0/filters:format(webp):quality(75)/bao_tang_my_thuat_2_5830af02a8.png',
      type: 'place',
    ),
    SearchLocationModel(
      id: '10',
      name: 'Sapa',
      imageUrl: 'https://pystravel.vn/_next/image?url=https%3A%2F%2Fbooking.pystravel.vn%2Fuploads%2Fposts%2Favatar%2F1740370327.jpg&w=3840&q=75',
      type: 'city',
    )
  ];

  @override
  Future<List<SearchLocationModel>> getRecentSearches() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data matching Figma exactly
    return _mockData.take(4).toList();
  }

  @override
  Future<List<SearchLocationModel>> searchLocations(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    return _mockData.where((location) {
      final name = location.name.toLowerCase();
      
      // Nếu người dùng chỉ gõ chung chung "thành phố" hoặc "tp" -> Show tất cả các thành phố
      if (q == 'thành phố' || q == 'thanh pho' || q == 'tp' || q == 'tp.') {
        return location.type == 'city';
      }

      // Trường hợp gõ "thành phố đà nẵng" nhưng mock data là "đà nẵng" 
      // -> Loại bỏ các từ khóa thừa để tăng tỉ lệ khớp
      String normalizedQ = q
          .replaceAll('thành phố', '')
          .replaceAll('thanh pho', '')
          .replaceAll('tp.', '')
          .replaceAll('tp ', '')
          .trim();

      // Mở rộng cả Tên trong Mock Data (ví dụ: "tp. hồ chí minh" thành "thành phố hồ chí minh")
      String expandedName = name.replaceAll('tp.', 'thành phố').replaceAll('tp ', 'thành phố ');

      // Nếu sau khi bỏ chữ "thành phố" mà từ khóa vẫn còn nội dung, ưu tiên match nội dung đó
      if (normalizedQ.isNotEmpty && name.contains(normalizedQ)) {
        return true;
      }

      return name.contains(q) || expandedName.contains(q);
    }).toList();
  }
}
