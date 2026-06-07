import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

import '../../data/datasources/nearby_places_api.dart';
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

  const AddPlaceSheet({
    super.key,
    required this.onAdd,
    this.referenceLat,
    this.referenceLng,
    this.existingIds,
    this.visitDate,
    this.proposedVisitTime,
  });

  static void show(
    BuildContext context, {
    required Function(NearbyPlaceModel place) onAdd,
    double? referenceLat,
    double? referenceLng,
    List<String>? existingIds,
    DateTime? visitDate,
    String? proposedVisitTime,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPlaceSheet(
        onAdd: onAdd,
        referenceLat: referenceLat,
        referenceLng: referenceLng,
        existingIds: existingIds,
        visitDate: visitDate,
        proposedVisitTime: proposedVisitTime,
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
  
  List<NearbyPlaceModel> get _listItems {
    return _allPlaces.where((p) {
      return _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final lat = widget.referenceLat ?? 16.047079;
      final lng = widget.referenceLng ?? 108.206230;
      final places = await NearbyPlacesApi.getNearbyPlaces(
        lat,
        lng,
        excludeIds: widget.existingIds,
        radius: 10,
      );

      if (mounted) {
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

  void _onSelect(NearbyPlaceModel place) async {
    // Validate opening hours dựa theo ngày tham quan và giờ dự kiến
    if (place.openHourCompressed != null && widget.proposedVisitTime != null) {
      final slot = _openSlotForDay(
          place.openHourCompressed!, widget.visitDate ?? DateTime.now());
      final hoursStr = slot != null ? '${slot.$1} – ${slot.$2}' : 'không xác định';
      final outside = slot != null
          ? !_isWithinHours(widget.proposedVisitTime!, slot.$1, slot.$2)
          : false;
      if (outside) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r16)),
            title: const Text('Ngoài giờ mở cửa',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            content: Text(
              '”${place.name}” mở cửa từ $hoursStr.\n\n'
              'Thời gian tham quan dự kiến ${widget.proposedVisitTime} '
              'nằm ngoài khung giờ mở cửa. Bạn có muốn tiếp tục thêm không?',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsExt.warning,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r8)),
                  elevation: 0,
                ),
                child: const Text('Tiếp tục thêm',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }

    widget.onAdd(place);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${place.name}" vào lịch trình'),
        backgroundColor: AppColorsExt.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r12)),
      ),
    );
  }

  /// Trả về (openTime, closeTime) dạng "HH:mm" cho ngày [date], hoặc null nếu không tìm thấy.
  (String, String)? _openSlotForDay(String jsonStr, DateTime date) {
    try {
      const dayNames = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      final dayName = dayNames[date.weekday - 1];
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final slots = map[dayName] as List?;
      if (slots == null || slots.isEmpty) return null;
      final slot = slots[0] as List;
      // "07:00:00" -> "07:00"
      final open = (slot[0] as String).substring(0, 5);
      final close = (slot[1] as String).substring(0, 5);
      return (open, close);
    } catch (_) {
      return null;
    }
  }

  bool _isWithinHours(String time, String openTime, String closeTime) {
    int toMins(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }
    final t = toMins(time);
    final o = toMins(openTime);
    final c = toMins(closeTime);
    return c >= o ? (t >= o && t <= c) : (t >= o || t <= c);
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
              'Nhập tên địa điểm muốn thêm vào lịch trình',
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
                widget.onAdd(NearbyPlaceModel(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  address: '',
                  category: 'Tham quan',
                  rating: 0,
                  reviewCount: 0,
                  imageUrl: 'https://placehold.co/1080x720?text=New+Place',
                ));
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
