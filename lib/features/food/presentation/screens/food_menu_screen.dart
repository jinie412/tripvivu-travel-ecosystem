import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/net_image.dart';
import '../cubit/food_cubit.dart';
import '../../domain/entities/food_item_entity.dart';

class FoodMenuScreen extends StatelessWidget {
  final String restaurantName;
  const FoodMenuScreen({super.key, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FoodCubit()..loadRestaurantMenu(restaurantName),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'Khám phá ẩm thực',
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'tại $restaurantName',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Filters ────────────────────────────────────────────────────────
            _buildFilters(),

            // ── Menu List ──────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<FoodCubit, FoodState>(
                builder: (context, state) {
                   final items = state.filteredItems;
                   if (items.isEmpty) {
                      return const Center(child: Text('Không tìm thấy món ăn phù hợp.'));
                   }
                   return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _FoodItemCard(item: items[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        // ── Bottom Cart Bar ──────────────────────────────────────────────────
        bottomNavigationBar: _BottomCartBar(),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: BlocBuilder<FoodCubit, FoodState>(
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(context, 'Tất cả', state.selectedMainCategory == 'Tất cả'),
                const SizedBox(width: 8),
                _filterDropdownChip(context, 'Món chính', state.selectedMainCategory == 'Món chính', state.subCategories, state.selectedSubCategory),
                const SizedBox(width: 8),
                _filterChip(context, 'Đồ uống', state.selectedMainCategory == 'Đồ uống'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, bool isActive) {
    return GestureDetector(
      onTap: () => context.read<FoodCubit>().selectMainCategory(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Widget _filterDropdownChip(BuildContext context, String label, bool isActive, List<String> subs, String selectedSub) {
    final cubit = context.read<FoodCubit>();
    return PopupMenuButton<String>(
      onSelected: (value) {
         cubit.selectMainCategory(label);
         cubit.selectSubCategory(value);
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => subs.map((s) => PopupMenuItem(
        value: s,
        child: Text(s, style: TextStyle(fontSize: 14, color: selectedSub == s ? AppColors.primary : const Color(0xFF1E293B), fontWeight: selectedSub == s ? FontWeight.bold : FontWeight.normal)),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              selectedSub == 'Tất cả' ? label : selectedSub,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 18, color: isActive ? Colors.white : const Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItemEntity item;
  const _FoodItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NetImage(url: item.imageUrl, width: 88, height: 88, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${(item.price / 1000).toStringAsFixed(0)}.000đ',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.quantity > 0) ...[
                      _qtyButton(context, Icons.remove, () => context.read<FoodCubit>().updateQuantity(item.id, -1)),
                      const SizedBox(width: 12),
                      Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                    ],
                    _qtyButton(context, Icons.add, () => context.read<FoodCubit>().updateQuantity(item.id, 1), filled: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(BuildContext context, IconData icon, VoidCallback onTap, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: filled ? Colors.white : const Color(0xFF64748B)),
      ),
    );
  }
}

class _BottomCartBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodCubit, FoodState>(
      builder: (context, state) {
        if (state.totalItems == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 32, color: Color(0xFF2563EB)),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '${state.totalItems}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng cộng', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(
                      '${(state.totalPrice / 1000).toStringAsFixed(0)}.000đ',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  final restaurantName = state.restaurantName;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Đặt món thành công! Bạn có thể nhận món tại $restaurantName ngay khi vừa đến nơi.',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Đặt trước', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
