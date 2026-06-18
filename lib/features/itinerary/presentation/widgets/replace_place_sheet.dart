import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

import '../../data/datasources/nearby_places_api.dart';


// ─── Main Widget ──────────────────────────────────────────────────────────────

class ReplacePlaceSheet extends StatefulWidget {
  final ItineraryActivityEntity currentActivity;
  final Function(NearbyPlaceModel place) onReplace;
  final List<String>? existingIds;

  const ReplacePlaceSheet({
    super.key,
    required this.currentActivity,
    required this.onReplace,
    this.existingIds,
  });

  static void show(
    BuildContext context, {
    required ItineraryActivityEntity activity,
    required Function(NearbyPlaceModel place) onReplace,
    List<String>? existingIds,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReplacePlaceSheet(
        currentActivity: activity,
        onReplace: onReplace,
        existingIds: existingIds,
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

  bool _isLoading = true;
  List<NearbyPlaceModel> _sameCategoryPlaces = [];
  List<NearbyPlaceModel> _otherPlaces = [];

  List<NearbyPlaceModel> _applySearch(List<NearbyPlaceModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  List<NearbyPlaceModel> get _filteredSame => _applySearch(_sameCategoryPlaces);
  List<NearbyPlaceModel> get _filteredOthers => _applySearch(_otherPlaces);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final lat = widget.currentActivity.latitude ?? 16.047079;
      final lng = widget.currentActivity.longitude ?? 108.206230;
      final places = await NearbyPlacesApi.getNearbyPlaces(
        lat,
        lng,
        excludeIds: widget.existingIds,
        preferCategory: widget.currentActivity.category,
        radius: 10,
      );

      if (mounted) {
        setState(() {
          _sameCategoryPlaces = places.where((p) => p.isSameCategory).toList();
          _otherPlaces = places.where((p) => !p.isSameCategory).toList();
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
    // Validate opening hours dựa theo giờ hiện tại của activity đang thay thế
    if (place.openHourCompressed != null) {
      final slot = _openSlotForDay(
          place.openHourCompressed!, DateTime.now());
      final hoursStr = slot != null ? '${slot.$1} – ${slot.$2}' : 'không xác định';
      final outside = slot != null
          ? !_isWithinHours(widget.currentActivity.startTime, slot.$1, slot.$2)
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
              '"${place.name}" mở cửa từ $hoursStr.\n\n'
              'Thời gian tham quan dự kiến ${widget.currentActivity.startTime} '
              'nằm ngoài khung giờ mở cửa. Bạn có muốn tiếp tục thay thế không?',
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
                child: const Text('Tiếp tục thay thế',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }

    widget.onReplace(place);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã thay thế bằng "${place.name}"'),
        backgroundColor: AppColorsExt.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r12)),
      ),
    );
  }

  (String, String)? _openSlotForDay(String jsonStr, DateTime date) {
    try {
      const dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final slots = map[dayNames[date.weekday - 1]] as List?;
      if (slots == null || slots.isEmpty) return null;
      final slot = slots[0] as List;
      return ((slot[0] as String).substring(0, 5), (slot[1] as String).substring(0, 5));
    } catch (_) { return null; }
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

  Widget _buildList(List<NearbyPlaceModel> places) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.s12),
      itemBuilder: (_, i) => _ListCard(
        place: places[i],
        onSelect: () => _onSelect(places[i]),
        fmt: _fmt,
        fmtPrice: _fmtPrice,
        tagColor: _tagColor,
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
                child: Builder(builder: (_) {
                  final samePlaces = _filteredSame;
                  final otherPlaces = _filteredOthers;
                  final totalSearch = samePlaces.length + otherPlaces.length;

                  return ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(AppSizes.s32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_searchQuery.isNotEmpty) ...[
                        _SectionTitle(
                          icon: Icons.search_rounded,
                          iconColor: AppColors.primary,
                          title: 'Kết quả tìm kiếm ($totalSearch)',
                        ),
                        if (totalSearch == 0)
                          const _EmptyState(isSearching: true)
                        else
                          _buildList([...samePlaces, ...otherPlaces]),
                      ] else ...[
                        if (samePlaces.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: AppColorsExt.warning,
                            title: 'Cùng loại: ${widget.currentActivity.category}',
                          ),
                          _buildList(samePlaces),
                        ],
                        if (otherPlaces.isNotEmpty) ...[
                          _SectionTitle(
                            icon: Icons.location_on_rounded,
                            iconColor: AppColors.primary,
                            title: 'Gợi ý gần đây',
                          ),
                          _buildList(otherPlaces),
                        ],
                        if (samePlaces.isEmpty && otherPlaces.isEmpty)
                          const _EmptyState(isSearching: false),
                      ],
                      const SizedBox(height: AppSizes.s20),
                      _ManualAddButton(onTap: () => _showManualAddDialog(context)),
                      const SizedBox(height: AppSizes.s32),
                    ],
                  );
                }),
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
                widget.onReplace(NearbyPlaceModel(
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
