/// Thrown when POST /itinerary/plan returns 422 ITINERARY_INFEASIBLE — the
/// scheduler could not find ANY plan satisfying budget/thời gian/giờ mở cửa
/// (khác BudgetConfirmationRequiredException: đó là "tìm được nhưng đắt hơn
/// ngân sách", còn đây là "không tìm được cái nào cả"). Trước đây rơi vào
/// catch-all Exception rồi chỉ hiện SnackBar tự biến mất — giờ tách riêng để
/// hiện dialog đứng yên kèm gợi ý xử lý, giống budgetConfirmationRequired.
class ItineraryInfeasibleException implements Exception {
  final String message;
  final List<String> suggestions;

  ItineraryInfeasibleException({
    required this.message,
    this.suggestions = const [],
  });

  factory ItineraryInfeasibleException.fromJson(Map<String, dynamic> json) {
    return ItineraryInfeasibleException(
      message:
          json['message']?.toString() ??
          'Không tìm được lịch trình thỏa ngân sách, thời gian và giờ mở cửa.',
      suggestions:
          (json['suggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  String toString() => message;
}
