import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationCubit>()..loadNotifications(),
      child: Drawer(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thông báo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    if (state is NotificationLoading || state is NotificationInitial) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is NotificationError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (state is NotificationLoaded) {
                      if (state.notifications.isEmpty) {
                        return const Center(
                          child: Text('Không có thông báo nào.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: state.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return _buildNotificationItem(context, notification);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationEntity notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: notification.isUnread ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _iconColorFor(notification.notificationType).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _iconFor(notification.iconKey),
                color: _iconColorFor(notification.notificationType),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (notification.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    notification.content,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                    notification.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('map')) {
      return Icons.map;
    } else if (lowerKey.contains('star')) {
      return Icons.star;
    } else if (lowerKey.contains('restaurant')) {
      return Icons.restaurant;
    } else if (lowerKey.contains('info')) {
      return Icons.info;
    }
    return Icons.notifications;
  }

  Color _iconColorFor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('review')) {
      return Colors.orange;
    } else if (lowerType.contains('food')) {
      return Colors.red;
    } else if (lowerType.contains('itinerary')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

}
