class AppConfig {
  /// 🔧 TRUNG TÂM ĐIỀU KHIỂN CHẾ ĐỘ DEMO
  /// - true: Dùng dữ liệu mẫu (Mock data), bỏ qua Login, Backend.
  /// - false: Kết nối API thật, yêu cầu Login.
  static const bool kUseMockData = false; 

  /// Tự động bỏ qua màn hình đăng nhập nếu đang ở chế độ Demo
  static const bool kSkipLogin = kUseMockData;
}
