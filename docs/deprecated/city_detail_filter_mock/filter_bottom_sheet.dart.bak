import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';

// ============================================================
// HELPER: Các widget con dùng chung trong 3 Bottom Sheet
// ============================================================

/// Tiêu đề section trong bottom sheet (ví dụ: "Loại hình", "Khoảng giá"...)
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
  late ActivityPriceType _priceType;
  late SortOption _sortOption;
  late String? _district;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Danh sách quận/huyện mẫu
  final List<String> _districts = [
    'Quận 1',
    'Quận 3',
    'Quận 5',
    'Quận 7',
    'Quận 10',
    'Quận 11',
    'Thủ Đức',
    'Bình Thạnh',
  ];

  @override
  void initState() {
    super.initState();
    _categories = Set.from(widget.currentFilter.categories);
    _priceType = widget.currentFilter.priceType;
    _sortOption = widget.currentFilter.sortOption;
    _district = widget.currentFilter.district;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _categories = {};
      _priceType = ActivityPriceType.all;
      _sortOption = SortOption.none;
      _district = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  String _getCategoryEmoji(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.culturalHistory:
        return '📜';
      case ActivityCategory.nature:
        return '🌲';
      case ActivityCategory.entertainment:
        return '🎭';
      case ActivityCategory.restaurant:
        return '🍽️';
      case ActivityCategory.attractions:
        return '📍';
      case ActivityCategory.cafe:
        return '☕';
      case ActivityCategory.photoSpot:
        return '📸';
      case ActivityCategory.museum:
        return '🏛️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
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
                  children: [
                    // --- Loại hình ---
                    const _SectionTitle('Loại hình địa điểm'),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bảo tàng, quán cà phê, v.v.',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                        fillColor: AppColors.inputFill,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category List
                    ...ActivityCategory.values
                        .where((cat) => cat.label.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .map((cat) {
                      final isSelected = _categories.contains(cat);
                      return ListTile(
                        leading: Text(
                          _getCategoryEmoji(cat),
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
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _categories.remove(cat);
                            } else {
                              _categories.add(cat);
                            }
                          });
                        },
                      );
                    }),

                    // --- Khoảng giá ---
                    const _SectionTitle('Khoảng giá'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ActivityPriceType.values.map((pt) {
                        final isSelected = _priceType == pt;
                        return ChoiceChip(
                          label: Text(pt.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _priceType = pt);
                          },
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
                    ),

                    // --- Khu vực ---
                    const _SectionTitle('Khu vực'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _district,
                          hint: const Text('Chọn quận/huyện'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả khu vực'),
                            ),
                            ..._districts.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                )),
                          ],
                          onChanged: (val) => setState(() => _district = val),
                        ),
                      ),
                    ),

                    // --- Sắp xếp theo ---
                    const _SectionTitle('Sắp xếp theo'),
                    ...[SortOption.none, SortOption.mostPopular, SortOption.highestRated]
                        .map((opt) => RadioListTile<SortOption>(
                              title: Text(
                                opt.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: opt,
                              groupValue: _sortOption,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                              },
                            )),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Nút "Đặt lại" + "Áp dụng"
              _ActionButtons(
                onReset: _reset,
                onApply: () {
                  widget.onApply(ActivityFilter(
                    categories: _categories,
                    priceType: _priceType,
                    district: _district,
                    sortOption: _sortOption,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
  late Set<RestaurantCuisine> _cuisines;
  late RestaurantPriceLevel _priceLevel;
  late Set<RestaurantAmenity> _amenities;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _cuisines = Set.from(widget.currentFilter.cuisines);
    _priceLevel = widget.currentFilter.priceLevel;
    _amenities = Set.from(widget.currentFilter.amenities);
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _cuisines = {};
      _priceLevel = RestaurantPriceLevel.all;
      _amenities = {};
      _sortOption = SortOption.none;
    });
  }

  String _getRestaurantAmenityEmoji(RestaurantAmenity amenity) {
    switch (amenity) {
      case RestaurantAmenity.parking:
        return '🅿️';
      case RestaurantAmenity.airCon:
        return '❄️';
      case RestaurantAmenity.kidFriendly:
        return '👶';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // --- Danh mục ---
                    const _SectionTitle('Danh mục'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RestaurantCuisine.values.map((c) {
                        final isSelected = _cuisines.contains(c);
                        return FilterChip(
                          label: Text(c.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _cuisines.add(c) : _cuisines.remove(c);
                            });
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
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
                    ),
                    // --- Mức giá ---
                    const _SectionTitle('Mức giá'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RestaurantPriceLevel.values.map((pl) {
                        final isSelected = _priceLevel == pl;
                        return ChoiceChip(
                          label: Text(pl.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _priceLevel = pl),
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
                    ),
                    // --- Tiện ích ---
                    const _SectionTitle('Tiện ích'),
                    ...RestaurantAmenity.values.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return ListTile(
                        leading: Text(
                          _getRestaurantAmenityEmoji(amenity),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          amenity.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _amenities.remove(amenity);
                            } else {
                              _amenities.add(amenity);
                            }
                          });
                        },
                      );
                    }),

                    // --- Sắp xếp theo ---
                    const _SectionTitle('Sắp xếp theo'),
                    ...SortOption.values
                        .map((opt) => RadioListTile<SortOption>(
                              title: Text(
                                opt.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: opt,
                              groupValue: _sortOption,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                              },
                            )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _ActionButtons(
                onReset: _reset,
                onApply: () {
                  widget.onApply(RestaurantFilter(
                    cuisines: _cuisines,
                    priceLevel: _priceLevel,
                    amenities: _amenities,
                    sortOption: _sortOption,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late Set<AccommodationType> _accommodationTypes;
  late Set<HotelAmenity> _amenities;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat.decimalPattern('vi_VN');
    _minPriceController = TextEditingController(
      text: widget.currentFilter.minPrice > 0 
        ? formatter.format(widget.currentFilter.minPrice.toInt()) 
        : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.currentFilter.maxPrice > 0 
        ? formatter.format(widget.currentFilter.maxPrice.toInt()) 
        : '',
    );
    _accommodationTypes = Set.from(widget.currentFilter.accommodationTypes);
    _amenities = Set.from(widget.currentFilter.amenities);
    _sortOption = widget.currentFilter.sortOption;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _accommodationTypes = {};
      _amenities = {};
      _sortOption = SortOption.none;
    });
  }

  String _getAccommodationEmoji(AccommodationType type) {
    switch (type) {
      case AccommodationType.hotel:
        return '🏨';
      case AccommodationType.homestay:
        return '🏡';
      case AccommodationType.resort:
        return '🏖️';
      case AccommodationType.apartment:
        return '🏢';
      case AccommodationType.guesthouse:
        return '🛌';
    }
  }

  String _getHotelAmenityEmoji(HotelAmenity amenity) {
    switch (amenity) {
      case HotelAmenity.pool:
        return '🏊';
      case HotelAmenity.freeWifi:
        return '📶';
      case HotelAmenity.breakfast:
        return '🍳';
      case HotelAmenity.gym:
        return '🏋️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // --- Khoảng giá (InputFields) ---
                    const _SectionTitle('Khoảng giá (VNĐ)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Từ',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              fillColor: AppColors.inputFill,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-', style: TextStyle(fontSize: 20, color: Colors.grey)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Đến',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              fillColor: AppColors.inputFill,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // --- Loại hình lưu trú ---
                    const _SectionTitle('Loại hình lưu trú'),
                    ...AccommodationType.values.map((type) {
                      final isSelected = _accommodationTypes.contains(type);
                      return ListTile(
                        leading: Text(
                          _getAccommodationEmoji(type),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _accommodationTypes.remove(type);
                            } else {
                              _accommodationTypes.add(type);
                            }
                          });
                        },
                      );
                    }),
                    // --- Tiện nghi ---
                    const _SectionTitle('Tiện nghi'),
                    ...HotelAmenity.values.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return ListTile(
                        leading: Text(
                          _getHotelAmenityEmoji(amenity),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          amenity.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _amenities.remove(amenity);
                            } else {
                              _amenities.add(amenity);
                            }
                          });
                        },
                      );
                    }),
                    // --- Sắp xếp theo ---
                    const _SectionTitle('Sắp xếp theo'),
                    ...SortOption.values
                        .map((opt) => RadioListTile<SortOption>(
                              title: Text(
                                opt.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: opt,
                              groupValue: _sortOption,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                              },
                            )),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              _ActionButtons(
                onReset: _reset,
                onApply: () {
                  // Loại bỏ dấu phân cách trước khi parse (ví dụ: "1.000.000" -> "1000000")
                  final minStr = _minPriceController.text.replaceAll(RegExp(r'\D'), '');
                  final maxStr = _maxPriceController.text.replaceAll(RegExp(r'\D'), '');
                  
                  final minPrice = double.tryParse(minStr) ?? 0;
                  final maxPrice = double.tryParse(maxStr) ?? 0;
                  
                  widget.onApply(HotelFilter(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    accommodationTypes: _accommodationTypes,
                    amenities: _amenities,
                    sortOption: _sortOption,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
