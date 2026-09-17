/// Thrown when POST /itinerary/plan returns 422 BUDGET_TOO_LOW — backend đã
/// chặn sớm TRƯỚC KHI chạy thuật toán lập lịch trình (Two-Tower/CP-SAT), vì
/// ngân sách nhập vào rõ ràng không đủ ngay cả ở mức sàn tối thiểu (300k/
/// ngày/người lớn × số ngày × số người) — tránh tốn thời gian chờ vô ích.
/// Khác ItineraryInfeasibleException/BudgetConfirmationRequiredException:
/// 2 cái đó xảy ra SAU KHI đã chạy thuật toán, còn cái này chặn trước khi
/// chạy nên không có gì để "dùng mức đề xuất" — chỉ có thể tự tăng ngân sách
/// rồi thử lại.
class BudgetTooLowException implements Exception {
  final String message;
  final double minimumBudget;
  final int requestedDays;
  final int participantCount;

  BudgetTooLowException({
    required this.message,
    required this.minimumBudget,
    required this.requestedDays,
    required this.participantCount,
  });

  factory BudgetTooLowException.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) => (value ?? 0).toDouble();
    return BudgetTooLowException(
      message:
          json['message']?.toString() ??
          'Ngân sách bạn nhập quá thấp để tạo lịch trình.',
      minimumBudget: toDouble(json['minimumBudget']),
      requestedDays: (json['requestedDays'] as num?)?.toInt() ?? 0,
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  String toString() => message;
}
