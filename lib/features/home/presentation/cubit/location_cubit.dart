import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:travel_advisor_mobile/core/services/location_service.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_state.dart';

/// Quản lý việc lấy vị trí hiện tại của người dùng cho header trang chủ.
/// Sau lần lấy đầu tiên sẽ lắng nghe stream để **tự cập nhật** khi di chuyển.
class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(const LocationInitial());

  StreamSubscription<Position>? _positionSub;

  /// Toạ độ đã reverse-geocode gần nhất — để chỉ geocode lại khi đi đủ xa,
  /// tránh spam Nominatim (rate limit ~1 req/s).
  double? _lastLat;
  double? _lastLng;

  /// Khoảng cách tối thiểu (m) để geocode lại tên Phường/Xã.
  static const double _refreshDistanceM = 150;

  Future<void> fetchLocation() async {
    emit(const LocationLoading());
    try {
      final location = await _locationService.getCurrentLocation();
      _lastLat = location.latitude;
      _lastLng = location.longitude;
      emit(LocationLoaded(location));
      _listenPositionChanges();
    } on LocationFailure catch (e) {
      emit(LocationError(e.message, permissionDenied: e.permissionDenied));
    } catch (e) {
      emit(LocationError('Không lấy được vị trí. Vui lòng thử lại.'));
    }
  }

  /// Lắng nghe thay đổi vị trí và cập nhật tên khu vực khi di chuyển đủ xa.
  void _listenPositionChanges() {
    _positionSub?.cancel();
    _positionSub = _locationService.positionStream(distanceFilter: 100).listen(
      _onPositionChanged,
      onError: (_) {/* giữ vị trí cũ nếu stream lỗi */},
    );
  }

  Future<void> _onPositionChanged(Position pos) async {
    if (isClosed) return;
    // Chỉ reverse-geocode lại khi đã rời xa điểm cũ -> đỡ gọi mạng liên tục.
    if (_lastLat != null && _lastLng != null) {
      final moved = Geolocator.distanceBetween(
        _lastLat!,
        _lastLng!,
        pos.latitude,
        pos.longitude,
      );
      if (moved < _refreshDistanceM) return;
    }
    try {
      final location =
          await _locationService.reverseGeocode(pos.latitude, pos.longitude);
      if (isClosed) return;
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      emit(LocationLoaded(location));
    } catch (_) {/* lỗi geocode -> giữ tên cũ, sẽ thử lại lần di chuyển sau */}
  }

  @override
  Future<void> close() {
    _positionSub?.cancel();
    return super.close();
  }
}
