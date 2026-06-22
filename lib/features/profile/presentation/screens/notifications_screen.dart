import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';
import 'package:travel_advisor_mobile/features/home/presentation/screens/notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _currentSort = 'Mới nhất';

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSortTile('Mới nhất'),
                _buildSortTile('Chưa đọc'),
              ],
            ),
          ),
        );
      },
    );
  }

  List<NotificationEntity> _visibleNotifications(
    List<NotificationEntity> notifications,
  ) {
    if (_currentSort == 'Chưa đọc') {
      return notifications.where((item) => item.isUnread).toList();
    }
    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s16,
                vertical: AppSizes.s8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 24,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Thông báo',
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          color: AppColorsExt.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.s48),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s24),
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  final hasUnread =
                      state is NotificationLoaded &&
                      state.notifications.any((item) => item.isUnread);

                  return Row(
                    children: [
                      _buildSortSelector(),
                      const SizedBox(width: AppSizes.s8),
                      _buildActiveSortTag(_currentSort),
                      const Spacer(),
                      if (hasUnread)
                        TextButton.icon(
                          onPressed: () =>
                              context.read<NotificationCubit>().markAllAsRead(),
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Đã đọc hết'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.s8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.s12),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<NotificationCubit, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading ||
                      state is NotificationInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is NotificationError) {
                    return _InboxMessage(
                      icon: Icons.error_outline,
                      message: state.message,
                    );
                  }

                  if (state is NotificationLoaded) {
                    final notifications = _visibleNotifications(
                      state.notifications,
                    );

                    if (notifications.isEmpty) {
                      return const _InboxMessage(
                        icon: Icons.notifications_none,
                        message: 'Hiện chưa có thông báo nào.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<NotificationCubit>().loadNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.s16,
                          vertical: AppSizes.s12,
                        ),
                        itemCount: notifications.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSizes.s8),
                        itemBuilder: (context, index) {
                          return _NotificationTile(
                            notification: notifications[index],
                            onTap: () async {
                              final cubit = context.read<NotificationCubit>();
                              final navigator = Navigator.of(context);
                              final markAsRead = cubit.markNotificationAsRead(
                                notifications[index].id,
                              );
                              await Future<void>.delayed(Duration.zero);
                              final readNotification = notifications[index]
                                  .copyWith(isUnread: false);
                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => NotificationDetailScreen(
                                    notificationId: notifications[index].id,
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
                          );
                        },
                      ),
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

  Widget _buildSortTile(String label) {
    return ListTile(
      title: Text(label),
      trailing: _currentSort == label
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _currentSort = label);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSortSelector() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s12,
          vertical: AppSizes.s8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Text(
              'Sắp xếp',
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSortTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s12,
        vertical: AppSizes.s8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.r8),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isUnread
          ? AppColors.primary.withValues(alpha: 0.06)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.s12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _iconColorFor(
                    notification.notificationType,
                  ).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(notification.iconKey),
                  color: _iconColorFor(notification.notificationType),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading2.copyWith(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: AppSizes.s8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.s4),
                    Text(
                      notification.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.78),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      notification.timeLabel,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('map')) {
      return Icons.map;
    } else if (lowerKey.contains('star')) {
      return Icons.star;
    } else if (lowerKey.contains('restaurant') || lowerKey.contains('food')) {
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
    } else if (lowerType.contains('itinerary') || lowerType.contains('trip')) {
      return AppColors.primary;
    }
    return Colors.grey;
  }
}

class _InboxMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InboxMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
