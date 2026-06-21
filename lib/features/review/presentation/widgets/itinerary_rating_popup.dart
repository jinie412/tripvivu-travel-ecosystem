import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/review_catalog_screen.dart';

enum _PopupMode { loading, write, read, error }

class ItineraryRatingPopup extends StatefulWidget {
  final String itineraryId;
  final String itineraryTitle;
  final int totalLocations;
  final int visitedLocations;

  const ItineraryRatingPopup({
    super.key,
    required this.itineraryId,
    required this.itineraryTitle,
    this.totalLocations = 0,
    this.visitedLocations = 0,
  });

  @override
  State<ItineraryRatingPopup> createState() => _ItineraryRatingPopupState();
}

class _ItineraryRatingPopupState extends State<ItineraryRatingPopup> {
  _PopupMode _mode = _PopupMode.loading;

  // Write mode state
  double _rating = 0;
  bool _isPublic = true;
  String _missedReason = '';
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;


  // Read mode state
  ItineraryReviewSummary? _existingReview;


  bool get _isHighlyCompleted =>
      widget.totalLocations > 0 &&
      (widget.visitedLocations / widget.totalLocations) >= 0.8;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await sl<ReviewRepository>().getReviewSummary(
        widget.itineraryId,
      );
      if (!mounted) return;
      if (summary.hasReview) {
        setState(() {
          _existingReview = summary;
          _mode = _PopupMode.read;
        });
      } else {
        setState(() => _mode = _PopupMode.write);
      }
    } catch (e, st) {
      debugPrint('[ItineraryRatingPopup] getReviewSummary error: $e\n$st');
      if (!mounted) return;
      // Lỗi mạng → fallback sang write mode thay vì chặn user
      setState(() => _mode = _PopupMode.write);
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao trước khi gửi')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await sl<ReviewRepository>().submitItineraryReview(
        itineraryId: widget.itineraryId,
        overallRating: _rating,
        overallContent: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        applyAllPlaces: false,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã đánh giá!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi đánh giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _goToDetailScreen({bool isReadOnly = false}) async {
    final navigatorContext = Navigator.of(context).context;
    Navigator.pop(context);
    if (isReadOnly) {
      await openReviewedItineraryReview(navigatorContext, widget.itineraryId);
      return;
    }
    if (!navigatorContext.mounted) return;
    Navigator.push(
      navigatorContext,
      MaterialPageRoute(
        builder: (_) => RateItineraryScreen(
          itineraryId: widget.itineraryId,
          initialRating: _rating,
          initialComment: _commentController.text,
        ),
      ),
    );
  }

  Future<void> _dismiss() async {
    try {
      await sl<ReviewRepository>().dismissPopup(widget.itineraryId);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: switch (_mode) {
            _PopupMode.loading => _buildLoading(),
            _PopupMode.write => _buildWriteMode(),
            _PopupMode.read => _buildReadMode(),
            _PopupMode.error => _buildWriteMode(),
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Lịch trình đã kết thúc',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWriteMode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const Text(
          'Bạn đánh giá thế nào về lịch trình này?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: index < _rating
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFCBD5E1),
                size: 40,
              ),
              onPressed: () => setState(() => _rating = index + 1.0),
            );
          }),
        ),
        TextButton.icon(
          onPressed: () => _goToDetailScreen(),
          icon: const Icon(Icons.stars_rounded, size: 18),
          label: const Text(
            'Đánh giá chi tiết địa điểm',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isHighlyCompleted
                ? 'Chia sẻ cảm nhận nổi bật của bạn về chuyến đi:'
                : 'Có vẻ lịch trình này chưa thực sự phù hợp với mong đợi của bạn? Chia sẻ lý do bạn bỏ lỡ một số địa điểm nhé:',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (_isHighlyCompleted ? kTravelReviewTags : kMissedLocationReasons)
              .map((reason) {
                final isSelected = _missedReason == reason;
                return _choiceChip(reason, isSelected);
              })
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: _isHighlyCompleted
                ? 'Chia sẻ cảm nghĩ của bạn về chuyến đi...'
                : 'Chia sẻ thêm chi tiết hoặc góp ý để chúng tôi cải thiện...',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bạn có muốn công khai đánh giá này đến mọi người?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _dismiss,
                child: const Text(
                  'Để sau',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gửi đánh giá',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadMode() {
    final review = _existingReview!;
    final existingRating = review.rating ?? 0;
    final hasContent =
        review.content != null && review.content!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const Text(
          'Bạn đã đánh giá lịch trình này',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return Icon(
              index < existingRating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: index < existingRating
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFCBD5E1),
              size: 40,
            );
          }),
        ),
        if (hasContent) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Text(
              review.content!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _goToDetailScreen(isReadOnly: true),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text(
              'Xem chi tiết đánh giá',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Đóng',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceChip(String label, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _missedReason = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
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
