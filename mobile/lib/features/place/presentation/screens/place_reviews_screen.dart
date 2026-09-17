import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/place/data/datasources/place_datasource.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_review_entity.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/review_card.dart';

class PlaceReviewsScreen extends StatefulWidget {
  final String placeId;
  final String placeName;

  const PlaceReviewsScreen({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<PlaceReviewsScreen> createState() => _PlaceReviewsScreenState();
}

class _PlaceReviewsScreenState extends State<PlaceReviewsScreen> {
  final _scrollController = ScrollController();
  final _items = <PlaceReviewEntity>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  int _filteredTotal = 0;
  int _pages = 0;
  double _average = 0;
  int? _selectedRating;
  Map<int, int> _breakdown = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 180 &&
        !_isLoading &&
        !_isLoadingMore &&
        _page < _pages) {
      _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _page = 1;
        _items.clear();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final touristId = await AuthUtils.getCurrentUserId();
      final data = await sl<PlaceDataSource>().getPlaceReviews(
        widget.placeId,
        touristId: touristId,
        rating: _selectedRating,
        page: _page,
        limit: _limit,
      );

      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(data.items);
        } else {
          _items.addAll(data.items);
        }
        _total = data.total;
        _filteredTotal = data.filteredTotal;
        _pages = data.pages;
        _limit = data.limit;
        _page = data.page + 1;
        _average = data.average;
        _breakdown = data.breakdown;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _changeRatingFilter(int? rating) {
    if (_selectedRating == rating) {
      return;
    }

    setState(() => _selectedRating = rating);
    _loadPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.premiumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.premiumBackground,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Bài đánh giá',
              style: TextStyle(
                color: AppColors.premiumNavy,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.placeName,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.premiumNavy,
            size: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_errorMessage != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  _StateMessage(
                    message: _errorMessage!,
                    actionLabel: 'Thử lại',
                    onAction: () => _loadPage(reset: true),
                  ),
                ],
              );
            }

            if (_items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _SummaryBox(
                    rating: _average,
                    totalReviews: _total,
                    breakdown: _breakdown,
                  ),
                  const SizedBox(height: 14),
                  _RatingFilterBar(
                    selectedRating: _selectedRating,
                    breakdown: _breakdown,
                    onChanged: _changeRatingFilter,
                  ),
                  const SizedBox(height: 56),
                  _StateMessage(
                    message: _selectedRating == null
                        ? 'Địa điểm này chưa có đánh giá.'
                        : 'Chưa có đánh giá ${_selectedRating!} sao.',
                  ),
                ],
              );
            }

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _SummaryBox(
                  rating: _average,
                  totalReviews: _total,
                  breakdown: _breakdown,
                ),
                const SizedBox(height: 14),
                _RatingFilterBar(
                  selectedRating: _selectedRating,
                  breakdown: _breakdown,
                  onChanged: _changeRatingFilter,
                ),
                const SizedBox(height: 18),
                ..._items.map((review) => ReviewCard(review: review)),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _SummaryBar(
        total: _total,
        filteredTotal: _filteredTotal,
        selectedRating: _selectedRating,
      ),
    );
  }
}

class _RatingFilterBar extends StatelessWidget {
  final int? selectedRating;
  final Map<int, int> breakdown;
  final ValueChanged<int?> onChanged;

  const _RatingFilterBar({
    required this.selectedRating,
    required this.breakdown,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final rating = index == 0 ? null : 6 - index;
          final isSelected = selectedRating == rating;
          final label = rating == null ? 'Tất cả' : '$rating';
          final count = rating == null
              ? breakdown.values.fold<int>(0, (sum, item) => sum + item)
              : breakdown[rating] ?? 0;

          return ChoiceChip(
            selected: isSelected,
            showCheckmark: false,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            avatar: rating == null
                ? null
                : Icon(
                    Icons.star,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.amber,
                  ),
            label: Text(
              count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onSelected: (_) => onChanged(rating),
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final Map<int, int> breakdown;

  const _SummaryBox({
    required this.rating,
    required this.totalReviews,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _formatRating(rating),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/5',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _stars(rating),
                const SizedBox(height: 8),
                Text(
                  '$totalReviews đánh giá',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _ratingBar(5, totalReviews, breakdown[5] ?? 0),
                _ratingBar(4, totalReviews, breakdown[4] ?? 0),
                _ratingBar(3, totalReviews, breakdown[3] ?? 0),
                _ratingBar(2, totalReviews, breakdown[2] ?? 0),
                _ratingBar(1, totalReviews, breakdown[1] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, int total, int count) {
    final percent = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            star.toString(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stars(double rating) {
    final roundedRating = (rating * 10).round() / 10;
    return Row(
      children: List.generate(
        5,
        (index) =>
            _fractionalStar((roundedRating - index).clamp(0.0, 1.0).toDouble()),
      ),
    );
  }

  Widget _fractionalStar(double fill) {
    const size = 16.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(
            Icons.star,
            size: size,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          ClipRect(
            clipper: _StarFillClipper(fill),
            child: const Icon(Icons.star, size: size, color: Colors.amber),
          ),
        ],
      ),
    );
  }

  String _formatRating(double value) {
    if (value <= 0) {
      return '0';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _StarFillClipper extends CustomClipper<Rect> {
  final double fill;

  const _StarFillClipper(this.fill);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_StarFillClipper oldClipper) => oldClipper.fill != fill;
}

class _StateMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final int total;
  final int filteredTotal;
  final int? selectedRating;

  const _SummaryBar({
    required this.total,
    required this.filteredTotal,
    required this.selectedRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Text(
        _summaryText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _summaryText {
    if (selectedRating != null) {
      return filteredTotal > 0
          ? '$filteredTotal đánh giá ${selectedRating!} sao'
          : 'Chưa có đánh giá ${selectedRating!} sao';
    }

    return total > 0 ? '$total đánh giá khả dụng' : 'Chưa có đánh giá khả dụng';
  }
}
