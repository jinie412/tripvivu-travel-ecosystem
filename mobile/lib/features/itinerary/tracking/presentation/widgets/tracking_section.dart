import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import 'tracking_permissions.dart';

/// Khối "Theo dõi lịch trình" nhúng vào màn chi tiết.
///
/// Khi tracking KHÔNG active: hiện nút "Bắt đầu theo dõi" (nếu showStartButton=true).
/// Khi tracking ACTIVE: không render UI (tiến độ ngày hiển thị ở card
/// "Tiến độ tham quan" trong màn chi tiết) — widget vẫn cần nằm trong tree để
/// đồng bộ activities cho food-proximity, dọn phiên stale theo dbTrackingActive
/// và hiện snackbar message từ TrackingCubit.
class TrackingSection extends StatefulWidget {
  final String itineraryId;
  final DateTime date;
  final String itineraryStatus;
  final List<ItineraryActivityEntity> activities;
  final bool showStartButton;
  final bool dbTrackingActive;

  /// Callback sau khi bắt đầu tracking thành công (dùng để cập nhật ItineraryCubit).
  final VoidCallback? onStarted;

  const TrackingSection({
    super.key,
    required this.itineraryId,
    required this.date,
    required this.itineraryStatus,
    required this.activities,
    this.showStartButton = true,
    this.dbTrackingActive = false,
    this.onStarted,
  });

  @override
  State<TrackingSection> createState() => _TrackingSectionState();
}

class _TrackingSectionState extends State<TrackingSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncActivities());
  }

  @override
  void didUpdateWidget(TrackingSection old) {
    super.didUpdateWidget(old);
    if (old.activities != widget.activities) {
      _syncActivities();
    }
    // DB vừa xác nhận tracking không còn active (refresh chi tiết, kết thúc
    // ngày, dừng từ màn khác...) → dọn phiên tracking stale trong cubit để
    // thanh "Đang theo dõi" không hiển thị sai.
    if (old.dbTrackingActive != widget.dbTrackingActive &&
        !widget.dbTrackingActive) {
      context.read<TrackingCubit>().notifyDbState(widget.itineraryId, false);
    }
  }

  void _syncActivities() {
    if (!mounted) return;
    context.read<TrackingCubit>().updateActivities(widget.activities);
  }

  @override
  Widget build(BuildContext context) {
    return _TrackingBody(
      itineraryId: widget.itineraryId,
      date: widget.date,
      itineraryStatus: widget.itineraryStatus,
      activities: widget.activities,
      showStartButton: widget.showStartButton,
      onStarted: widget.onStarted,
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final String itineraryId;
  final DateTime date;
  final String itineraryStatus;
  final List<ItineraryActivityEntity> activities;
  final bool showStartButton;
  final VoidCallback? onStarted;

  const _TrackingBody({
    required this.itineraryId,
    required this.date,
    required this.itineraryStatus,
    required this.activities,
    required this.showStartButton,
    this.onStarted,
  });

  // TODO(date-restriction): Bật lại khi muốn giới hạn chỉ bắt đầu vào ngày lịch trình.
  // bool get _dayReached {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final d = DateTime(date.year, date.month, date.day);
  //   return !d.isAfter(today);
  // }

  Future<void> _onStart(BuildContext context) async {
    final cubit = context.read<TrackingCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final perm = await TrackingPermissions.ensure();
    if (perm != TrackingPermResult.granted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(TrackingPermissions.messageFor(perm)),
          action: perm == TrackingPermResult.deniedBackground
              ? SnackBarAction(label: 'Mở Cài đặt', onPressed: openAppSettings)
              : null,
        ),
      );
      return;
    }
    await cubit.start(
      itineraryId: itineraryId,
      date: date,
      activities: activities,
    );
    if (context.mounted && cubit.state.isActive) {
      onStarted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingCubit, TrackingState>(
      listenWhen: (p, c) => c.message != null && c.message != p.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (!showStartButton) return const SizedBox.shrink();
        final isThisTrip = state.itineraryId == itineraryId;
        final isTrackedDay =
            state.date != null &&
            state.date!.year == date.year &&
            state.date!.month == date.month &&
            state.date!.day == date.day;
        // Đang theo dõi lịch trình/ngày này → không cần nút bắt đầu.
        if (state.isActive && isThisTrip && isTrackedDay) {
          return const SizedBox.shrink();
        }
        return _startButton(context, state);
      },
    );
  }

  // ── Nút bắt đầu ─────────────────────────────────────────────────────────────
  Widget _startButton(BuildContext context, TrackingState state) {
    final isCompleted = itineraryStatus.toUpperCase() == 'COMPLETED';
    // TODO(date-restriction): thay canStart = _dayReached && !isCompleted
    final canStart = !isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.s12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (!canStart || state.isStarting)
              ? null
              : () => _onStart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14DFBC),
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            elevation: 0,
          ),
          icon: state.isStarting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(
            state.isStarting
                ? 'Đang bật...'
                : isCompleted
                ? 'Lịch trình đã hoàn thành'
                : 'Bắt đầu theo dõi lịch trình',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
