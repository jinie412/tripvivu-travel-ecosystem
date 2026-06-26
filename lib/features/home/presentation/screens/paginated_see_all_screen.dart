import 'dart:async';

import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';

class SortOption<T> {
  final String label;
  final int Function(T a, T b) compare;

  const SortOption({required this.label, required this.compare});
}

class PaginatedSeeAllScreen<T> extends StatefulWidget {
  final String title;
  final int pageSize;
  final Future<List<T>> Function(int page, int limit) pageLoader;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final List<T> initialItems;
  final Stream<FavoriteChangedEvent>? favoriteChanges;
  final T Function(T item, FavoriteChangedEvent event)? favoriteMapper;
  // filter / sort
  final String? Function(T item)? cityExtractor;
  final String? Function(T item)? travelTypeExtractor;
  final List<SortOption<T>>? sortOptions;
  final double separatorHeight;

  const PaginatedSeeAllScreen({
    super.key,
    required this.title,
    required this.pageLoader,
    required this.itemBuilder,
    this.pageSize = 10,
    this.emptyMessage = 'Không có dữ liệu để hiển thị.',
    this.initialItems = const [],
    this.favoriteChanges,
    this.favoriteMapper,
    this.cityExtractor,
    this.travelTypeExtractor,
    this.sortOptions,
    this.separatorHeight = 20,
  });

  @override
  State<PaginatedSeeAllScreen<T>> createState() =>
      _PaginatedSeeAllScreenState<T>();
}

class _PaginatedSeeAllScreenState<T>
    extends State<PaginatedSeeAllScreen<T>> {
  final ScrollController _scrollController = ScrollController();
  final List<T> _allItems = [];
  StreamSubscription<FavoriteChangedEvent>? _favoriteSubscription;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;

  // active filters / sort
  String? _selectedCity;
  String? _selectedTravelType;
  int _selectedSortIndex = -1;

  List<String> get _availableCities {
    final extractor = widget.cityExtractor;
    if (extractor == null) return const [];
    final seen = <String>{};
    final result = <String>[];
    for (final item in _allItems) {
      final v = extractor(item);
      if (v != null && v.isNotEmpty && seen.add(v)) result.add(v);
    }
    result.sort();
    return result;
  }

  List<String> get _availableTravelTypes {
    final extractor = widget.travelTypeExtractor;
    if (extractor == null) return const [];
    final seen = <String>{};
    final result = <String>[];
    for (final item in _allItems) {
      final v = extractor(item);
      if (v != null && v.isNotEmpty && seen.add(v)) result.add(v);
    }
    result.sort();
    return result;
  }

  List<T> get _displayItems {
    var items = List<T>.from(_allItems);
    final cityExt = widget.cityExtractor;
    if (cityExt != null && _selectedCity != null) {
      items = items.where((i) => cityExt(i) == _selectedCity).toList();
    }
    final typeExt = widget.travelTypeExtractor;
    if (typeExt != null && _selectedTravelType != null) {
      items =
          items.where((i) => typeExt(i) == _selectedTravelType).toList();
    }
    final sorts = widget.sortOptions;
    if (sorts != null &&
        _selectedSortIndex >= 0 &&
        _selectedSortIndex < sorts.length) {
      items.sort(sorts[_selectedSortIndex].compare);
    }
    return items;
  }

  bool get _hasActiveFilter =>
      _selectedCity != null ||
      _selectedTravelType != null ||
      _selectedSortIndex >= 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _favoriteSubscription =
        widget.favoriteChanges?.listen(_onFavoriteChanged);
    if (widget.initialItems.isNotEmpty) {
      _allItems.addAll(widget.initialItems);
      _isInitialLoading = false;
      _refreshPage1();
    } else {
      _loadFirstPage();
    }
  }

  Future<void> _refreshPage1() async {
    try {
      final items = await widget.pageLoader(1, widget.pageSize);
      if (!mounted) return;
      if (items.isEmpty && _allItems.isNotEmpty) {
        setState(() => _hasMore = false);
        return;
      }
      setState(() {
        _allItems
          ..clear()
          ..addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage = 2;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasMore = false);
    }
  }

  void _onFavoriteChanged(FavoriteChangedEvent event) {
    final mapper = widget.favoriteMapper;
    if (!mounted || mapper == null || _allItems.isEmpty) return;
    setState(() {
      for (var i = 0; i < _allItems.length; i++) {
        _allItems[i] = mapper(_allItems[i], event);
      }
    });
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_hasMore ||
        _isLoadingMore ||
        _isInitialLoading) {
      return;
    }
    final threshold =
        _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _hasMore = true;
      _currentPage = 1;
      _allItems.clear();
    });
    try {
      final items = await widget.pageLoader(_currentPage, widget.pageSize);
      if (!mounted) return;
      setState(() {
        _allItems.addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage = 2;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });
    try {
      final items = await widget.pageLoader(_currentPage, widget.pageSize);
      if (!mounted) return;
      setState(() {
        _allItems.addAll(items);
        _hasMore = items.length >= widget.pageSize;
        _currentPage += 1;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _openFilterSheet() {
    final cities = _availableCities;
    final travelTypes = _availableTravelTypes;
    final sorts = widget.sortOptions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSortSheet<T>(
        cities: cities,
        travelTypes: travelTypes,
        sortOptions: sorts,
        selectedCity: _selectedCity,
        selectedTravelType: _selectedTravelType,
        selectedSortIndex: _selectedSortIndex,
        onApply: (city, travelType, sortIndex) {
          setState(() {
            _selectedCity = city;
            _selectedTravelType = travelType;
            _selectedSortIndex = sortIndex;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayItems;
    final hasFilterOrSort = widget.cityExtractor != null ||
        widget.travelTypeExtractor != null ||
        (widget.sortOptions?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasFilterOrSort)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hasActiveFilter
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: _hasActiveFilter
                                ? AppColors.primary
                                : Colors.white,
                            size: 22,
                          ),
                          onPressed: _openFilterSheet,
                        ),
                      ),
                      if (_hasActiveFilter)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: Builder(builder: (context) {
              if (_isInitialLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_errorMessage != null && _allItems.isEmpty) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadFirstPage,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (display.isEmpty) {
                return Center(
                  child: Text(
                    _hasActiveFilter
                        ? 'Không có kết quả phù hợp với bộ lọc'
                        : widget.emptyMessage,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }
              return ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
                itemCount: display.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (_, index) =>
                    index == display.length - 1 && _isLoadingMore
                        ? const SizedBox(height: 12)
                        : SizedBox(height: widget.separatorHeight),
                itemBuilder: (context, index) {
                  if (index >= display.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return widget.itemBuilder(context, display[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Filter + Sort bottom sheet ─────────────────────────────────────────────

class _FilterSortSheet<T> extends StatefulWidget {
  final List<String> cities;
  final List<String> travelTypes;
  final List<SortOption<T>>? sortOptions;
  final String? selectedCity;
  final String? selectedTravelType;
  final int selectedSortIndex;
  final void Function(String? city, String? travelType, int sortIndex) onApply;

  const _FilterSortSheet({
    required this.cities,
    required this.travelTypes,
    required this.sortOptions,
    required this.selectedCity,
    required this.selectedTravelType,
    required this.selectedSortIndex,
    required this.onApply,
  });

  @override
  State<_FilterSortSheet<T>> createState() => _FilterSortSheetState<T>();
}

class _FilterSortSheetState<T> extends State<_FilterSortSheet<T>> {
  String? _city;
  String? _travelType;
  int _sortIndex = -1;

  @override
  void initState() {
    super.initState();
    _city = widget.selectedCity;
    _travelType = widget.selectedTravelType;
    _sortIndex = widget.selectedSortIndex;
  }

  bool get _hasFilter =>
      _city != null || _travelType != null || _sortIndex >= 0;

  void _reset() {
    setState(() {
      _city = null;
      _travelType = null;
      _sortIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Lọc & Sắp xếp',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_hasFilter)
                    GestureDetector(
                      onTap: _reset,
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City filter
                  if (widget.cities.isNotEmpty) ...[
                    _sectionLabel('Tỉnh / Thành phố'),
                    const SizedBox(height: 8),
                    _dropdownField<String?>(
                      value: _city,
                      hint: 'Tất cả',
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Tất cả')),
                        ...widget.cities.map((c) =>
                            DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) => setState(() => _city = v),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Travel type filter (itineraries)
                  if (widget.travelTypes.isNotEmpty) ...[
                    _sectionLabel('Loại hình du lịch'),
                    const SizedBox(height: 8),
                    _dropdownField<String?>(
                      value: _travelType,
                      hint: 'Tất cả',
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Tất cả')),
                        ...widget.travelTypes.map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) => setState(() => _travelType = v),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sort
                  if (widget.sortOptions != null &&
                      widget.sortOptions!.isNotEmpty) ...[
                    _sectionLabel('Sắp xếp theo'),
                    const SizedBox(height: 8),
                    _dropdownField<int>(
                      value: _sortIndex,
                      hint: 'Mặc định',
                      items: [
                        const DropdownMenuItem(
                            value: -1, child: Text('Mặc định')),
                        ...List.generate(
                          widget.sortOptions!.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(widget.sortOptions![i].label),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _sortIndex = v ?? -1),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            // Apply button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_city, _travelType, _sortIndex);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );

  Widget _dropdownField<V>({
    required V value,
    required String hint,
    required List<DropdownMenuItem<V>> items,
    required ValueChanged<V?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<V>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey),
        ),
      ),
    );
  }
}
