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

  bool _isViolation(NotificationEntity n) {
    final t = n.notificationType.toLowerCase();
    final title = n.title.toLowerCase();
    return t == 'system' &&
        (title.contains('vi phạm') || title.contains('từ chối'));
  }

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

            final isViolation = _isViolation(notification);

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
                  // Header: title (left) + time (top-right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 19,
                            height: 1.3,
                            color: isViolation
                                ? const Color(0xFFC0392B)
                                : AppColorsExt.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
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
                  const SizedBox(height: AppSizes.s12),

                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.s12),

                  _buildContentText(notification.content, isViolation),
                  if (isViolation) ...[
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      'Nội dung này đã bị ẩn và không hiển thị với người dùng khác.',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],

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

  Widget _buildContentText(String content, bool isViolation) {
    final baseStyle = AppTextStyles.body.copyWith(
      fontSize: 16,
      height: 1.55,
      color: AppColors.textPrimary,
    );

    if (!isViolation) {
      return Text(content, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final regex = RegExp(r'"([^"]*)"');
    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          decoration: TextDecoration.lineThrough,
          decorationColor: Color(0xFFC0392B),
          decorationThickness: 2,
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
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
