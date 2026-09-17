import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/entities/trip_form.dart';

part 'trip_planner_state.freezed.dart';

@freezed
class TripPlannerState with _$TripPlannerState {
  const factory TripPlannerState.initial() = _Initial;
  const factory TripPlannerState.loading() = _Loading;
  const factory TripPlannerState.loaded({required TripForm tripForm}) = _Loaded;
  // isDetectingRegions = true cho bước gửi form lần đầu (backend chỉ chạy
  // phát hiện vùng địa lý, nhanh) — false cho bước sau khi đã chốt phân bổ
  // vùng (backend chạy CP-SAT lập lịch trình thật, có thể mất 20-30 giây) —
  // dùng để chọn đúng bộ thông điệp loading cho từng giai đoạn.
  const factory TripPlannerState.generating({
    @Default(false) bool isDetectingRegions,
  }) = _Generating;
  const factory TripPlannerState.success({required String itineraryId}) =
      _Success;
  const factory TripPlannerState.error(String message) = _Error;
  // Ngân sách nhập vào không đủ tạo lịch trình khả thi — hỏi người dùng dùng
  // mức đề xuất hay tiếp tục với ngân sách hiện tại (xem mục 1.5 trong plan
  // chi phí chuyến đi).
  const factory TripPlannerState.budgetConfirmationRequired({
    required String message,
    required double userBudget,
    required double calculatedCost,
    required double recommendedBudget,
    required int participantCount,
    String? confirmToken,
  }) = _BudgetConfirmationRequired;
  // Backend vừa phân cụm địa lý xong — luôn hỏi người dùng phân bổ số ngày
  // cho từng vùng trước khi tạo lịch trình thật sự (wizard phân vùng).
  const factory TripPlannerState.regionAllocationRequired({
    required String message,
    required List<RegionInfo> regions,
    required int numDays,
    required int estimatedTotalDays,
  }) = _RegionAllocationRequired;
  // Scheduler không tìm được BẤT KỲ lịch trình nào thỏa ngân sách/thời
  // gian/giờ mở cửa (khác budgetConfirmationRequired: đó là "tìm được nhưng
  // đắt hơn", đây là "không tìm được cái nào cả") — hiện dialog đứng yên
  // kèm gợi ý, không phải SnackBar tự biến mất như trước.
  const factory TripPlannerState.infeasible({
    required String message,
    @Default([]) List<String> suggestions,
  }) = _Infeasible;
  // Backend chặn sớm TRƯỚC KHI chạy thuật toán vì ngân sách rõ ràng quá
  // thấp (không đủ ngay cả mức sàn tối thiểu) — khác infeasible (đã chạy
  // xong mới biết không đủ), nên không có gì để "dùng mức đề xuất".
  const factory TripPlannerState.budgetTooLow({
    required String message,
    required double minimumBudget,
  }) = _BudgetTooLow;
}
