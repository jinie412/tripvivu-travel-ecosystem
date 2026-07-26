import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/violation_media_item.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';

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
        backgroundColor: AppColors.premiumBackground,
        appBar: AppBar(
          backgroundColor: AppColors.premiumBackground,
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
            final isResponding = state is NotificationLoading;
            final itineraryShareResponseLabel = _itineraryShareResponseLabel(
              notification,
            );

            final violatingMedia = notification.violationMedia
                .where((m) => m.categories.isNotEmpty)
                .toList();

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
                  if (violatingMedia.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s16),
                    _ViolationMediaSection(items: violatingMedia),
                  ],
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

                  if (itineraryShareResponseLabel != null) ...[
                    const SizedBox(height: AppSizes.s24),
                    _ShareResponseStatus(
                      accepted:
                          notification.actionType == 'itinerary_share_accepted',
                      label: itineraryShareResponseLabel,
                    ),
                  ] else if (_canRespondToItineraryShare(notification) &&
                      !isResponding) ...[
                    const SizedBox(height: AppSizes.s24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isResponding
                                ? null
                                : () => _respondToItineraryShare(
                                    context,
                                    notification,
                                    accept: false,
                                  ),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.s12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isResponding
                                ? null
                                : () => _respondToItineraryShare(
                                    context,
                                    notification,
                                    accept: true,
                                  ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Xác nhận'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_canOpenReview(notification)) ...[
                    const SizedBox(height: AppSizes.s24),
                    ElevatedButton.icon(
                      onPressed: _hasWrittenReview(notification)
                          ? null
                          : () => _openReview(context, notification),
                      icon: Icon(
                        _hasWrittenReview(notification)
                            ? Icons.check_circle_outline_rounded
                            : Icons.rate_review_outlined,
                      ),
                      label: Text(
                        _hasWrittenReview(notification)
                            ? 'Đã viết đánh giá'
                            : 'Viết đánh giá',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasWrittenReview(notification)
                            ? const Color(0xFFE9F7EF)
                            : AppColors.primary,
                        foregroundColor: _hasWrittenReview(notification)
                            ? const Color(0xFF14804A)
                            : Colors.white,
                        disabledBackgroundColor: const Color(0xFFE9F7EF),
                        disabledForegroundColor: const Color(0xFF14804A),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          side: _hasWrittenReview(notification)
                              ? BorderSide(
                                  color: const Color(
                                    0xFF14804A,
                                  ).withValues(alpha: 0.35),
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
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            decorationColor: Color(0xFFC0392B),
            decorationThickness: 2,
          ),
        ),
      );
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

  bool _canRespondToItineraryShare(NotificationEntity notification) {
    return notification.actionType == 'respond_itinerary_share' &&
        notification.itineraryId?.isNotEmpty == true;
  }

  String? _itineraryShareResponseLabel(NotificationEntity notification) {
    if (notification.actionType == 'itinerary_share_accepted') {
      return 'Đã chấp nhận lời mời chia sẻ lịch trình';
    }
    if (notification.actionType == 'itinerary_share_rejected') {
      return 'Đã từ chối lời mời chia sẻ lịch trình';
    }
    return null;
  }

  Future<void> _respondToItineraryShare(
    BuildContext context,
    NotificationEntity notification, {
    required bool accept,
  }) async {
    final itineraryId = notification.itineraryId;
    if (itineraryId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<NotificationCubit>().respondToItineraryShare(
        notificationId: notification.id,
        itineraryId: itineraryId,
        accept: accept,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Đã xác nhận lời mời chia sẻ lịch trình'
                : 'Đã từ chối lời mời chia sẻ lịch trình',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      var message = e.toString().replaceFirst('Exception: ', '');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          final value = data['message'];
          message = value is List ? value.join('\n') : value.toString();
        } else if (e.response?.statusCode == 409) {
          message =
              'Bạn đang tham gia một lịch trình đang diễn ra. Vui lòng dừng hoặc kết thúc lịch trình đó trước khi chấp nhận lời mời này.';
        }
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Không thể phản hồi lời mời: $message',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _hasWrittenReview(NotificationEntity notification) {
    if (_canOpenItineraryReview(notification)) {
      return notification.hasItineraryReview;
    }
    return notification.hasPlaceReview;
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

class _ViolationMediaSection extends StatelessWidget {
  final List<ViolationMediaItem> items;

  const _ViolationMediaSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh/video vi phạm',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _ViolationMediaThumb(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _ViolationMediaThumb extends StatelessWidget {
  final ViolationMediaItem item;

  const _ViolationMediaThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.mediaType == ViolationMediaType.video;

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        builder: (_) => _ViolationMediaPreviewDialog(item: item),
      ),
      child: Container(
        width: 96,
        height: 96,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(color: const Color(0xFF111827))
            else
              NetImage(url: item.url, fit: BoxFit.cover),
            if (isVideo) Container(color: Colors.black.withValues(alpha: 0.18)),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            if (item.categories.isNotEmpty)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Vi phạm: ${item.categories.first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViolationMediaPreviewDialog extends StatefulWidget {
  final ViolationMediaItem item;

  const _ViolationMediaPreviewDialog({required this.item});

  @override
  State<_ViolationMediaPreviewDialog> createState() =>
      _ViolationMediaPreviewDialogState();
}

class _ViolationMediaPreviewDialogState
    extends State<_ViolationMediaPreviewDialog> {
  VideoPlayerController? _controller;

  bool get _isVideo => widget.item.mediaType == ViolationMediaType.video;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.item.url),
      );
      _controller = controller;
      controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.play();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.item.categories;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            Center(child: _isVideo ? _buildVideo() : _buildImage()),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            if (categories.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Vi phạm: ${categories.join(', ')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: NetImage(
        url: widget.item.url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: () => setState(() {
        controller.value.isPlaying ? controller.pause() : controller.play();
      }),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _ShareResponseStatus extends StatelessWidget {
  final bool accepted;
  final String label;

  const _ShareResponseStatus({required this.accepted, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = accepted ? const Color(0xFF14804A) : const Color(0xFFB91C1C);
    final background = accepted
        ? const Color(0xFFE9F7EF)
        : const Color(0xFFFFF1F2);
    final border = accepted ? const Color(0xFFB7E4C7) : const Color(0xFFFECACA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            accepted
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
