import '../models/activity_item_model.dart';
import '../models/profile_model.dart';
import '../../domain/entities/activity_item_entity.dart';

abstract class ProfileDataSource {
  Future<ProfileModel> getProfile();
  Future<List<ActivityItemModel>> getRecentActivities();
}

class MockProfileDataSource implements ProfileDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const ProfileModel(
      id: 'usr-1',
      name: 'Nguyễn Văn A',
      email: 'nva@example.com',
      avatarUrl: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200',
      membershipTier: 'Thành viên Vàng',
      reviewPendingCount: 2,
    );
  }

  @override
  Future<List<ActivityItemModel>> getRecentActivities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ActivityItemModel(
        id: 'act-1',
        title: 'Đà Lạt Palace Hotel',
        type: ActivityType.itinerary,
        rating: 5.0,
        date: DateTime(2023, 10, 20),
      ),
      ActivityItemModel(
        id: 'act-2',
        title: 'Chùa Linh Phước',
        type: ActivityType.rated,
        rating: 4.8,
        date: DateTime(2023, 10, 15),
      ),
      const ActivityItemModel(
        id: 'act-3',
        title: 'Hồ Tuyền Lâm',
        type: ActivityType.reviewPending,
        status: ActivityStatus.pendingReview,
      ),
      ActivityItemModel(
        id: 'act-4',
        title: 'Bánh mì xíu mại',
        type: ActivityType.food,
        code: '#TRV123',
        status: ActivityStatus.preparing,
        restaurantName: 'Cơm tấm Ba Ghiền',
        orderItems: ['Cơm tấm sườn bì chả', 'Trà đá'],
      ),
      ActivityItemModel(
        id: 'act-5',
        title: 'Lẩu gà lá é',
        type: ActivityType.food,
        code: '#TRV120',
        status: ActivityStatus.delivered,
        restaurantName: 'Lẩu gà lá é Tao Ngộ',
        orderItems: ['Lẩu gà lá é (Lớn)', 'Bún thêm'],
      ),
    ];
  }
}
