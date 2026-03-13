import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/activity_item_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/activity_list_widget.dart';
import '../widgets/food_order_list_widget.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Thông tin cá nhân',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProfileError) {
            return _buildErrorState(context, state.message);
          } else if (state is ProfileLoaded) {
            return _buildContent(context, state.profile, state.activities);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<ProfileCubit>().loadProfile(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ProfileEntity profile, List<ActivityItemEntity> activities) {
    final itineraryItems =
        activities.where((a) => a.type == ActivityType.itinerary).toList();
    final ratedItems =
        activities.where((a) => a.type == ActivityType.rated).toList();
    final reviewPendingItems =
        activities.where((a) => a.type == ActivityType.reviewPending).toList();
    final foodItems =
        activities.where((a) => a.type == ActivityType.food).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeader(profile: profile),
          const SizedBox(height: 24),
          _buildSection('Lịch trình & Địa điểm',
              ActivityListWidget(items: itineraryItems)),
          const SizedBox(height: 16),
          _buildSection('Địa điểm đã đánh giá',
              ActivityListWidget(items: ratedItems)),
          const SizedBox(height: 16),
          _buildSectionWithBadge(
            'Địa điểm chờ đánh giá',
            profile.reviewPendingCount,
            ActivityListWidget(items: reviewPendingItems),
          ),
          const SizedBox(height: 16),
          _buildSection(
              'Đơn hàng của tôi', FoodOrderListWidget(items: foodItems)),
          const SizedBox(height: 32),
          _buildSettingsMenu(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSectionWithBadge(String title, int count, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (count > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildSettingsMenu() {
    return Column(
      children: [
        _buildListTile(Icons.settings_outlined, 'Cài đặt tài khoản'),
        _buildListTile(Icons.exit_to_app_rounded, 'Đăng xuất',
            isDestructive: true),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title,
      {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : const Color(0xFF1C1C1E);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: color)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

