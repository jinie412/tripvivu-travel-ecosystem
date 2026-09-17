enum CostWarningLevel { normal, warning, danger }

class CostWarningResult {
  final CostWarningLevel level;
  final String? message;

  CostWarningResult({required this.level, this.message});
}

/// Hệ cảnh báo 2 mức duy nhất, dùng chung cho mọi màn hình hiển thị chi phí.
/// [roundedGroupTotal] (đã gồm 10% dự trù + làm tròn trăm nghìn) phải lấy từ
/// `CostBreakdownEntity` (tính 1 lần ở backend) — không tự suy lại ở đây, để
/// tránh mỗi màn ra một con số khác nhau.
class CostWarningUtils {
  static CostWarningResult evaluate({
    required double roundedGroupTotal,
    required double actualSpent,
    required double maxBudget,
  }) {
    if (maxBudget > 0 && actualSpent >= maxBudget * 0.9) {
      return CostWarningResult(
        level: CostWarningLevel.danger,
        message: "Cảnh báo: Bạn đã sử dụng 90% hạn mức chi trả cho chuyến đi này.",
      );
    }

    if (actualSpent > roundedGroupTotal) {
      return CostWarningResult(
        level: CostWarningLevel.warning,
        message: "Lưu ý: Chi phí thực tế đã vượt quá mức ước tính và quỹ dự trù.",
      );
    }

    return CostWarningResult(level: CostWarningLevel.normal, message: null);
  }
}
