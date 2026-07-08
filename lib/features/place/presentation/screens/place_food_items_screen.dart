import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/place/data/datasources/place_datasource.dart';
import 'package:travel_advisor_mobile/features/place/domain/entities/place_food_item_entity.dart';

class PlaceFoodItemsScreen extends StatefulWidget {
  final String placeId;
  final String placeName;

  const PlaceFoodItemsScreen({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<PlaceFoodItemsScreen> createState() => _PlaceFoodItemsScreenState();
}

class _PlaceFoodItemsScreenState extends State<PlaceFoodItemsScreen> {
  final _scrollController = ScrollController();
  final _items = <PlaceFoodItemEntity>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  int _pages = 0;

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
      final data = await sl<PlaceDataSource>().getPlaceFoodItems(
        widget.placeId,
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
        _pages = data.pages;
        _limit = data.limit;
        _page = data.page + 1;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Thực đơn',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              widget.placeName,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
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
                children: const [
                  SizedBox(height: 120),
                  _StateMessage(message: 'Địa điểm này chưa có món ăn khả dụng.'),
                ],
              );
            }

            return ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _items.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, index) => index == _items.length - 1
                  ? const SizedBox(height: 12)
                  : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _FoodItemCard(item: _items[index]);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _SummaryBar(total: _total),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final PlaceFoodItemEntity item;

  const _FoodItemCard({required this.item});

  static final _priceFormat = NumberFormat.decimalPattern('vi_VN');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: NetImage(
              url: item.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isNotEmpty ? item.description : 'Chưa có mô tả',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.price > 0
                      ? '${_priceFormat.format(item.price.round())} đ'
                      : 'Liên hệ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
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

  const _SummaryBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Text(
        total > 0 ? '$total món ăn khả dụng' : 'Chưa có món ăn khả dụng',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
