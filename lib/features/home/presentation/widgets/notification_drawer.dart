import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/notification_detail_screen.dart';
import 'package:travel_advisor_mobile/features/home/presentation/widgets/review_rejected_icon.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state is! NotificationLoaded ||
                    !state.notifications.any((item) => item.isUnread)) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          context.read<NotificationCubit>().markAllAsRead(),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Đánh dấu đã đọc hết'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading ||
                      state is NotificationInitial) {
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
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationEntity notification,
  ) {
    return InkWell(
      onTap: () async {
        final navigator = Navigator.of(context);
        final cubit = context.read<NotificationCubit>();
        final markAsRead = cubit.markNotificationAsRead(notification.id);
        await Future<void>.delayed(Duration.zero);
        final readNotification = notification.copyWith(isUnread: false);

        await navigator.push(
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(
              notificationId: notification.id,
              initialNotification: readNotification,
            ),
          ),
        );

        try {
          await markAsRead;
        } catch (_) {
          // The cubit restores the previous state if the request fails.
        }
        if (!context.mounted) return;
        cubit.loadNotifications(silent: true);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColorFor(notification).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isViolation(notification)
                    ? ReviewRejectedIcon(
                        size: 20,
                        color: _iconColorFor(notification),
                      )
                    : Icon(
                        _iconFor(notification),
                        color: _iconColorFor(notification),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isViolation(NotificationEntity n) {
    final t = n.notificationType.toLowerCase();
    final title = n.title.toLowerCase();
    return t == 'system' &&
        (title.contains('vi phạm') || title.contains('từ chối'));
  }

  IconData _iconFor(NotificationEntity n) {
    if (_isViolation(n)) return Icons.thumb_down_alt_outlined;
    final lowerKey = n.iconKey.toLowerCase();
    if (lowerKey.contains('map')) return Icons.map;
    if (lowerKey.contains('star')) return Icons.star;
    if (lowerKey.contains('restaurant')) return Icons.restaurant;
    if (lowerKey.contains('info')) return Icons.info;
    return Icons.notifications;
  }

  Color _iconColorFor(NotificationEntity n) {
    if (_isViolation(n)) return const Color(0xFFC0392B);
    final lowerType = n.notificationType.toLowerCase();
    if (lowerType.contains('review')) return Colors.orange;
    if (lowerType.contains('food')) return Colors.red;
    if (lowerType.contains('itinerary')) return Colors.blue;
    return Colors.grey;
  }
}
