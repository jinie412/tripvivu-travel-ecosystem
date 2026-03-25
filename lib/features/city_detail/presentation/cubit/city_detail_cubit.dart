import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_city_overview_usecase.dart';
import 'city_detail_state.dart';

class CityDetailCubit extends Cubit<CityDetailState> {
  final GetCityOverviewUseCase _getCityOverview;

  CityDetailCubit(this._getCityOverview) : super(const CityDetailState.initial());

  Future<void> loadCityDetail(String cityId) async {
    emit(const CityDetailState.loading());
    try {
      final overview = await _getCityOverview(cityId);
      emit(CityDetailState.loaded(overview, 0)); // Default tab 0: Tổng quan
    } catch (e) {
      emit(CityDetailState.error(e.toString()));
    }
  }

  void changeTab(int index) {
    state.mapOrNull(
      loaded: (s) => emit(s.copyWith(activeTab: index)),
    );
  }
}
