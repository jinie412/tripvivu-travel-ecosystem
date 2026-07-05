import 'package:flutter/material.dart';

/// Dialog xác nhận dừng lịch trình với lời lẽ thân thiện, dùng chung cho
/// thẻ lịch trình ở trang Khám phá và danh sách Lịch trình của tôi.
///
/// Trả về `true` khi người dùng xác nhận dừng.
Future<bool> showStopTrackingDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.flag_circle_rounded,
                  color: Color(0xFFF97316),
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dừng chuyến đi này?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ứng dụng sẽ ngừng tự động điểm danh các địa điểm và '
              'cập nhật lại trạng thái lịch trình của bạn.\n'
              'Bạn luôn có thể bắt đầu lại khi sẵn sàng nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục đi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        // Padding ngang mặc định lớn làm chữ bị xuống dòng
                        // trong dialog hẹp — thu nhỏ lại
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      // FittedBox: luôn 1 dòng, tự co chữ nếu màn quá hẹp
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Dừng chuyến đi',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed == true;
}
