import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/itinerary_entity.dart';
import '../../domain/entities/itinerary_summary.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
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
  final GetItineraryDetailUseCase _getItineraryDetail;

  /// Filter đang active, null = "Tất cả".
  ItineraryStatus? _currentFilter;

  /// Filter con cho "Đã đi".
  CompletedFilter _currentCompletedFilter = CompletedFilter.all;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
    required GetItineraryDetailUseCase getItineraryDetail,
  })  : _getItineraries = getItineraries,
        _getSummary = getSummary,
        _deleteItinerary = deleteItinerary,
        _getItineraryDetail = getItineraryDetail,
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

      var itineraries = results[0] as List<ItineraryEntity>;
      
      // Lọc thêm theo Rating nếu đang ở tab "Đã đi"
      if (_currentFilter == ItineraryStatus.completed) {
        if (_currentCompletedFilter == CompletedFilter.rated) {
          itineraries = itineraries.where((i) => i.rating != null).toList();
        } else if (_currentCompletedFilter == CompletedFilter.unrated) {
          itineraries = itineraries.where((i) => i.rating == null).toList();
        }
      }

      emit(ItineraryLoaded(
        itineraries: itineraries,
        summary: results[1] as dynamic,
        activeFilter: _currentFilter,
        activeCompletedFilter: _currentCompletedFilter,
        selectedItinerary: (state is ItineraryLoaded) ? (state as ItineraryLoaded).selectedItinerary : null,
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
    // Reset filter con khi đổi tab chính
    _currentCompletedFilter = CompletedFilter.all;
    await loadData();
  }

  /// Lọc con cho "Đã đi" (Tất cả / Đã đánh giá / Chưa đánh giá).
  Future<void> filterByCompleted(CompletedFilter filter) async {
    _currentCompletedFilter = filter;
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

  /// Chọn một lịch trình để xem chi tiết.
  /// Cubit sẽ fetch data detail và lưu vào [selectedItinerary].
  Future<void> selectItinerary(String id) async {
    final currentState = state;
    if (currentState is ItineraryLoaded) {
      // Clear previous selection to show loading
      emit(currentState.copyWithSelected(null));
      
      try {
        final detail = await _getItineraryDetail(id);
        emit((state as ItineraryLoaded).copyWithSelected(detail));
      } catch (e) {
        emit(ItineraryError('Không thể tải chi tiết: ${e.toString()}'));
      }
    } else {
      // Nếu chưa load danh sách (ví dụ đi từ màn hình Saved)
      emit(const ItineraryLoading());
      try {
        // Tải cả summary và detail để có đủ data cho trạng thái Loaded
        final results = await Future.wait([
          _getSummary(),
          _getItineraryDetail(id),
          _getItineraries(),
        ]);
        
        emit(ItineraryLoaded(
          itineraries: results[2] as List<ItineraryEntity>,
          summary: results[0] as ItinerarySummary,
          selectedItinerary: results[1] as ItineraryDetailEntity,
        ));
      } catch (e) {
        emit(ItineraryError('Không thể tải dữ liệu: ${e.toString()}'));
      }
    }
  }

  void toggleItineraryStatus(String id, bool isOngoing) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final updatedList = currentState.itineraries.map((itinerary) {
        if (itinerary.id == id) {
          return itinerary.copyWith(
            status: isOngoing ? ItineraryStatus.ongoing : ItineraryStatus.upcoming,
          );
        }
        return itinerary;
      }).toList();

      emit(ItineraryLoaded(
        itineraries: updatedList,
        summary: currentState.summary,
        activeFilter: currentState.activeFilter,
        activeCompletedFilter: currentState.activeCompletedFilter,
        selectedItinerary: currentState.selectedItinerary,
      ));
    }
  }
}

extension on ItineraryLoaded {
  ItineraryLoaded copyWithSelected(dynamic selected) {
    return ItineraryLoaded(
      itineraries: itineraries,
      summary: summary,
      activeFilter: activeFilter,
      activeCompletedFilter: activeCompletedFilter,
      selectedItinerary: selected,
    );
  }
}
