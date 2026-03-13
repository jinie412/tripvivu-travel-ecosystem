import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/profile/domain/entities/activity_item_entity.dart';
import '../../../../features/profile/domain/entities/profile_entity.dart';
import '../../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../../features/profile/presentation/cubit/profile_state.dart';
import '../../../../features/review/presentation/screens/rate_itinerary_screen.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: BlocProvider(
        create: (_) => sl<ProfileCubit>()..loadProfile(),
        child: const _DrawerContent(),
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileError) {
          return Center(child: Text(state.message));
        }
        if (state is ProfileLoaded) {
          return _buildBody(context, state.profile, state.activities);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBody(
      BuildContext context, ProfileEntity profile, List<ActivityItemEntity> activities) {
    final itineraryItems =
        activities.where((a) => a.type == ActivityType.itinerary).toList();
    final ratedItems = activities.where((a) => a.type == ActivityType.rated).toList();
    final pendingItems =
        activities.where((a) => a.type == ActivityType.reviewPending).toList();
    final foodItems = activities.where((a) => a.type == ActivityType.food).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blobLight, width: 2),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 4),
                      Text(profile.membershipTier,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // Lịch trình
            const _PillHeader(
                icon: Icons.calendar_today_outlined, label: 'LỊCH TRÌNH & ĐỊA ĐIỂM'),
            const _SubHeader(label: 'Sắp đến'),
            ...itineraryItems
                .map((e) => _ActivityTile(item: e, icon: Icons.bed_outlined, isImage: false)),
            const SizedBox(height: 16),

            // Đánh giá
            const _PillHeader(
                icon: Icons.star_border_rounded, label: 'ĐÁNH GIÁ ĐỊA ĐIỂM'),
            const _SubHeader(label: 'Đã đánh giá'),
            ...ratedItems.map((e) => _ActivityTile(
                item: e, icon: Icons.location_on_outlined, isImage: false)),
            
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 8, top: 4),
                child: Text('Xem tất cả', 
                    style: TextStyle(color: AppColors.primary.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            _SubHeader(
                label: 'Chờ đánh giá',
                trailing: profile.reviewPendingCount > 0 ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF44336), // Red
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    profile.reviewPendingCount.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ) : null,
            ),
            ...pendingItems
                .map((e) => _ActivityTile(item: e, icon: Icons.image_outlined, isImage: true)),
            const SizedBox(height: 16),

            // Ẩm thực
            const _PillHeader(
                icon: Icons.restaurant_outlined, label: 'ẨM THỰC ĐÃ ĐẶT'),
            const _SubHeader(label: 'Đơn hàng của tôi'),
            ...foodItems.map((e) => _FoodOrderCard(item: e)),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),
            const _MenuTile(
                icon: Icons.settings_outlined, label: 'Cài đặt tài khoản'),
            const _MenuTile(icon:Icons.exit_to_app_rounded, label: 'Đăng xuất'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SubHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 20, top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          trailing ?? const SizedBox(),
        ],
      ),
    );
  }
}

class _PillHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blobLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5563))),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItemEntity item;
  final IconData icon;
  final bool isImage;
  const _ActivityTile({required this.item, required this.icon, this.isImage = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (item.status == ActivityStatus.pendingReview) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RateItineraryScreen(itineraryId: item.id),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 36, right: 20, top: 4, bottom: 8),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: isImage ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isImage ? BorderRadius.circular(12) : null,
            ),
            child: Icon(isImage ? Icons.landscape_outlined : icon, color: Colors.grey.shade600, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E))),
                const SizedBox(height: 4),
                if (item.status == ActivityStatus.pendingReview)
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Chờ bạn chia sẻ',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.primary)),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (item.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFA500)),
                        const SizedBox(width: 4),
                        Text(item.rating.toString(),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      if (item.date != null)
                        Text(DateFormat('dd/MM/yyyy').format(item.date!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    ));
  }
}

class _FoodOrderCard extends StatelessWidget {
  final ActivityItemEntity item;
  const _FoodOrderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String statusText = '';
    Color statusBgColor = Colors.transparent;
    Color statusTextColor = Colors.transparent;

    if (item.status == ActivityStatus.preparing) {
      statusText = 'Đang chuẩn bị';
      statusBgColor = AppColors.blobLight.withValues(alpha: 0.3);
      statusTextColor = AppColors.primary;
    } else if (item.status == ActivityStatus.delivered) {
      statusText = 'Đã giao';
      statusBgColor = Colors.transparent;
      statusTextColor = Colors.grey.shade500;
    }

    final isPreparing = item.status == ActivityStatus.preparing;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPreparing
                  ? AppColors.blobLight.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPreparing
                  ? Icons.shopping_bag_outlined
                  : Icons.check_circle_outline,
              color: isPreparing ? AppColors.primary : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E))),
                const SizedBox(height: 2),
                Text(item.code ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (statusText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
        ],
      ),
    );
  }
}
