import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

import '../../data/datasources/tracking_remote_datasource.dart';
import '../../data/models/tracking_models.dart';
import '../../domain/usecases/tracking_usecases.dart';
import '../../services/geofence_tracking_service.dart';
import '../../services/tracking_alarm_service.dart';
import '../../services/tracking_context.dart';
import '../../tracking_config.dart';
import 'tracking_state.dart';

/// Thông tin tối giản về quán ăn, dùng để lưu/khôi phục qua SharedPreferences.
class _FoodSpot {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const _FoodSpot({required this.id, required this.name, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'i': id, 'n': name, 'a': lat, 'o': lng};

  factory _FoodSpot.fromJson(Map<String, dynamic> j) => _FoodSpot(
        id: j['i'] as String? ?? '',
        name: j['n'] as String? ?? '',
        lat: (j['a'] as num).toDouble(),
        lng: (j['o'] as num).toDouble(),
      );
}

/// Điều phối luồng theo dõi lịch trình ở main isolate:
/// `/start` → đăng ký geofence → đặt AlarmManager 23h → tải trạng thái bản đồ.
class TrackingCubit extends Cubit<TrackingState> with WidgetsBindingObserver {
  final StartTrackingUseCase _start;
  final GetTrackingStatusUseCase _status;
  final SendTrackingEventUseCase _sendEvent;
  final ManualCheckInUseCase _checkIn;
  final EndTrackingDayUseCase _endDay;
  final GeofenceTrackingService _geofenceSvc;
  final TrackingAlarmService _alarmSvc;

  static double get _foodProximityKm => TrackingConfig.foodProximityKm;

  // Category keywords nhận diện địa điểm ăn uống
  static const _foodKeywords = [
    'nhà hàng', 'restaurant', 'cafe', 'cà phê', 'ăn uống',
    'quán ăn', 'buffet', 'fastfood', 'fast food', 'food', 'ẩm thực',
  ];

  static bool _isFoodCategory(String? category) {
    if (category == null || category.isEmpty) return false;
    final lower = category.toLowerCase();
    return _foodKeywords.any((k) => lower.contains(k));
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  TrackingCubit({
    required StartTrackingUseCase start,
    required GetTrackingStatusUseCase status,
    required SendTrackingEventUseCase sendEvent,
    required ManualCheckInUseCase checkIn,
    required EndTrackingDayUseCase endDay,
    required GeofenceTrackingService geofenceSvc,
    required TrackingAlarmService alarmSvc,
  })  : _start = start,
        _status = status,
        _sendEvent = sendEvent,
        _checkIn = checkIn,
        _endDay = endDay,
        _geofenceSvc = geofenceSvc,
        _alarmSvc = alarmSvc,
        super(const TrackingState()) {
    WidgetsBinding.instance.addObserver(this);
    _listenConnectivity();
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _wasOffline && state.isActive) {
        refreshStatus();
        // Có mạng trở lại -> gửi ngay sự kiện geofence còn tồn đọng.
        _evaluateGeofences();
      }
      _wasOffline = !isOnline;
    });
  }

  String _touristId = '';
  Timer? _refreshTimer;
  Timer? _geofenceTimer;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  List<_FoodSpot> _foodSpots = [];
  bool _wasOffline = false;
  final _connectivity = Connectivity();

  // ── Phát hiện geofence chủ động ở foreground (nhanh hơn native passive) ──────
  /// Geofence của ngày (lat/lng/bán kính/ngưỡng dwell) để tự tính khoảng cách.
  List<TrackingGeofence> _geofences = [];
  Position? _lastPosition;
  final Set<String> _insideIds = {}; // đang ở trong vùng
  final Map<String, DateTime> _enteredAt = {}; // mốc vào vùng -> tính dwell
  final Set<String> _dwellSentIds = {}; // đã gửi DWELL thành công (chống lặp)
  final Set<String> _visitedIds = {}; // đã "Đã ghé" -> bỏ qua, không gửi lại

  /// true = stream đang chạy GPS độ chính xác cao (khi tới gần điểm).
  bool _highAccuracyMode = false;

  /// Trong bán kính này (m) tới điểm gần nhất thì bật GPS chính xác cao.
  /// Xa hơn -> dùng medium để tiết kiệm pin lúc đang di chuyển/đứng xa.
  static const double _highAccuracyRangeM = 500;

  /// Ngưỡng dwell foreground (giây): nhỏ để phản hồi nhanh, vẫn >= backend.
  static int _foregroundDwell(int threshold) => threshold.clamp(15, 120);

  /// Xoá trạng thái phát hiện geofence (khi bắt đầu/khôi phục/dừng).
  void _resetDetectionState() {
    _geofences = [];
    _lastPosition = null;
    _highAccuracyMode = false;
    _insideIds.clear();
    _enteredAt.clear();
    _dwellSentIds.clear();
    _visitedIds.clear();
  }

  // Stale detection được xử lý trong cubit, không phải từ widget lifecycle.

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _geofenceTimer?.cancel();
    _locationSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }

  /// Refresh ngay khi app trở về foreground (sau geofence trigger nền).
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && state.isActive) {
      refreshStatus();
      _evaluateGeofences(); // đánh giá lại ngay khi mở app
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refreshStatus());
  }

  void _startFoodProximityWatch(List<ItineraryActivityEntity> activities) {
    _foodSpots = activities
        .where((a) => _isFoodCategory(a.category) && a.latitude != null && a.longitude != null)
        .map((a) => _FoodSpot(
              id: a.id,
              name: a.locationName.isNotEmpty ? a.locationName : a.title,
              lat: a.latitude!,
              lng: a.longitude!,
            ))
        .toList();
    _persistFoodSpots();
    _subscribeLocationStream();
  }

  Future<void> _persistFoodSpots() async {
    if (_foodSpots.isEmpty) {
      await TrackingContextStore.clearFoodSpots();
    } else {
      await TrackingContextStore.saveFoodSpots(
        jsonEncode(_foodSpots.map((s) => s.toJson()).toList()),
      );
    }
  }

  Future<void> _restoreFoodProximityWatch() async {
    final raw = await TrackingContextStore.loadFoodSpots();
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _foodSpots = list
          .map((j) => _FoodSpot.fromJson(Map<String, dynamic>.from(j as Map)))
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (_) {
      _foodSpots = [];
    }
    _subscribeLocationStream();
  }

  void _subscribeLocationStream({bool highAccuracy = false}) {
    _locationSub?.cancel();
    // Luôn cần stream khi đang theo dõi: phục vụ cả phát hiện geofence chủ động
    // (không phụ thuộc native passive) lẫn gợi ý quán ăn gần đây.
    if (!state.isActive) return;
    _highAccuracyMode = highAccuracy;
    try {
      _locationSub = Geolocator.getPositionStream(
        // Gần điểm -> high + filter 10m (bắt ENTER/DWELL chính xác).
        // Xa điểm  -> medium + filter 100m (nhẹ pin lúc di chuyển/đứng xa).
        locationSettings: LocationSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: highAccuracy ? 10 : 100,
        ),
      ).listen(_onPosition, onError: (_) {});
    } catch (_) {}
  }

  /// Xử lý mỗi cập nhật vị trí: lưu lại + chạy phát hiện geofence + quán ăn +
  /// điều chỉnh độ chính xác GPS theo khoảng cách tới điểm gần nhất.
  void _onPosition(Position pos) {
    if (isClosed) return;
    _lastPosition = pos;
    _evaluateGeofences();
    _checkFoodProximity(pos);
    _maybeSwitchAccuracy(pos);
  }

  /// Bật GPS chính xác cao khi tới gần điểm chưa ghé (<= [_highAccuracyRangeM]),
  /// hạ về medium khi đã đi xa -> tiết kiệm pin mà vẫn nhạy lúc cần.
  void _maybeSwitchAccuracy(Position pos) {
    if (_geofences.isEmpty) return;
    double? nearest;
    for (final g in _geofences) {
      if (_visitedIds.contains(g.itineraryDetailId)) continue;
      final m =
          _haversineKm(pos.latitude, pos.longitude, g.latitude, g.longitude) *
              1000;
      if (nearest == null || m < nearest) nearest = m;
    }
    if (nearest == null) return; // tất cả đã ghé
    final shouldHigh = nearest <= _highAccuracyRangeM;
    if (shouldHigh != _highAccuracyMode) {
      _subscribeLocationStream(highAccuracy: shouldHigh);
    }
  }

  /// Timer 5s chỉ chạy khi đang ở trong ít nhất một vùng (để DWELL fire dù
  /// đứng yên). Ngoài vùng -> tắt, nhường cho stream -> đỡ tốn pin/CPU.
  void _ensureDwellTimer() {
    _geofenceTimer ??=
        Timer.periodic(const Duration(seconds: 5), (_) => _evaluateGeofences());
  }

  void _stopDwellTimerIfIdle() {
    if (_insideIds.isEmpty) {
      _geofenceTimer?.cancel();
      _geofenceTimer = null;
    }
  }

  void _checkFoodProximity(Position pos) {
    if (isClosed || _foodSpots.isEmpty) return;
    for (final s in _foodSpots) {
      final km = _haversineKm(pos.latitude, pos.longitude, s.lat, s.lng);
      if (km <= _foodProximityKm) {
        if (state.nearbyRestaurantDetailId != s.id) {
          emit(state.copyWith(
            nearbyRestaurantDetailId: s.id,
            nearbyRestaurantName: s.name,
          ));
        }
        return;
      }
    }
    if (state.nearbyRestaurantDetailId != null) {
      emit(state.copyWith(clearNearbyRestaurant: true));
    }
  }

  /// Phát hiện geofence **chủ động** ở foreground: tính khoảng cách tới từng
  /// điểm dừng và tự gửi ENTER/DWELL/EXIT — phản hồi trong vài giây thay vì chờ
  /// native geofence (passive, có thể trễ vài phút).
  void _evaluateGeofences() {
    if (isClosed || !state.isActive) return;
    final pos = _lastPosition;
    if (pos == null || _geofences.isEmpty) return;
    final now = DateTime.now();

    for (final g in _geofences) {
      final id = g.itineraryDetailId;
      if (id.isEmpty || _visitedIds.contains(id)) continue;

      final meters =
          _haversineKm(pos.latitude, pos.longitude, g.latitude, g.longitude) *
              1000;
      final inside = meters <= g.radiusM;

      if (inside) {
        if (!_insideIds.contains(id)) {
          _insideIds.add(id);
          _enteredAt[id] = now;
          _ensureDwellTimer(); // vào vùng -> bật timer chờ dwell
          _sendGeofenceEvent(id, 'ENTER');
        } else if (!_dwellSentIds.contains(id)) {
          final entered = _enteredAt[id] ?? now;
          final elapsed = now.difference(entered).inSeconds;
          if (elapsed >= _foregroundDwell(g.dwellThresholdSeconds)) {
            _dwellSentIds.add(id);
            _sendGeofenceEvent(
              id,
              'DWELL',
              dwellSeconds: g.dwellThresholdSeconds,
              placeName: g.name,
            ).then((ok) {
              // Gửi lỗi (mất mạng) -> bỏ cờ để lần poll sau thử lại.
              if (!ok) _dwellSentIds.remove(id);
            });
          }
        }
      } else if (_insideIds.remove(id)) {
        _enteredAt.remove(id);
        _dwellSentIds.remove(id);
        _sendGeofenceEvent(id, 'EXIT');
      }
    }
    _stopDwellTimerIfIdle(); // ra khỏi mọi vùng -> tắt timer cho nhẹ pin
  }

  /// Gửi một sự kiện geofence lên backend. Trả về true nếu thành công.
  /// Khi DWELL được xác nhận "Đã ghé": cập nhật bản đồ + bắn thông báo cục bộ.
  Future<bool> _sendGeofenceEvent(
    String detailId,
    String eventType, {
    int? dwellSeconds,
    String? placeName,
  }) async {
    if (_touristId.isEmpty) _touristId = await _resolveTouristId();
    if (_touristId.isEmpty) return false;
    try {
      final res = await _sendEvent(
        itineraryDetailId: detailId,
        touristId: _touristId,
        eventType: eventType,
        occurredAt: DateTime.now(),
        dwellSeconds: dwellSeconds,
      );
      if (eventType == 'DWELL' && res.status == VisitStatus.visited) {
        _visitedIds.add(detailId);
        await refreshStatus();
        await _showArrivalNotification(
          detailId: detailId,
          placeName: res.name ?? placeName ?? 'địa điểm',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Thông báo cục bộ "Đã đến nơi" (song song với native callback nền).
  Future<void> _showArrivalNotification({
    required String detailId,
    required String placeName,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await plugin.initialize(settings: initSettings);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'itinerary_tracking_channel',
          'Theo dõi lịch trình',
          channelDescription:
              'Thông báo khi bạn đến một địa điểm trong lịch trình',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await plugin.show(
        id: detailId.hashCode & 0x7fffffff,
        title: 'Đã đến nơi 🎉',
        body: 'Bạn đã đến $placeName',
        notificationDetails: details,
        payload: 'tracking:$detailId',
      );
    } catch (_) {}
  }

  /// Dựng lại danh sách geofence để phát hiện chủ động từ trạng thái bản đồ
  /// (dùng khi khôi phục sau khi app khởi động lại — context chỉ lưu tên/dwell).
  Future<void> _rebuildGeofencesFromStatus(TrackingStatusResult status) async {
    final ctx = await TrackingContextStore.load();
    final radius = ctx?.radiusM ?? TrackingConfig.radiusM;
    final list = <TrackingGeofence>[];
    for (final p in status.places) {
      if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
        _visitedIds.add(p.itineraryDetailId);
        continue;
      }
      if (p.latitude == null || p.longitude == null) continue;
      list.add(TrackingGeofence(
        itineraryDetailId: p.itineraryDetailId,
        latitude: p.latitude!,
        longitude: p.longitude!,
        name: p.name,
        radiusM: radius,
        dwellThresholdSeconds:
            ctx?.metaFor(p.itineraryDetailId)?.dwellSeconds ??
                TrackingConfig.dwellSeconds,
      ));
    }
    _geofences = list;
  }

  /// Cập nhật danh sách activities khi màn hình chi tiết mở (hoặc đổi ngày).
  /// Dùng để khởi động food proximity watch khi start từ màn hình danh sách.
  void updateActivities(List<ItineraryActivityEntity> activities) {
    if (!state.isActive) return;
    _startFoodProximityWatch(activities);
  }

  /// Ẩn popup gợi ý đặt món (người dùng đã đóng).
  void dismissNearbyRestaurant() {
    emit(state.copyWith(clearNearbyRestaurant: true));
  }

  Future<String> _resolveTouristId() async {
    final fromAuth = await AuthUtils.getCurrentUserId();
    return (fromAuth != null && fromAuth.isNotEmpty)
        ? fromAuth
        : (dotenv.env['EXPLORE_TOURIST_ID']?.trim() ?? '');
  }

  /// Khôi phục trạng thái theo dõi khi app khởi động lại.
  /// Đọc TrackingContext từ SharedPreferences (đã lưu lúc start hoặc qua đêm sang ngày mới).
  Future<void> restoreIfActive() async {
    if (state.isActive) return;

    final ctx = await TrackingContextStore.load();
    if (ctx == null || ctx.itineraryId.isEmpty || ctx.date.isEmpty) return;

    DateTime? date;
    try {
      final p = ctx.date.split('-');
      if (p.length == 3) date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {}
    if (date == null) return;

    _touristId = ctx.touristId;
    _resetDetectionState();

    emit(state.copyWith(
      phase: TrackingPhase.active,
      itineraryId: ctx.itineraryId,
      date: date,
    ));

    // Dựng lại geofence từ trạng thái bản đồ để phát hiện chủ động hoạt động
    // ngay sau khi app khởi động lại.
    try {
      final status = await _status(itineraryId: ctx.itineraryId, date: date);
      emit(state.copyWith(places: status.places));
      await _rebuildGeofencesFromStatus(status);
    } catch (_) {}

    _startRefreshTimer();
    await _restoreFoodProximityWatch();
    // Đảm bảo stream vị trí chạy cho phát hiện geofence dù không có quán ăn.
    _subscribeLocationStream();
  }

  /// Bắt đầu theo dõi cho [date] của [itineraryId].
  /// [activities] dùng để phát hiện quán ăn gần vị trí hiện tại.
  Future<void> start({
    required String itineraryId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
    List<ItineraryActivityEntity> activities = const [],
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

      // Xóa geofence cũ (từ session trước, cùng địa điểm → ghi nhận trùng).
      await _geofenceSvc.removeAll();

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

      if (registered == 0) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Không đăng ký được geofence. '
              'Kiểm tra quyền vị trí "Luôn cho phép" (Always Allow) '
              'trong Cài đặt → Ứng dụng → Quyền → Vị trí.',
        ));
        return;
      }

      emit(state.copyWith(
        phase: TrackingPhase.active,
        registeredCount: registered,
        places: status.places,
      ));

      // Nạp geofence cho phát hiện chủ động foreground (lat/lng/dwell đầy đủ).
      _resetDetectionState();
      _geofences = geofences;
      for (final p in status.places) {
        if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
          _visitedIds.add(p.itineraryDetailId);
        }
      }

      // Refresh status mỗi 60 giây
      _startRefreshTimer();
      // Theo dõi vị trí: phát hiện geofence chủ động + quán ăn gần đây.
      _startFoodProximityWatch(activities);
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
      // Đồng bộ điểm đã ghé (qua native callback / check-in) để không gửi lại.
      for (final p in status.places) {
        if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
          _visitedIds.add(p.itineraryDetailId);
        }
      }
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

  /// Được gọi từ UI khi DB xác nhận [dbActive] cho itinerary [itineraryId].
  /// Nếu cubit đang active cho cùng ID nhưng DB nói không active → cache stale → xóa.
  Future<void> notifyDbState(String itineraryId, bool dbActive) async {
    if (state.itineraryId != itineraryId) return;
    if (!state.isActive) return;
    if (!dbActive) await clearStaleCache();
  }

  /// Xóa cache stale khi DB xác nhận tracking không còn active (không gọi backend).
  /// Quan trọng: gỡ geofences khỏi Android OS để tránh callback giả khi user
  /// đi qua khu vực đã từng theo dõi.
  Future<void> clearStaleCache() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _foodSpots = [];
    _resetDetectionState();
    await _geofenceSvc.removeAll();
    await _alarmSvc.cancelAll();
    await TrackingContextStore.clear();
    await TrackingContextStore.clearFoodSpots();
    emit(const TrackingState());
  }

  /// Dừng theo dõi: gỡ toàn bộ geofence + alarm + ngữ cảnh.
  Future<void> stop() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _foodSpots = [];
    _resetDetectionState();
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
    await TrackingContextStore.clearFoodSpots();
    emit(const TrackingState());
  }
}
