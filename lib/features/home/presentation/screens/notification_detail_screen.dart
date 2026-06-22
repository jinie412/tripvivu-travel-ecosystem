import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/review_catalog_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationId;
  final NotificationEntity? initialNotification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.initialNotification,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<NotificationCubit>()..loadNotificationDetail(notificationId),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Chi tiết thông báo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final notification = state is NotificationDetailLoaded
                ? state.notification
                : initialNotification;

            if (notification == null &&
                (state is NotificationLoading ||
                    state is NotificationInitial)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notification == null && state is NotificationError) {
              return _DetailMessage(
                icon: Icons.error_outline,
                message: state.message,
              );
            }

            if (notification == null) {
              return const _DetailMessage(
                icon: Icons.notifications_none,
                message: 'Không tìm thấy thông báo.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context
                  .read<NotificationCubit>()
                  .loadNotificationDetail(notification.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.s24,
                  AppSizes.s16,
                  AppSizes.s24,
                  AppSizes.s32,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _iconColorFor(
                            notification.notificationType,
                          ).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(notification.iconKey),
                          color: _iconColorFor(notification.notificationType),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 22,
                                color: AppColorsExt.textDark,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s8),
                            Text(
                              notification.timeLabel,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s24),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.s24),
                  Text(
                    notification.content,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_canOpenReview(notification)) ...[
                    const SizedBox(height: AppSizes.s24),
                    ElevatedButton.icon(
                      onPressed: () => _hasWrittenReview(notification)
                          ? _viewReview(context, notification)
                          : _openReview(context, notification),
                      icon: Icon(
                        _hasWrittenReview(notification)
                            ? Icons.visibility_outlined
                            : Icons.rate_review_outlined,
                      ),
                      label: Text(
                        _hasWrittenReview(notification)
                            ? 'Xem đánh giá'
                            : 'Viết đánh giá',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasWrittenReview(notification)
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.primary,
                        foregroundColor: _hasWrittenReview(notification)
                            ? AppColors.primary
                            : Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          side: _hasWrittenReview(notification)
                              ? BorderSide(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                )
                              : BorderSide.none,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (state is NotificationLoading) ...[
                    const SizedBox(height: AppSizes.s24),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            );
          },
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

  bool _canOpenPlaceReview(NotificationEntity notification) {
    return notification.actionType == 'review_place' &&
        notification.itineraryId?.isNotEmpty == true &&
        notification.itineraryDetailId?.isNotEmpty == true;
  }

  bool _canOpenItineraryReview(NotificationEntity notification) {
    return notification.actionType == 'review_itinerary' &&
        notification.itineraryId?.isNotEmpty == true;
  }

  bool _canOpenReview(NotificationEntity notification) {
    return _canOpenPlaceReview(notification) ||
        _canOpenItineraryReview(notification);
  }

  bool _hasWrittenReview(NotificationEntity notification) {
    if (_canOpenItineraryReview(notification)) {
      return notification.hasItineraryReview;
    }
    return notification.hasPlaceReview;
  }

  Future<void> _viewReview(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final catalog = await sl<ReviewRepository>().getReviewCatalog();
      final isItinerary = _canOpenItineraryReview(notification);
      ReviewCatalogItem? reviewedItem;

      for (final item in catalog.reviewed) {
        if (item.itineraryId != notification.itineraryId) continue;
        if (isItinerary && item.isItinerary) {
          reviewedItem = item;
          break;
        }
        if (isItinerary || item.isItinerary) continue;

        final detailMatches = notification.itineraryDetailId != null &&
            item.itineraryDetailId == notification.itineraryDetailId;
        final placeMatches = notification.placeId != null &&
            item.placeId == notification.placeId;
        if (detailMatches || placeMatches) {
          reviewedItem = item;
          break;
        }
      }

      if (reviewedItem == null) {
        throw StateError('Không tìm thấy nội dung đánh giá đã gửi.');
      }
      if (!context.mounted) return;

      await openReviewItem(context, reviewedItem);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể tải đánh giá: $e')),
      );
    }
  }

  Future<void> _openReview(
    BuildContext context,
    NotificationEntity notification,
  ) {
    if (_canOpenItineraryReview(notification)) {
      return _openItineraryReview(context, notification);
    }
    return _openPlaceReview(context, notification);
  }

  Future<void> _openItineraryReview(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final itineraryId = notification.itineraryId;
    if (itineraryId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RateItineraryScreen(
          itineraryId: itineraryId,
          popExtraOnSubmit: false,
        ),
      ),
    );

    if (context.mounted) {
      await context.read<NotificationCubit>().loadNotificationDetail(
        notification.id,
      );
    }
  }

  Future<void> _openPlaceReview(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    final itineraryId = notification.itineraryId;
    final itineraryDetailId = notification.itineraryDetailId;
    if (itineraryId == null || itineraryDetailId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final reviewCubit = sl<ReviewCubit>();

    try {
      await reviewCubit.loadReviewData(itineraryId);
      if (!context.mounted) {
        await reviewCubit.close();
        return;
      }

      final state = reviewCubit.state;
      if (state is! ReviewLoaded ||
          !state.itinerary.locations.any(
            (item) => item.id == itineraryDetailId,
          )) {
        await reviewCubit.close();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy địa điểm cần đánh giá.'),
          ),
        );
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (_) => PlaceReviewScreen(
            locationId: itineraryDetailId,
            reviewCubit: reviewCubit,
          ),
        ),
      );
      if (context.mounted) {
        await context.read<NotificationCubit>().loadNotificationDetail(
          notification.id,
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể mở màn hình đánh giá: $e')),
      );
    } finally {
      if (!reviewCubit.isClosed) {
        await reviewCubit.close();
      }
    }
  }
}

class _DetailMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DetailMessage({required this.icon, required this.message});

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
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
