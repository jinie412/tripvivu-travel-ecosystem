import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

import '../../data/models/tracking_models.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import 'tracking_permissions.dart';

/// Khối UI "Theo dõi lịch trình" chèn vào màn chi tiết lịch trình.
/// Tự cung cấp [TrackingCubit] qua DI nên không cần sửa cây provider sẵn có.
class TrackingSection extends StatelessWidget {
  final String itineraryId;
  final DateTime date;
  final String itineraryStatus;
  final List<ItineraryActivityEntity> activities;

  const TrackingSection({
    super.key,
    required this.itineraryId,
    required this.date,
    required this.itineraryStatus,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrackingCubit>(
      create: (_) => sl<TrackingCubit>(),
      child: _TrackingBody(
        itineraryId: itineraryId,
        date: date,
        itineraryStatus: itineraryStatus,
        activities: activities,
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final String itineraryId;
  final DateTime date;
  final String itineraryStatus;
  final List<ItineraryActivityEntity> activities;

  const _TrackingBody({
    required this.itineraryId,
    required this.date,
    required this.itineraryStatus,
    required this.activities,
  });

  bool get _dayReached {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return !d.isAfter(today); // hôm nay hoặc đã qua
  }

  Future<void> _onStart(BuildContext context) async {
    final cubit = context.read<TrackingCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final perm = await TrackingPermissions.ensure();
    if (perm != TrackingPermResult.granted) {
      messenger.showSnackBar(SnackBar(
        content: Text(TrackingPermissions.messageFor(perm)),
        action: perm == TrackingPermResult.deniedBackground
            ? SnackBarAction(label: 'Mở Cài đặt', onPressed: openAppSettings)
            : null,
      ));
      return;
    }
    await cubit.start(itineraryId: itineraryId, date: date);
  }

  Map<String, String> get _nameByDetailId {
    final map = <String, String>{};
    for (final a in activities) {
      final name = a.locationName.isNotEmpty ? a.locationName : a.title;
      if (a.id.isNotEmpty && name.isNotEmpty) map[a.id] = name;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingCubit, TrackingState>(
      listenWhen: (p, c) => c.message != null && c.message != p.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.s12),
          padding: const EdgeInsets.all(AppSizes.s16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: state.isActive
              ? _activePanel(context, state)
              : _startPanel(context, state),
        );
      },
    );
  }

  // ───────────────────────────── panel trước khi bắt đầu
  Widget _startPanel(BuildContext context, TrackingState state) {
    final canStart = _dayReached && itineraryStatus.toUpperCase() != 'COMPLETED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.my_location, color: Color(0xFF14DFBC)),
            SizedBox(width: AppSizes.s8),
            Expanded(
              child: Text(
                'Theo dõi lịch trình',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        Text(
          canStart
              ? 'Bật theo dõi để tự động đánh dấu "Đã ghé" khi bạn đến từng địa điểm (chạy nền bằng geofence).'
              : 'Chức năng theo dõi sẽ khả dụng vào ngày diễn ra lịch trình.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: AppSizes.s12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (!canStart || state.isStarting)
                ? null
                : () => _onStart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14DFBC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r12),
              ),
            ),
            icon: state.isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(state.isStarting ? 'Đang bật...' : 'Bắt đầu'),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────── panel khi đang theo dõi
  Widget _activePanel(BuildContext context, TrackingState state) {
    final names = _nameByDetailId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_searching, color: Color(0xFF14DFBC)),
            const SizedBox(width: AppSizes.s8),
            Expanded(
              child: Text(
                'Đang theo dõi · đã ghé ${state.visitedCount}/${state.totalCount}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () => _confirmStop(context),
              child: const Text('Dừng',
                  style: TextStyle(color: Color(0xFFE53935))),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        ...state.places.map((p) => _placeRow(context, state, p, names)),
        if (state.places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.s8),
            child: Text('Chưa có điểm nào trong ngày.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ),
        const SizedBox(height: AppSizes.s8),
        Row(
          children: const [
            Icon(Icons.refresh, size: 14, color: Color(0xFF9E9E9E)),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Trạng thái cập nhật tự động khi bạn đến nơi đủ thời gian.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeRow(BuildContext context, TrackingState state,
      TrackingPlaceStatus p, Map<String, String> names) {
    final name = (p.name != null && p.name!.isNotEmpty)
        ? p.name!
        : (names[p.itineraryDetailId] ?? 'Điểm dừng');
    final color = _statusColor(p);
    final isChecking = state.checkingInDetailId == p.itineraryDetailId;
    final visited = p.status == VisitStatus.visited;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(p), size: 16, color: color),
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(p.statusLabelVi,
                    style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
          if (!visited)
            isChecking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: () => context
                        .read<TrackingCubit>()
                        .manualCheckIn(p.itineraryDetailId),
                    child: const Text('Tôi đã đến'),
                  ),
        ],
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context) async {
    final cubit = context.read<TrackingCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng theo dõi?'),
        content: const Text(
            'Geofence sẽ được gỡ và không tự đánh dấu địa điểm nữa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Dừng')),
        ],
      ),
    );
    if (ok == true) await cubit.stop();
  }

  Color _statusColor(TrackingPlaceStatus p) {
    final hex = p.mapColor;
    if (hex != null && hex.isNotEmpty) {
      final parsed = _parseHex(hex);
      if (parsed != null) return parsed;
    }
    switch (p.status) {
      case VisitStatus.visited:
        return const Color(0xFF10B981); // success
      case VisitStatus.skipped:
        return const Color(0xFFE53935); // error
      case VisitStatus.notVisited:
        return const Color(0xFF9E9E9E); // grey
    }
  }

  IconData _statusIcon(TrackingPlaceStatus p) {
    switch (p.mapIcon) {
      case 'check':
        return Icons.check_circle;
      case 'skip':
        return Icons.remove_circle_outline;
      case 'pin':
        return Icons.place_outlined;
    }
    switch (p.status) {
      case VisitStatus.visited:
        return Icons.check_circle;
      case VisitStatus.skipped:
        return Icons.remove_circle_outline;
      case VisitStatus.notVisited:
        return Icons.place_outlined;
    }
  }

  Color? _parseHex(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
