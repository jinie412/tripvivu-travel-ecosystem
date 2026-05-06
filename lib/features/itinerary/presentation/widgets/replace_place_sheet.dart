import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

// ─── Internal data model ──────────────────────────────────────────────────────

class _PlaceSuggestion {
  final String id;
  final String name;
  final String address;
  final String category;
  final double rating;
  final int reviewCount;
  final double? price;
  final bool isFree;
  final String imageUrl;
  final List<String> tags;
  final double? distanceKm;
  final bool isFeatured;

  const _PlaceSuggestion({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.rating,
    required this.reviewCount,
    this.price,
    this.isFree = false,
    required this.imageUrl,
    this.tags = const [],
    this.distanceKm,
    this.isFeatured = false,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const _kSuggestions = [
  _PlaceSuggestion(
    id: 'p1',
    name: 'Cầu Vàng Bà Nà Hills',
    address: 'Bà Nà Hills, Đà Nẵng',
    category: 'Tham quan',
    rating: 4.9,
    reviewCount: 12800,
    price: 750000,
    imageUrl: 'https://images.unsplash.com/photo-1576919228236-a097c32a5cd4?w=600&q=80',
    tags: ['Cùng danh mục', 'Được đánh giá cao'],
    distanceKm: 3.2,
    isFeatured: true,
  ),
  _PlaceSuggestion(
    id: 'p2',
    name: 'Ngũ Hành Sơn',
    address: 'Quận Ngũ Hành Sơn, Đà Nẵng',
    category: 'Tham quan',
    rating: 4.7,
    reviewCount: 8500,
    price: 40000,
    imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80',
    tags: ['Cùng danh mục', 'Gần khu vực'],
    distanceKm: 1.8,
    isFeatured: true,
  ),
  _PlaceSuggestion(
    id: 'p3',
    name: 'Bảo tàng Mỹ Thuật Đà Nẵng',
    address: '78 Lê Duẩn, Hải Châu, Đà Nẵng',
    category: 'Tham quan',
    rating: 4.4,
    reviewCount: 2100,
    isFree: true,
    imageUrl: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=600&q=80',
    tags: ['Cùng danh mục', 'Miễn phí'],
    distanceKm: 0.5,
    isFeatured: true,
  ),
  _PlaceSuggestion(
    id: 'p4',
    name: 'Mì Quảng Bà Mua',
    address: '19-21 Trần Bình Trọng, Đà Nẵng',
    category: 'Ăn uống',
    rating: 4.6,
    reviewCount: 3200,
    price: 60000,
    imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&q=80',
    tags: ['Phổ biến', 'Ẩm thực địa phương'],
    distanceKm: 1.2,
  ),
  _PlaceSuggestion(
    id: 'p5',
    name: 'Chùa Linh Ứng Sơn Trà',
    address: 'Bán đảo Sơn Trà, Đà Nẵng',
    category: 'Tham quan',
    rating: 4.8,
    reviewCount: 15000,
    isFree: true,
    imageUrl: 'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=600&q=80',
    tags: ['Cùng danh mục', 'Miễn phí', 'Phổ biến'],
    distanceKm: 5.5,
  ),
  _PlaceSuggestion(
    id: 'p6',
    name: 'Khu vui chơi Sun World',
    address: 'Bà Nà Hills, Đà Nẵng',
    category: 'Giải trí',
    rating: 4.7,
    reviewCount: 20000,
    price: 850000,
    imageUrl: 'https://images.unsplash.com/photo-1531804055935-76f44d7c3621?w=600&q=80',
    tags: ['Giải trí', 'Gia đình'],
    distanceKm: 4.0,
  ),
  _PlaceSuggestion(
    id: 'p7',
    name: 'Chợ Cồn Đà Nẵng',
    address: 'Ông Ích Khiêm, Hải Châu, Đà Nẵng',
    category: 'Mua sắm',
    rating: 4.2,
    reviewCount: 1800,
    isFree: true,
    imageUrl: 'https://images.unsplash.com/photo-1555636222-cae831e670b3?w=600&q=80',
    tags: ['Mua sắm', 'Ẩm thực'],
    distanceKm: 0.8,
  ),
  _PlaceSuggestion(
    id: 'p8',
    name: 'Công viên APEC',
    address: 'Đường 2/9, Hải Châu, Đà Nẵng',
    category: 'Tham quan',
    rating: 4.3,
    reviewCount: 900,
    isFree: true,
    imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600&q=80',
    tags: ['Cùng danh mục', 'Gần khu vực'],
    distanceKm: 0.3,
  ),
];


// ─── Main Widget ──────────────────────────────────────────────────────────────

class ReplacePlaceSheet extends StatefulWidget {
  final ItineraryActivityEntity currentActivity;
  final Function(String placeId, String placeName) onReplace;

  const ReplacePlaceSheet({
    super.key,
    required this.currentActivity,
    required this.onReplace,
  });

  static void show(
    BuildContext context, {
    required ItineraryActivityEntity activity,
    required Function(String placeId, String placeName) onReplace,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplacePlaceSheet(
        currentActivity: activity,
        onReplace: onReplace,
      ),
    );
  }

  @override
  State<ReplacePlaceSheet> createState() => _ReplacePlaceSheetState();
}

class _ReplacePlaceSheetState extends State<ReplacePlaceSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  List<_PlaceSuggestion> get _listItems {
    return _kSuggestions.where((p) {
      return _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(int count) =>
      count >= 1000 ? '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k' : '$count';

  String _fmtPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)}M₫';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k₫';
    return '${price.toStringAsFixed(0)}₫';
  }

  Color _tagColor(String tag) {
    if (tag.contains('danh mục')) return const Color(0xFF2563EB);
    if (tag.contains('Gần')) return const Color(0xFF10B981);
    if (tag.contains('cao') || tag.contains('Phổ biến')) return const Color(0xFFF59E0B);
    if (tag.contains('Miễn phí')) return const Color(0xFF10B981);
    return const Color(0xFF8B5CF6);
  }

  void _onSelect(_PlaceSuggestion place) {
    widget.onReplace(place.id, place.name);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thay thế bằng "${place.name}"'),
        backgroundColor: AppColorsExt.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r12)),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.78, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
          ),
          child: Column(
            children: [
              _Header(
                currentActivity: widget.currentActivity,
                searchController: _searchController,
                searchQuery: _searchQuery,
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    _SectionTitle(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColorsExt.warning,
                      title: _searchQuery.isNotEmpty
                          ? 'Kết quả tìm kiếm (${_listItems.length})'
                          : 'Gợi ý',
                    ),
                    if (_listItems.isEmpty)
                      _EmptyState(isSearching: _searchQuery.isNotEmpty)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
                        itemCount: _listItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSizes.s12),
                        itemBuilder: (_, i) => _ListCard(
                          place: _listItems[i],
                          onSelect: () => _onSelect(_listItems[i]),
                          fmt: _fmt,
                          fmtPrice: _fmtPrice,
                          tagColor: _tagColor,
                        ),
                      ),
                    const SizedBox(height: AppSizes.s20),
                    _ManualAddButton(
                      onTap: () => _showManualAddDialog(context),
                    ),
                    const SizedBox(height: AppSizes.s32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManualAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r20)),
        title: const Text('Thêm địa điểm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập tên địa điểm muốn thay thế vào lịch trình',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: AppSizes.s16),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'VD: Quán cà phê Mỹ Hạnh...',
                hintStyle: const TextStyle(color: AppColorsExt.textHint, fontSize: 14),
                filled: true,
                fillColor: AppColorsExt.searchBarBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s16, vertical: AppSizes.s12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                widget.onReplace('custom_${DateTime.now().millisecondsSinceEpoch}', name);
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12)),
              elevation: 0,
            ),
            child:
                const Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ItineraryActivityEntity currentActivity;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onClose;

  const _Header({
    required this.currentActivity,
    required this.searchController,
    required this.searchQuery,
    required this.onClearSearch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Close
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thay thế địa điểm',
                  style: AppTextStyles.heading2
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColorsExt.searchBarBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),

          // Current place mini card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(AppSizes.r12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.s8),
                  child: NetImage(
                    url: currentActivity.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đang thay thế',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentActivity.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColorsExt.textDark,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.s8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      size: 16, color: Color(0xFFF59E0B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.s12),

          // Search bar
          Container(
            height: AppSizes.searchBarHeight,
            decoration: BoxDecoration(
              color: AppColorsExt.searchBarBg,
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSizes.s12),
                const Icon(Icons.search,
                    size: AppSizes.iconMd, color: AppColors.textSecondary),
                const SizedBox(width: AppSizes.s4),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa điểm cần thay thế...',
                      hintStyle: TextStyle(
                        color: AppColorsExt.textHint,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: onClearSearch,
                    child: const Padding(
                      padding: EdgeInsets.all(AppSizes.s8),
                      child: Icon(Icons.close,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  )
                else
                  const SizedBox(width: AppSizes.s12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.s20, AppSizes.s16, AppSizes.s20, AppSizes.s12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: AppSizes.s8),
          Text(title,
              style: AppTextStyles.heading2
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
// ─── List card ────────────────────────────────────────────────────────────────

class _ListCard extends StatelessWidget {
  final _PlaceSuggestion place;
  final VoidCallback onSelect;
  final String Function(int) fmt;
  final String Function(double) fmtPrice;
  final Color Function(String) tagColor;

  const _ListCard({
    required this.place,
    required this.onSelect,
    required this.fmt,
    required this.fmtPrice,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          NetImage(
            url: place.imageUrl,
            width: 88,
            height: 95,
            borderRadius: AppSizes.r16,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: AppSizes.s12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 11, color: AppColorsExt.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          place.address,
                          style: AppTextStylesExt.bodySmall
                              .copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 12, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text(
                        '${place.rating} (${fmt(place.reviewCount)})',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      if (place.distanceKm != null) ...[
                        const SizedBox(width: AppSizes.s8),
                        const Icon(Icons.near_me,
                            size: 11, color: AppColorsExt.textHint),
                        const SizedBox(width: 2),
                        Text('${place.distanceKm}km',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColorsExt.textHint)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Wrap(
                    spacing: 4,
                    children: place.tags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor(tag).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                                fontSize: 9,
                                color: tagColor(tag),
                                fontWeight: FontWeight.w600)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          // Select button
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.s12),
            child: GestureDetector(
              onTap: onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s12, vertical: AppSizes.s8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: const Text('Chọn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearching;

  const _EmptyState({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s32),
      child: Center(
        child: Column(
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.location_off_outlined,
              size: 48,
              color: AppColorsExt.divider,
            ),
            const SizedBox(height: AppSizes.s12),
            Text(
              isSearching
                  ? 'Không tìm thấy địa điểm nào'
                  : 'Chưa có gợi ý cho danh mục này',
              style: AppTextStylesExt.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Manual add button ────────────────────────────────────────────────────────

class _ManualAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ManualAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
            borderRadius: BorderRadius.circular(AppSizes.r16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline_rounded,
                  size: AppSizes.iconSm, color: AppColors.primary),
              const SizedBox(width: AppSizes.s8),
              Text('Chọn từ danh mục yêu thích',
                  style: AppTextStylesExt.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
