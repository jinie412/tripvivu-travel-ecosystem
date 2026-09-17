import 'package:equatable/equatable.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/user_location.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationLoaded extends LocationState {
  final UserLocation location;
  const LocationLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationError extends LocationState {
  final String message;

  /// true khi do quyền/dịch vụ vị trí — UI có thể gợi ý cấp quyền/bật GPS.
  final bool permissionDenied;

  const LocationError(this.message, {this.permissionDenied = false});

  @override
  List<Object?> get props => [message, permissionDenied];
}
