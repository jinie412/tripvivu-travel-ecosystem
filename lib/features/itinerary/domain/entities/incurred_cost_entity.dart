/// priceAdjustment ("Điều chỉnh giá") = điều chỉnh giá địa điểm (chỉ chủ
/// lịch trình, amount là chênh lệch có thể âm, luôn gắn 1 địa điểm, không
/// gán riêng cho ai). Các giá trị còn lại là chi phí phát sinh cá nhân (any
/// member tạo, chỉ người tạo được sửa/xoá).
///
/// Giá trị API ([toApi]/[fromApi]) là tiếng Việt có dấu, giống hệt DB — toàn
/// hệ thống dùng chung 1 chuỗi, không có bản dịch/slug tiếng Anh nào đứng
/// giữa (xem cost-type.enum.ts bên api-service).
enum CostType {
  priceAdjustment,
  water,
  gift,
  shopping,
  parkingFee,
  other;

  static CostType fromApi(String? value) {
    switch (value) {
      case 'Điều chỉnh giá':
        return CostType.priceAdjustment;
      case 'Nước uống':
        return CostType.water;
      case 'Quà tặng':
        return CostType.gift;
      case 'Mua sắm':
        return CostType.shopping;
      case 'Phí gửi xe':
        return CostType.parkingFee;
      default:
        return CostType.other;
    }
  }

  String toApi() => label;

  String get label {
    switch (this) {
      case CostType.priceAdjustment:
        return 'Điều chỉnh giá';
      case CostType.water:
        return 'Nước uống';
      case CostType.gift:
        return 'Quà tặng';
      case CostType.shopping:
        return 'Mua sắm';
      case CostType.parkingFee:
        return 'Phí gửi xe';
      case CostType.other:
        return 'Khác';
    }
  }
}

/// Một khoản chi phí phát sinh người dùng ghi nhận trong chuyến đi (mục 1.6),
/// gắn hoặc không gắn với 1 địa điểm cụ thể trong lịch trình.
class IncurredCostEntity {
  final String id;
  final CostType type;
  final String? placeId;
  final String? placeName;
  final String note;
  final double amount;
  // user_id phải gánh khoản này. Rỗng = chia đều cho cả nhóm. Luôn rỗng khi
  // type == priceAdjustment.
  final List<String> chargedTo;
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;

  const IncurredCostEntity({
    required this.id,
    this.type = CostType.other,
    this.placeId,
    this.placeName,
    required this.note,
    required this.amount,
    this.chargedTo = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
  });
}

/// Địa điểm đã "đi" (visited), đủ điều kiện chọn trong combobox mục 1.6.
class EligiblePlaceEntity {
  final String id;
  final String name;
  final String address;
  // Giá hiệu lực hiện tại của địa điểm này trong lịch trình (đã gồm mọi
  // price_adjustment trước đó) — hiển thị làm tham chiếu khi chọn type
  // "Điều chỉnh giá".
  final double currentEffectivePrice;

  const EligiblePlaceEntity({
    required this.id,
    required this.name,
    this.address = '',
    this.currentEffectivePrice = 0,
  });
}

/// "Mỗi người phải trả tổng bao nhiêu" (mục 1.7) — không có khái niệm nợ/ứng
/// tiền trước, chỉ là tổng chi phí mỗi người gánh (kế hoạch gốc + phát sinh).
///
/// [total] là phần CỦA RIÊNG người này (không gồm trẻ em, kể cả khi
/// isOwner). [childrenShare] > 0 chỉ với thành viên đang chịu trách nhiệm chi
/// phí trẻ em (mặc định là chủ lịch trình) — hiển thị thành dòng riêng, không
/// cộng gộp vào [total] để tránh gây hiểu lầm.
class MemberCostTotalEntity {
  final String userId;
  final String fullName;
  final bool isOwner;
  final double total;
  final double childrenShare;

  const MemberCostTotalEntity({
    required this.userId,
    required this.fullName,
    required this.isOwner,
    required this.total,
    this.childrenShare = 0,
  });
}

class CostBreakdownEntity {
  final List<MemberCostTotalEntity> memberTotals;
  final double totalCost;
  final double basePlanCost;
  final double incurredTotal;
  final double childrenShare;
  // Card 2: chi phí thực tế đã tiêu — chỉ tính địa điểm đã đi + chi phí phát
  // sinh gắn với địa điểm đã đi (hoặc không gắn địa điểm).
  final double spentSoFar;
  // Card 1: chi phí ước tính + mức có thể chi trả, mỗi cái 3 cách nhìn (cả
  // nhóm/mỗi người lớn/mỗi trẻ em) — tính tươi, không lưu, không suy ngược.
  final double estimatedCostForGroup;
  final double estimatedCostPerAdult;
  final double estimatedCostPerChild;
  final double payableLimitForGroup;
  final double payableLimitPerAdult;
  final double payableLimitPerChild;
  // Breakdown xổ ra khi bấm vào dòng "Người lớn"/"Trẻ em" ở Card 1 — đã
  // per-adult sẵn (transport dùng CHUNG 1 mức cho cả người lớn/trẻ em, vì
  // xăng xe chia đều đầu người thật, không phải giá vé).
  final double placeCostPerAdult;
  final double placeCostPerChild;
  final double hotelCostPerAdult;
  final double hotelCostPerChild;
  final double transportPerAdult;
  // Minh bạch: mức giá/km hiện dùng để tính transportPerAdult (VNĐ/km),
  // hiển thị phụ dưới số tiền để user hiểu căn cứ thay vì thấy "thấp" mà
  // không rõ vì sao.
  final double transportRatePerKmMotorbike;
  final double transportRatePerKmCar;
  final int adultCount;
  final int childCount;

  const CostBreakdownEntity({
    this.memberTotals = const [],
    this.totalCost = 0,
    this.basePlanCost = 0,
    this.incurredTotal = 0,
    this.childrenShare = 0,
    this.spentSoFar = 0,
    this.estimatedCostForGroup = 0,
    this.estimatedCostPerAdult = 0,
    this.estimatedCostPerChild = 0,
    this.payableLimitForGroup = 0,
    this.payableLimitPerAdult = 0,
    this.payableLimitPerChild = 0,
    this.placeCostPerAdult = 0,
    this.placeCostPerChild = 0,
    this.hotelCostPerAdult = 0,
    this.hotelCostPerChild = 0,
    this.transportPerAdult = 0,
    this.transportRatePerKmMotorbike = 0,
    this.transportRatePerKmCar = 0,
    this.adultCount = 1,
    this.childCount = 0,
  });
}
