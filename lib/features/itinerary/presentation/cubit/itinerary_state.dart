import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';

/// Trạng thái của màn hình "Lịch trình của tôi".
///
/// 4 trạng thái đảm bảo UI luôn biết chính xác hiển thị gì:
/// - [ItineraryInitial]  → Chưa gọi API, hiện placeholder.
/// - [ItineraryLoading]  → Đang tải, hiện Shimmer skeleton.
/// - [ItineraryLoaded]   → Có data, hiện danh sách + thống kê.
/// - [ItineraryError]    → Lỗi, hiện thông báo + nút Retry.
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

/// Filter cho tab "Đã đi".
enum CompletedFilter { all, rated, unrated }

/// Trạng thái ban đầu — chưa tải dữ liệu.
class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

/// Đang tải dữ liệu — UI hiển thị Shimmer loading.
class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

/// Tải thành công — chứa danh sách lịch trình và thống kê.
class ItineraryLoaded extends ItineraryState {
  /// Danh sách lịch trình (đã lọc hoặc toàn bộ).
  final List<ItineraryEntity> itineraries;

  /// Thống kê tổng quan (luôn là tổng, không bị ảnh hưởng bởi filter).
  final ItinerarySummary summary;

  /// Tab filter đang active (null = "Tất cả").
  final ItineraryStatus? activeFilter;

  /// Lịch trình đang được chọn để xem chi tiết hoặc tổng quan.
  final ItineraryDetailEntity? selectedItinerary;

  /// Filter cho tab "Đã đi".
  final CompletedFilter activeCompletedFilter;

  const ItineraryLoaded({
    required this.itineraries,
    required this.summary,
    this.activeFilter,
    this.selectedItinerary,
    this.activeCompletedFilter = CompletedFilter.all,
  });

  @override
  List<Object?> get props => [itineraries, summary, activeFilter, selectedItinerary, activeCompletedFilter];
}

/// Lỗi — hiển thị thông báo và nút Retry.
class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}