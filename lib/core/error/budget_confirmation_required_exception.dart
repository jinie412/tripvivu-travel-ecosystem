/// Thrown when POST /itinerary/plan returns 422 BUDGET_CONFIRMATION_REQUIRED —
/// the requested budget can't produce a feasible itinerary. Carries the
/// numbers needed to show a confirmation dialog offering either a higher
/// recommended budget or proceeding anyway with an over-budget itinerary.
class BudgetConfirmationRequiredException implements Exception {
  final String message;
  final double userBudget;
  final double calculatedCost;
  final double recommendedBudget;
  final int participantCount;

  BudgetConfirmationRequiredException({
    required this.message,
    required this.userBudget,
    required this.calculatedCost,
    required this.recommendedBudget,
    required this.participantCount,
  });

  factory BudgetConfirmationRequiredException.fromJson(
    Map<String, dynamic> json,
  ) {
    double toDouble(dynamic value) => (value ?? 0).toDouble();
    return BudgetConfirmationRequiredException(
      message:
          json['message']?.toString() ??
          'Ngân sách đã nhập chưa đủ cho một lịch trình phù hợp.',
      userBudget: toDouble(json['userBudget']),
      calculatedCost: toDouble(json['calculatedCost']),
      recommendedBudget: toDouble(json['recommendedBudget']),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  String toString() => message;
}
