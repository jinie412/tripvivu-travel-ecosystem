import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

import '../../data/datasources/nearby_places_api.dart';
import '../../../../core/di/injection_container.dart';
import '../../../saved/domain/usecases/get_favorite_places_usecase.dart';
// ─── Main Widget ──────────────────────────────────────────────────────────────

class AddPlaceSheet extends StatefulWidget {
  final Function(NearbyPlaceModel place) onAdd;
  final double? referenceLat;
  final double? referenceLng;
  final List<String>? existingIds;
  /// Ngày tham quan — dùng để validate opening hours đúng ngày trong tuần.
  final DateTime? visitDate;
  /// Giờ dự kiến tham quan (HH:mm) — dùng để validate opening hours.
  final String? proposedVisitTime;
  final String? destinationCity;

  const AddPlaceSheet({
    super.key,
    required this.onAdd,
    this.referenceLat,
    this.referenceLng,
    this.existingIds,
    this.visitDate,
    this.proposedVisitTime,
    this.destinationCity,
  });

  static void show(
    BuildContext context, {
    required Function(NearbyPlaceModel place) onAdd,
    double? referenceLat,
    double? referenceLng,
    List<String>? existingIds,
    DateTime? visitDate,
    String? proposedVisitTime,
    String? destinationCity,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddPlaceSheet(
        onAdd: onAdd,
        referenceLat: referenceLat,
        referenceLng: referenceLng,
        existingIds: existingIds,
        visitDate: visitDate,
        proposedVisitTime: proposedVisitTime,
        destinationCity: destinationCity,
      ),
    );
  }

  @override
  State<AddPlaceSheet> createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  bool _isLoading = true;
  List<NearbyPlaceModel> _allPlaces = [];

  List<NearbyPlaceModel> get _listItems => _allPlaces;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadNearbyPlaces();
  }

  // Whitelist: chỉ hiện category là địa điểm du lịch / tham quan / vui chơi
  static const _tourismCategoryKeywords = [
    // Di tích, tín ngưỡng
    'chùa', 'đền', 'tháp', 'đình', 'miếu', 'nhà thờ', 'tu viện',
    'pagoda', 'temple', 'shrine', 'church', 'cathedral',
    // Thắng cảnh, lịch sử
    'di tích', 'thắng cảnh', 'danh lam', 'lịch sử', 'văn hóa', 'heritage',
    'landmark', 'monument', 'ruins', 'citadel', 'castle', 'palace',
    // Thiên nhiên
    'công viên', 'vườn', 'thiên nhiên', 'núi', 'biển', 'hồ', 'thác', 'hang',
    'park', 'garden', 'nature', 'beach', 'mountain', 'lake', 'waterfall', 'cave',
    // Tham quan
    'tham quan', 'du lịch', 'điểm đến', 'attraction', 'sightseeing', 'tourist',
    'khu du lịch', 'khu tham quan',
    // Vui chơi giải trí
    'vui chơi', 'giải trí', 'khu vui', 'công viên nước', 'khu nghỉ dưỡng',
    'amusement', 'entertainment', 'theme park', 'resort', 'leisure',
    // Nghệ thuật, văn hóa
    'bảo tàng', 'gallery', 'triển lãm', 'nhà hát', 'nghệ thuật',
    'museum', 'art', 'theater', 'exhibition', 'gallery',
    // Chợ, phố cổ, làng nghề
    'chợ', 'phố cổ', 'làng', 'market', 'old town', 'village',
  ];

  Future<void> _loadNearbyPlaces({String? q}) async {
    setState(() => _isLoading = true);
    try {
      final lat = widget.referenceLat ?? 16.047079;
      final lng = widget.referenceLng ?? 108.206230;
      var places = await NearbyPlacesApi.getNearbyPlaces(
        lat,
        lng,
        excludeIds: widget.existingIds,
        preferCategory: (q != null && q.isNotEmpty) ? null : 'Tham quan',
        radius: q != null && q.isNotEmpty ? 50 : 30,
        limit: q != null && q.isNotEmpty ? 30 : 25,
        q: q,
      );

      // Khi không tìm kiếm: chỉ gợi ý địa điểm du lịch/tham quan nổi tiếng,
      // loại bỏ hoàn toàn nhà hàng, quán ăn, khách sạn, v.v.
      if (q == null || q.isEmpty) {
        places = places.where((p) {
          final cat = p.category.toLowerCase();
          return _tourismCategoryKeywords.any((kw) => cat.contains(kw));
        }).toList();
      }

      if (mounted) {
        places.sort((a, b) {
          if (b.rating != a.rating) {
            return b.rating.compareTo(a.rating);
          }
          return b.reviewCount.compareTo(a.reviewCount);
        });
        setState(() {
          _allPlaces = places;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final newQuery = _searchController.text.trim();
        if (_searchQuery != newQuery) {
          setState(() => _searchQuery = newQuery);
          _loadNearbyPlaces(q: newQuery);
        }
      }
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

  Future<void> _onSelect(NearbyPlaceModel place) async {
    Navigator.pop(context);
    await widget.onAdd(place);
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
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSizes.s32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_listItems.isEmpty)
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
                      onTap: () => _showFavoritePlacesDialog(context),
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

  void _showFavoritePlacesDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final usecase = sl<GetFavoritePlacesUseCase>();
      final allFavorites = await usecase.call(limit: 50);
      if (!mounted) return;
      Navigator.pop(context); // close loading

      final favorites = widget.destinationCity != null
          ? allFavorites.where((f) =>
              f.city.toLowerCase().contains(widget.destinationCity!.toLowerCase()) ||
              widget.destinationCity!.toLowerCase().contains(f.city.toLowerCase())
            ).toList()
          : allFavorites;

      if (favorites.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r20)),
            title: const Text('Danh mục yêu thích',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Text(
              widget.destinationCity != null
                  ? 'Bạn chưa lưu địa điểm yêu thích nào tại ${widget.destinationCity}.'
                  : 'Danh mục yêu thích của bạn đang trống.',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
        return;
      }

      showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r20)),
              title: const Text('Danh mục yêu thích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.only(top: 16),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final fav = favorites[index];
                    return GestureDetector(
                      onTap: () async {
                        final place = NearbyPlaceModel(
                          id: fav.id,
                          name: fav.name,
                          address: fav.city,
                          category: 'Yêu thích',
                          rating: fav.rating,
                          reviewCount: fav.reviewCount,
                          imageUrl: fav.image,
                          latitude: widget.referenceLat,
                          longitude: widget.referenceLng,
                        );
                        Navigator.pop(ctx);
                        await widget.onAdd(place);
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: NetImage(url: fav.image, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fav.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(fav.city, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onClose;

  const _Header({
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
                  'Thêm địa điểm',
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
                      hintText: 'Tìm kiếm địa điểm cần thêm...',
                      hintStyle: TextStyle(
                        color: AppColorsExt.textHint,
                        fontSize: 13,
                      ),
                      filled: false,
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
  final NearbyPlaceModel place;
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

                    ],
                  ),
                  const SizedBox(height: AppSizes.s4),
                  Wrap(
                    spacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColorsExt.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(place.category,
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColorsExt.success,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
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
                child: const Text('Thêm',
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
