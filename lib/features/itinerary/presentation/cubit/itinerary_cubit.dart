import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/itinerary_entity.dart';
import '../../domain/usecases/itinerary_usecases.dart';
import 'itinerary_state.dart';

/// Cubit quản lý trạng thái màn hình "Lịch trình của tôi".
///
/// Luồng:
///   1. [loadData]   → emit Loading → gọi UseCases → emit Loaded / Error
///   2. [filterBy]   → emit Loading → gọi lại với status filter → emit Loaded
///   3. [deleteItem] → xóa → tải lại danh sách
class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;

  /// Filter đang active, null = "Tất cả".
  ItineraryStatus? _currentFilter;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
  })  : _getItineraries = getItineraries,
        _getSummary = getSummary,
        _deleteItinerary = deleteItinerary,
        super(const ItineraryInitial());

  /// Tải toàn bộ dữ liệu (danh sách + thống kê).
  ///
  /// Gọi khi màn hình mở lần đầu hoặc khi bấm Retry.
  Future<void> loadData() async {
    emit(const ItineraryLoading());
    try {
      // Gọi song song để giảm thời gian chờ.
      final results = await Future.wait([
        _getItineraries(status: _currentFilter),
        _getSummary(),
      ]);
      emit(ItineraryLoaded(
        itineraries: results[0] as List<ItineraryEntity>,
        summary: results[1] as dynamic,
        activeFilter: _currentFilter,
      ));
    } catch (e) {
      emit(ItineraryError(e.toString()));
    }
  }

  /// Lọc theo trạng thái. Truyền `null` để hiển thị "Tất cả".
  ///
  /// Gọi khi người dùng bấm chip filter (Tất cả / Sắp đi / Đã đi / Nháp).
  Future<void> filterBy(ItineraryStatus? status) async {
    _currentFilter = status;
    await loadData();
  }

  /// Xóa một lịch trình và tải lại danh sách.
  ///
  /// Gọi khi người dùng vuốt trái card và bấm "Xóa".
  Future<void> deleteItem(String id) async {
    try {
      await _deleteItinerary(id);
      // Tải lại sau khi xóa để cập nhật cả danh sách lẫn thống kê.
      await loadData();
    } catch (e) {
      emit(ItineraryError('Không thể xóa lịch trình: ${e.toString()}'));
    }
  }
}
