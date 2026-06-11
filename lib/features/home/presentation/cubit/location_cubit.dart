import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/services/location_service.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_state.dart';

/// Quản lý việc lấy vị trí hiện tại của người dùng cho header trang chủ.
class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(const LocationInitial());

  Future<void> fetchLocation() async {
    emit(const LocationLoading());
    try {
      final location = await _locationService.getCurrentLocation();
      emit(LocationLoaded(location));
    } on LocationFailure catch (e) {
      emit(LocationError(e.message, permissionDenied: e.permissionDenied));
    } catch (e) {
      emit(LocationError('Không lấy được vị trí. Vui lòng thử lại.'));
    }
  }
}