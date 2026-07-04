import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';

// ============================================================
// Bộ lọc City Detail — chỉ gồm các filter có DỮ LIỆU THẬT từ
// backend /explore/cities/:id/overview (loại hình activity,
// đánh giá, trạng thái mở cửa, sắp xếp).
// UI mock cũ (khoảng giá, quận/huyện, món ăn, tiện ích, loại
// lưu trú...) được backup tại docs/deprecated/city_detail_filter_mock/.
// ============================================================

// ============================================================
// HELPER: Các widget con dùng chung trong 3 Bottom Sheet
// ============================================================

/// Tiêu đề section trong bottom sheet (ví dụ: "Loại hình", "Đánh giá"...)
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Nút "Áp dụng" + "Đặt lại" ở cuối bottom sheet
class _ActionButtons extends StatelessWidget {
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _ActionButtons({required this.onApply, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Nút "Đặt lại"
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Đặt lại',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút "Áp dụng"
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung bottom sheet chung: handle + tiêu đề "Bộ lọc" + nội dung cuộn + nút.
class _FilterSheetScaffold extends StatelessWidget {
  final List<Widget> children;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final double initialChildSize;

  const _FilterSheetScaffold({
    required this.children,
    required this.onApply,
    required this.onReset,
    this.initialChildSize = 0.62,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Tiêu đề "Bộ lọc"
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Nội dung cuộn
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [...children, const SizedBox(height: 20)],
                ),
              ),
              // Nút "Đặt lại" + "Áp dụng"
              _ActionButtons(onReset: onReset, onApply: onApply),
            ],
          ),
        );
      },
    );
  }
}

/// Chip chọn 1 (đánh giá tối thiểu, sắp xếp).
class _SingleChoiceChips<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _SingleChoiceChips({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        return ChoiceChip(
          label: Text(labelOf(option)),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onSelected(option),
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          backgroundColor: AppColors.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
            ),
          ),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

/// Switch "Chỉ hiện đang mở cửa".
class _OpenNowSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OpenNowSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: const Text(
        'Chỉ hiện địa điểm đang mở cửa',
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

// ============================================================
// BOTTOM SHEET 1: Hoạt động tham quan
// ============================================================

class ActivityFilterSheet extends StatefulWidget {
  final ActivityFilter currentFilter;
  final ValueChanged<ActivityFilter> onApply;

  const ActivityFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late Set<ActivityCategory> _categories;
  late MinRating _minRating;
  late bool _openNowOnly;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _categories = Set.from(widget.currentFilter.categories);
    _minRating = widget.currentFilter.minRating;
    _openNowOnly = widget.currentFilter.openNowOnly;
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _categories = {};
      _minRating = MinRating.all;
      _openNowOnly = false;
      _sortOption = SortOption.none;
    });
  }

  String _categoryEmoji(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.attractions:
        return '📍';
      case ActivityCategory.culturalHistory:
        return '🏛️';
      case ActivityCategory.entertainment:
        return '🎡';
      case ActivityCategory.nature:
        return '🌿';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetScaffold(
      initialChildSize: 0.72,
      onReset: _reset,
      onApply: () {
        widget.onApply(ActivityFilter(
          categories: _categories,
          minRating: _minRating,
          openNowOnly: _openNowOnly,
          sortOption: _sortOption,
        ));
        Navigator.pop(context);
      },
      children: [
        // --- Loại hình (chọn nhiều) ---
        const _SectionTitle('Loại hình địa điểm'),
        ...ActivityCategory.values.map((cat) {
          final isSelected = _categories.contains(cat);
          return ListTile(
            leading: Text(
              _categoryEmoji(cat),
              style: const TextStyle(fontSize: 22),
            ),
            title: Text(
              cat.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 20)
                : null,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onTap: () {
              setState(() {
                isSelected ? _categories.remove(cat) : _categories.add(cat);
              });
            },
          );
        }),

        // --- Đánh giá tối thiểu ---
        const _SectionTitle('Đánh giá'),
        _SingleChoiceChips<MinRating>(
          options: MinRating.values,
          selected: _minRating,
          labelOf: (r) => r.label,
          onSelected: (r) => setState(() => _minRating = r),
        ),

        // --- Trạng thái mở cửa ---
        const _SectionTitle('Trạng thái'),
        _OpenNowSwitch(
          value: _openNowOnly,
          onChanged: (v) => setState(() => _openNowOnly = v),
        ),

        // --- Sắp xếp theo ---
        const _SectionTitle('Sắp xếp theo'),
        _SingleChoiceChips<SortOption>(
          options: SortOption.values,
          selected: _sortOption,
          labelOf: (o) => o.label,
          onSelected: (o) => setState(() => _sortOption = o),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM SHEET 2: Nhà hàng
// ============================================================

class RestaurantFilterSheet extends StatefulWidget {
  final RestaurantFilter currentFilter;
  final ValueChanged<RestaurantFilter> onApply;

  const RestaurantFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<RestaurantFilterSheet> createState() => _RestaurantFilterSheetState();
}

class _RestaurantFilterSheetState extends State<RestaurantFilterSheet> {
  late MinRating _minRating;
  late bool _openNowOnly;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _minRating = widget.currentFilter.minRating;
    _openNowOnly = widget.currentFilter.openNowOnly;
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _minRating = MinRating.all;
      _openNowOnly = false;
      _sortOption = SortOption.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetScaffold(
      onReset: _reset,
      onApply: () {
        widget.onApply(RestaurantFilter(
          minRating: _minRating,
          openNowOnly: _openNowOnly,
          sortOption: _sortOption,
        ));
        Navigator.pop(context);
      },
      children: [
        // --- Đánh giá tối thiểu ---
        const _SectionTitle('Đánh giá'),
        _SingleChoiceChips<MinRating>(
          options: MinRating.values,
          selected: _minRating,
          labelOf: (r) => r.label,
          onSelected: (r) => setState(() => _minRating = r),
        ),

        // --- Trạng thái mở cửa ---
        const _SectionTitle('Trạng thái'),
        _OpenNowSwitch(
          value: _openNowOnly,
          onChanged: (v) => setState(() => _openNowOnly = v),
        ),

        // --- Sắp xếp theo ---
        const _SectionTitle('Sắp xếp theo'),
        _SingleChoiceChips<SortOption>(
          options: SortOption.values,
          selected: _sortOption,
          labelOf: (o) => o.label,
          onSelected: (o) => setState(() => _sortOption = o),
        ),
      ],
    );
  }
}

// ============================================================
// BOTTOM SHEET 3: Khách sạn
// ============================================================

class HotelFilterSheet extends StatefulWidget {
  final HotelFilter currentFilter;
  final ValueChanged<HotelFilter> onApply;

  const HotelFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends State<HotelFilterSheet> {
  late MinRating _minRating;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _minRating = widget.currentFilter.minRating;
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _minRating = MinRating.all;
      _sortOption = SortOption.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _FilterSheetScaffold(
      initialChildSize: 0.5,
      onReset: _reset,
      onApply: () {
        widget.onApply(HotelFilter(
          minRating: _minRating,
          sortOption: _sortOption,
        ));
        Navigator.pop(context);
      },
      children: [
        // --- Đánh giá tối thiểu ---
        const _SectionTitle('Đánh giá'),
        _SingleChoiceChips<MinRating>(
          options: MinRating.values,
          selected: _minRating,
          labelOf: (r) => r.label,
          onSelected: (r) => setState(() => _minRating = r),
        ),

        // --- Sắp xếp theo ---
        const _SectionTitle('Sắp xếp theo'),
        _SingleChoiceChips<SortOption>(
          options: SortOption.values,
          selected: _sortOption,
          labelOf: (o) => o.label,
          onSelected: (o) => setState(() => _sortOption = o),
        ),
      ],
    );
  }
}
