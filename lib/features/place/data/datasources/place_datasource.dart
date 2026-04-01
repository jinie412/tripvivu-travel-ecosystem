import 'package:travel_advisor_mobile/features/place/data/models/place_detail_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_model.dart';
import 'package:travel_advisor_mobile/features/place/data/models/place_review_model.dart';

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
        'https://kyhoatourist.com.vn/uploadwb/image/tintuc/nha-hat-lon-2.jpg',
        'https://static.vinwonders.com/production/nha-hat-thanh-pho-1.jpg',
        'https://res.klook.com/images/fl_lossy.progressive,q_65/c_fill,w_1200,h_811/w_74,x_13,y_13,g_south_west,l_Klook_water_br_trans_yhcmh3/activities/i64sjejsothrtuqz43ap/V%C3%A9%C3%80%E1%BB%90Show%E1%BB%9ENh%C3%A0H%C3%A1tTh%C3%A0nhPh%E1%BB%91.jpg',
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
          imageUrl: 'https://cdn2.fptshop.com.vn/unsafe/1920x0/filters:format(webp):quality(75)/bao_tang_my_thuat_2_5830af02a8.png',
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