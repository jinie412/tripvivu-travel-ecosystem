import 'package:equatable/equatable.dart';
import '../../domain/entities/place_detail_entity.dart';

abstract class PlaceDetailState extends Equatable {
  const PlaceDetailState();

  @override
  List<Object?> get props => [];
}

class PlaceDetailInitial extends PlaceDetailState {
  const PlaceDetailInitial();
}

class PlaceDetailLoading extends PlaceDetailState {
  const PlaceDetailLoading();
}

class PlaceDetailLoaded extends PlaceDetailState {
  final PlaceDetailEntity placeDetail;

  const PlaceDetailLoaded(this.placeDetail);

  @override
  List<Object?> get props => [placeDetail];
}

class PlaceDetailError extends PlaceDetailState {
  final String message;

  const PlaceDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
