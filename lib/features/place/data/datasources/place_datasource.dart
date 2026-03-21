import '../models/place_model.dart';
import '../models/place_detail_model.dart';
import '../models/place_review_model.dart';

abstract class PlaceDataSource {
  Future<PlaceDetailModel> getPlaceDetail(String id);
}

class MockPlaceDataSource implements PlaceDataSource {
  @override
  Future<PlaceDetailModel> getPlaceDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return PlaceDetailModel(
      id: 'nh-001',
      name: 'Nhà hát Thành phố Hồ Chí Minh',
      address: '7 Công Trường Lam Sơn, Quận 1, TP. HCM',
      district: 'Quận 1',
      city: 'TP. HCM',
      rating: 4.5,
      totalReviews: 1248,
      tags: ['Văn hóa - lịch sử', 'Tham quan - chụp ảnh'],
      images: [
        'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800&q=80',
        'https://images.unsplash.com/photo-1552011335-41e893e95c1c?w=800&q=80',
        'https://images.unsplash.com/photo-1596401037688-69cb907abf12?w=800&q=80',
        'https://images.unsplash.com/photo-1508919892451-4b8495bc44ed?w=800&q=80',
      ],
      description: 'Nhà Hát Lớn Thành Phố - Thăm quan & chụp ảnh. Sân khấu tại 7 Công Trường Lam Sơn, Quận 1, TP. HCM. Giá bình quân đầu người: 80.000đ - 350.000đ. Đây là công trình kiến trúc đặc sắc của Sài Gòn.',
      openingHours: '10:00',
      closingHours: '23:00',
      phone: '(028) 38 299 919',
      isFavorite: true,
      reviews: [
        PlaceReviewModel(
          id: 'rv-001',
          userName: 'Minh Anh Trần',
          userAvatar: 'https://i.pravatar.cc/150?u=minhanh',
          rating: 5,
          timeAgo: '3 ngày trước',
          reviewText: 'Kiến trúc rất đẹp và cổ kính, buổi tối lên đèn lung linh lắm, cực kỳ hợp để check-in sống ảo.',
          reviewImages: ['https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400&q=80'],
        ),
        PlaceReviewModel(
          id: 'rv-002',
          userName: 'Thế Hùng',
          userAvatar: 'https://i.pravatar.cc/150?u=thehung',
          rating: 4,
          timeAgo: '1 tuần trước',
          reviewText: 'Địa điểm ngay trung tâm, dễ tìm. Tuy nhiên khá đông đúc vào cuối tuần.',
        ),
      ],
      relatedPlaces: [
        PlaceModel(
          id: 'pl-related-001',
          name: 'Bảo tàng Mỹ thuật',
          imageUrl: 'https://images.unsplash.com/photo-1565039030686-34247e0e800a?w=400&q=80',
          rating: 4.6,
          district: 'Quận 1',
          city: 'TP. HCM',
        ),
        PlaceModel(
          id: 'pl-related-002',
          name: 'Chùa Ngọc Hoàng',
          imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=400&q=80',
          rating: 4.7,
          district: 'Quận 3',
          city: 'TP. HCM',
        ),
      ],
    );
  }
}
