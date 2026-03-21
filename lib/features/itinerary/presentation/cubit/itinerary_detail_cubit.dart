import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/itinerary_usecases.dart';
import 'itinerary_detail_state.dart';

class ItineraryDetailCubit extends Cubit<ItineraryDetailState> {
  final GetItineraryDetailUseCase getItineraryDetail;

  ItineraryDetailCubit({required this.getItineraryDetail})
      : super(ItineraryDetailInitial());

  Future<void> loadDetail(String id) async {
    emit(ItineraryDetailLoading());
    try {
      final itinerary = await getItineraryDetail(id);
      emit(ItineraryDetailLoaded(itinerary: itinerary));
    } catch (e) {
      emit(ItineraryDetailError(e.toString()));
    }
  }

  void selectDay(int day) {
    if (state is ItineraryDetailLoaded) {
      emit((state as ItineraryDetailLoaded).copyWith(selectedDay: day));
    }
  }
}
