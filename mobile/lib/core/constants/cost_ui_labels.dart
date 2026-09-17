/// Bộ thuật ngữ dùng chung cho tất cả điểm chạm liên quan đến chi phí.
///
/// Hai màn Tổng quan lịch trình và Quản lý chi phí phải dùng các nhãn này
/// để người dùng không phải hiểu lại cùng một khái niệm dưới nhiều tên gọi.
class CostUiLabels {
  CostUiLabels._();

  static const managementTitle = 'Quản lý chi phí';
  static const overviewEyebrow = 'TỔNG QUAN CHI PHÍ';
  static const estimatedTotal = 'Tổng chi phí ước tính';
  static const spent = 'Chi phí đã chi';
  static const spendingLimit = 'Hạn mức chi tiêu';
  static const reserveIncluded = 'Đã gồm 10% dự trù';
  static const beforeReserve = 'Chi phí trước dự trù';
  static const estimateDetails = 'Chi tiết chi phí ước tính';
  static const estimateDetailsSubtitle =
      'Theo người lớn, trẻ em và từng hạng mục';
  static const estimateByTraveler = 'Chi tiết chi phí theo loại khách';
  static const memberAllocation = 'Chi phí theo thành viên';
  static const memberAllocationSubtitle = 'Số tiền mỗi người chịu trách nhiệm';
  static const expenseHistory = 'Lịch sử chi tiêu';
  static const viewDetails = 'Xem chi tiết và quản lý khoản chi';

  // Card "Tổng quan ngày" ở Chi tiết lịch trình — CỐ Ý ghi rõ "ngày này" để
  // không bị hiểu nhầm là số của CẢ CHUYẾN (estimatedTotal/spent ở trên là
  // số cả chuyến, 2 khái niệm khác nhau dù trước đây dùng chung chữ "Tổng
  // chi phí"/"Đã chi" ngắn gọn, gây lẫn lộn giữa các màn).
  static const dayTotalCost = 'Chi phí ngày này';
  static const daySpent = 'Đã chi ngày này';
}
