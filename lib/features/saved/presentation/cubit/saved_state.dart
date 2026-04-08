import 'package:equatable/equatable.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/saved/domain/entities/favorite_place_entity.dart';

abstract class SavedState extends Equatable {
  const SavedState();

  @override
  List<Object?> get props => [];
}

class SavedInitial extends SavedState {}

class SavedLoading extends SavedState {}

class SavedLoaded extends SavedState {
  final List<FavoriteItineraryEntity> itineraries;
  final List<FavoritePlaceEntity> places;

  const SavedLoaded({required this.itineraries, required this.places});

  @override
  List<Object?> get props => [itineraries, places];
}

class SavedError extends SavedState {
  final String message;

  const SavedError(this.message);

  @override
  List<Object?> get props => [message];
}