import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';

import '../../data/datasources/tracking_remote_datasource.dart';
import '../../domain/usecases/tracking_usecases.dart';
import '../../services/geofence_tracking_service.dart';
import '../../services/tracking_alarm_service.dart';
import '../../services/tracking_context.dart';
import 'tracking_state.dart';

/// Điều phối luồng theo dõi lịch trình ở main isolate:
/// `/start` → đăng ký geofence → đặt AlarmManager 23h → tải trạng thái bản đồ.
class TrackingCubit extends Cubit<TrackingState> {
  final StartTrackingUseCase _start;
  final GetTrackingStatusUseCase _status;
  final ManualCheckInUseCase _checkIn;
  final EndTrackingDayUseCase _endDay;
  final GeofenceTrackingService _geofenceSvc;
  final TrackingAlarmService _alarmSvc;

  TrackingCubit({
    required StartTrackingUseCase start,
    required GetTrackingStatusUseCase status,
    required ManualCheckInUseCase checkIn,
    required EndTrackingDayUseCase endDay,
    required GeofenceTrackingService geofenceSvc,
    required TrackingAlarmService alarmSvc,
  })  : _start = start,
        _status = status,
        _checkIn = checkIn,
        _endDay = endDay,
        _geofenceSvc = geofenceSvc,
        _alarmSvc = alarmSvc,
        super(const TrackingState());

  String _touristId = '';

  Future<String> _resolveTouristId() async {
    final fromAuth = await AuthUtils.getCurrentUserId();
    return (fromAuth != null && fromAuth.isNotEmpty)
        ? fromAuth
        : (dotenv.env['EXPLORE_TOURIST_ID']?.trim() ?? '');
  }

  /// Bắt đầu theo dõi cho [date] của [itineraryId].
  Future<void> start({
    required String itineraryId,
    required DateTime date,
    int radiusM = 100,
  }) async {
    emit(state.copyWith(
      phase: TrackingPhase.starting,
      itineraryId: itineraryId,
      date: date,
      clearMessage: true,
    ));
    try {
      _touristId = await _resolveTouristId();
      if (_touristId.isEmpty) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Không xác định được tài khoản. Vui lòng đăng nhập lại.',
        ));
        return;
      }

      final result = await _start(
        itineraryId: itineraryId,
        touristId: _touristId,
        date: date,
        radiusM: radiusM,
      );
      final geofences = result.geofences.where((g) => g.hasValidLocation).toList();
      if (geofences.isEmpty) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Ngày này chưa có địa điểm để theo dõi.',
        ));
        return;
      }

      // Lưu ngữ cảnh cho background isolate.
      await TrackingContextStore.save(TrackingContextStore.build(
        baseUrl: ApiConfig.baseUrl,
        touristId: _touristId,
        itineraryId: itineraryId,
        date: TrackingRemoteDataSource.fmtDate(date),
        radiusM: radiusM,
        geofences: geofences,
      ));

      // Đăng ký geofence (hết hạn cuối ngày).
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
      final ttl = endOfDay.difference(DateTime.now());
      final registered = await _geofenceSvc.registerAll(
        geofences,
        expiration: ttl.isNegative ? null : ttl,
      );

      // Đặt alarm kết thúc ngày (23:00) để remove geofence + mark skipped.
      final dayEndAt = DateTime(date.year, date.month, date.day, 23, 0);
      if (dayEndAt.isAfter(DateTime.now())) {
        await _alarmSvc.scheduleEndOfDay(dayEndAt);
      }

      // Lấy trạng thái bản đồ ban đầu.
      final status = await _status(itineraryId: itineraryId, date: date);

      emit(state.copyWith(
        phase: TrackingPhase.active,
        registeredCount: registered,
        places: status.places,
      ));
    } catch (e) {
      emit(state.copyWith(
        phase: TrackingPhase.error,
        message: 'Không bắt đầu được theo dõi: $e',
      ));
    }
  }

  /// Tải lại trạng thái màu/icon (gọi khi quay lại app hoặc sau check-in).
  Future<void> refreshStatus() async {
    final id = state.itineraryId;
    final d = state.date;
    if (id == null || d == null) return;
    try {
      final status = await _status(itineraryId: id, date: d);
      emit(state.copyWith(places: status.places));
    } catch (_) {/* giữ trạng thái cũ */}
  }

  /// Check-in thủ công "Tôi đã đến đây".
  Future<void> manualCheckIn(String itineraryDetailId) async {
    if (_touristId.isEmpty) _touristId = await _resolveTouristId();
    emit(state.copyWith(checkingInDetailId: itineraryDetailId));
    try {
      await _checkIn(
        itineraryDetailId: itineraryDetailId,
        touristId: _touristId,
      );
      await refreshStatus();
      emit(state.copyWith(clearCheckingIn: true, message: 'Đã check-in'));
    } catch (e) {
      emit(state.copyWith(
        clearCheckingIn: true,
        message: 'Check-in thất bại: $e',
      ));
    }
  }

  /// Dừng theo dõi: gỡ toàn bộ geofence + alarm + ngữ cảnh.
  Future<void> stop() async {
    try {
      final id = state.itineraryId;
      final d = state.date;
      if (id != null && d != null) {
        await _endDay(itineraryId: id, date: d, markPendingAsSkipped: false);
      }
    } catch (_) {}
    await _geofenceSvc.removeAll();
    await _alarmSvc.cancelAll();
    await TrackingContextStore.clear();
    await TrackingContextStore.clearNextDate();
    emit(const TrackingState());
  }
}
