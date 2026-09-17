/// Cấu hình tính năng Theo dõi lịch trình.
///
/// Tất cả hằng số liên quan đến geofence, dwell time và proximity
/// được tập trung tại đây để dễ điều chỉnh về sau.
class TrackingConfig {
  TrackingConfig._();

  /// Bán kính geofence mỗi địa điểm (mét).
  /// Tăng nếu trigger không nhạy; giảm nếu có false positive.
  static const int radiusM = 100;

  /// Thời gian ở lại tối thiểu để tính "Đã đến nơi" (giây).
  /// Android loitering delay = giá trị này.
  static const int dwellSeconds = 15;

  /// Giới hạn dwell khi demo. Backend đôi khi trả dwell theo thời lượng
  /// tham quan thật, ví dụ 3040s; mobile clamp về giá trị này để demo nhanh.
  static const int maxDemoDwellSeconds = 15;

  /// Khoảng cách hiện popup gợi ý đặt món tại quán ăn (km).
  static const double foodProximityKm = 5.0;
}
