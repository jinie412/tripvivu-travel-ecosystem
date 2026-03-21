import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/net_image.dart';

class DetailedPlaceCard extends StatefulWidget {
  final String title;
  final double rating;
  final String reviews;
  final String imageUrl;
  final int placeholderColor;
  final String info; 
  final VoidCallback? onTap;
  final VoidCallback? onAddTap;

  const DetailedPlaceCard({
    super.key,
    required this.title,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.placeholderColor,
    required this.info,
    this.onTap,
    this.onAddTap,
  });

  @override
  State<DetailedPlaceCard> createState() => _DetailedPlaceCardState();
}

class _DetailedPlaceCardState extends State<DetailedPlaceCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Hero Image
            SizedBox(
              height: 180,
              width: double.infinity,
              child: NetImage(url: widget.imageUrl, placeholderColor: widget.placeholderColor),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                          if (_isFavorite) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã lưu vào danh mục yêu thích'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_outline,
                          color: _isFavorite ? Colors.red : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2), // Adjusted for IconButton padding
                  Row(
                    children: [
                      // Modern Star Rating with Half Stars
                      ...List.generate(5, (index) {
                        if (index < widget.rating.floor()) {
                          return const Icon(Icons.star, color: Color(0xFFFFB400), size: 18);
                        } else if (index == widget.rating.floor() && (widget.rating - widget.rating.floor()) >= 0.5) {
                          return const Icon(Icons.star_half, color: Color(0xFFFFB400), size: 18);
                        } else {
                          return const Icon(Icons.star_border, color: Color(0xFFFFB400), size: 18);
                        }
                      }),
                      const SizedBox(width: 8),
                      Text(
                        widget.rating.toString(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.reviews} đánh giá)',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.info,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onAddTap != null)
                        ElevatedButton.icon(
                          onPressed: widget.onAddTap,
                          icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: Colors.white),
                          label: const Text('Thêm địa điểm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
