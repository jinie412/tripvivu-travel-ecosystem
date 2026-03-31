import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/city_entities.dart';

part 'city_detail_state.freezed.dart';

@freezed
class CityDetailState with _$CityDetailState {
  const factory CityDetailState.initial() = _Initial;
  const factory CityDetailState.loading() = _Loading;
  const factory CityDetailState.loaded(CityOverview overview, int activeTab) = _Loaded;
  const factory CityDetailState.error(String message) = _Error;
}