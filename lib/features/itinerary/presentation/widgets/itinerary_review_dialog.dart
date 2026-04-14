import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';

class ItineraryReviewDialog extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;
  final int totalLocations;
  final int visitedLocations;

  const ItineraryReviewDialog({
    super.key,
    required this.itineraryId,
    required this.itineraryTitle,
    required this.totalLocations,
    required this.visitedLocations,
  });

  @override
  State<ItineraryReviewDialog> createState() => _ItineraryReviewDialogState();
}

class _ItineraryReviewDialogState extends State<ItineraryReviewDialog> {
  double _rating = 0;
  bool _isPublic = true;
  String _missedReason = '';
  final TextEditingController _commentController = TextEditingController();

  final List<String> _suggestedReasons = [
    'Thời gian quá gấp',
    'Địa điểm không như mong đợi',
    'Thời tiết không thuận lợi',
    'Sức khỏe không đảm bảo',
    'Tìm thấy địa điểm khác thú vị hơn',
  ];

  @override
  Widget build(BuildContext context) {
    final bool isHighlyCompleted = (widget.visitedLocations / widget.totalLocations) >= 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lịch trình đã kết thúc',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Đã đi ${widget.visitedLocations}/${widget.totalLocations} địa điểm',
                  style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Rating Area
              const Text(
                'Bạn đánh giá thế nào về lịch trình này?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < _rating ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                      size: 40,
                    ),
                    onPressed: () => setState(() => _rating = index + 1.0),
                  );
                }),
              ),
              
              // Nút Đánh giá chi tiết địa điểm
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RateItineraryScreen(
                        itineraryId: widget.itineraryId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.stars_rounded, size: 18),
                label: const Text('Đánh giá chi tiết địa điểm'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),

              const SizedBox(height: 12),

              // Feedback for Missed Locations (Path 2)
              if (!isHighlyCompleted) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Có vẻ lịch trình này chưa thực sự phù hợp với mong đợi của bạn? Chia sẻ lý do bạn bỏ lỡ một số địa điểm nhé:',
                    style: TextStyle(fontSize: 14, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedReasons.map((reason) {
                    final isSelected = _missedReason == reason;
                    return choiceChip(reason, isSelected);
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Comment Area
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isHighlyCompleted ? 'Chia sẻ cảm nghĩ của bạn về chuyến đi...' : 'Chia sẻ thêm chi tiết hoặc góp ý để chúng tôi cải thiện...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Public Privacy Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _isPublic,
                        onChanged: (val) => setState(() => _isPublic = val ?? true),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Bạn có muốn công khai đánh giá này đến mọi người?',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bỏ qua', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Submit logic here
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cảm ơn bạn đã đóng góp đánh giá!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Gửi đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget choiceChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _missedReason = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
