import '../entities/itinerary_entity.dart';
import '../entities/itinerary_summary.dart';
import '../entities/itinerary_detail_entity.dart';

/// Hợp đồng (Interface) cho tầng Data.
///
/// Tầng Domain chỉ biết interface này.
/// Tầng Data sẽ cung cấp implementation cụ thể (Mock hoặc Remote).
abstract class ItineraryRepository {
  /// Lấy danh sách lịch trình, tùy chọn lọc theo [status].
  Future<List<ItineraryEntity>> getItineraries({ItineraryStatus? status});

  /// Lấy thống kê tổng quan (tổng / đã đi / sắp đi / nháp).
  Future<ItinerarySummary> getSummary();

  /// Lấy chi tiết một lịch trình theo [id].
  Future<ItineraryDetailEntity> getItineraryDetail(String id);

  /// Xóa một lịch trình theo [id].
  Future<void> deleteItinerary(String id);
}
