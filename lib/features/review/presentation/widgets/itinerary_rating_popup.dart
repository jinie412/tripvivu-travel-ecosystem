import 'package:flutter/material.dart';

import 'star_rating_input.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';

class ItineraryRatingPopup extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;

  const ItineraryRatingPopup({
    super.key,
    required this.itineraryId,
    required this.itineraryTitle,
  });

  @override
  State<ItineraryRatingPopup> createState() => _ItineraryRatingPopupState();
}

class _ItineraryRatingPopupState extends State<ItineraryRatingPopup> {
  double _rating = 4.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ),
              
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '🎉',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Chuyến đi của bạn đã hoàn thành!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Hãy chia sẻ trải nghiệm của bạn về lịch trình này',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              
              // Stars
              StarRatingInput(
                rating: _rating,
                onRatingChanged: (val) {
                  setState(() => _rating = val);
                },
                size: 32,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              const SizedBox(height: 20),
              
              // Feedback Textfield - CLEANED BORDERS & UNIFORM BACKGROUND
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Nhập phản hồi của bạn tại đây...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // "Đánh giá chi tiết" Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RateItineraryScreen(itineraryId: widget.itineraryId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Đánh giá chi tiết',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // "Gửi đánh giá" Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          try {
                            await sl<ReviewRepository>().submitItineraryReview(
                              itineraryId: widget.itineraryId,
                              overallRating: _rating,
                              overallContent: _feedbackController.text,
                              applyAllPlaces: true,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cảm ơn bạn đã phản hồi!'),
                                backgroundColor: Color(0xFF22C55E),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Không thể gửi đánh giá: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Gửi đánh giá',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.send_outlined, size: 16, color: Color(0xFF475569)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              // "Để sau" link
              TextButton(
                onPressed: () async {
                  try {
                    await sl<ReviewRepository>().dismissPopup(widget.itineraryId);
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Để sau',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}