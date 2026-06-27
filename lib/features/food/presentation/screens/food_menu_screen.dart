import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/food/domain/entities/food_item_entity.dart';
import 'package:travel_advisor_mobile/features/food/presentation/cubit/food_cubit.dart';

class FoodMenuScreen extends StatelessWidget {
  final String placeId;
  final String restaurantName;
  final String? itineraryDetailId;

  const FoodMenuScreen({
    super.key,
    required this.placeId,
    required this.restaurantName,
    this.itineraryDetailId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FoodCubit>()
        ..loadRestaurantMenu(
          placeId: placeId,
          restaurantName: restaurantName,
          itineraryDetailId: itineraryDetailId,
        ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: BlocBuilder<FoodCubit, FoodState>(
            buildWhen: (previous, current) =>
                previous.restaurantName != current.restaurantName,
            builder: (context, state) {
              final name =
                  state.restaurantName.isEmpty ? restaurantName : state.restaurantName;
              return Column(
                children: [
                  const Text(
                    'Khám phá ẩm thực',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'tại $name',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
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
        body: Column(
          children: [
            const _FoodFilters(),
            Expanded(
              child: BlocBuilder<FoodCubit, FoodState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errorMessage != null) {
                    return _FoodMenuMessage(
                      message: '[placeId: ${state.placeId}]\n\n${state.errorMessage!}',
                      actionLabel: 'Thử lại',
                      onAction: () =>
                          context.read<FoodCubit>().loadRestaurantMenu(
                                placeId: state.placeId,
                                restaurantName: state.restaurantName,
                                itineraryDetailId: state.itineraryDetailId,
                              ),
                    );
                  }

                  final items = state.filteredItems;
                  if (items.isEmpty) {
                    return const _FoodMenuMessage(
                      message: 'Địa điểm này chưa có món ăn khả dụng.',
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
        bottomNavigationBar: const _BottomCartBar(),
      ),
    );
  }
}

class _FoodFilters extends StatelessWidget {
  const _FoodFilters();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: BlocBuilder<FoodCubit, FoodState>(
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: FoodState.allCategoryLabel,
                  isActive:
                      state.selectedMainCategory == FoodState.allCategoryLabel,
                  onTap: () => context
                      .read<FoodCubit>()
                      .selectMainCategory(FoodState.allCategoryLabel),
                ),
                const SizedBox(width: 8),
                _FilterDropdownButton(
                  label: FoodState.mainCategoryLabel,
                  isActive:
                      state.selectedMainCategory == FoodState.mainCategoryLabel,
                  subCategories: state.subCategories,
                  selectedSubCategory: state.selectedSubCategory,
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label: FoodState.drinkCategoryLabel,
                  isActive:
                      state.selectedMainCategory == FoodState.drinkCategoryLabel,
                  onTap: () => context
                      .read<FoodCubit>()
                      .selectMainCategory(FoodState.drinkCategoryLabel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

class _FilterDropdownButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final List<String> subCategories;
  final String selectedSubCategory;

  const _FilterDropdownButton({
    required this.label,
    required this.isActive,
    required this.subCategories,
    required this.selectedSubCategory,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FoodCubit>();
    return PopupMenuButton<String>(
      onSelected: (value) {
        cubit.selectMainCategory(label);
        cubit.selectSubCategory(value);
      },
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => subCategories
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedSubCategory == item
                      ? AppColors.primary
                      : const Color(0xFF1E293B),
                  fontWeight: selectedSubCategory == item
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(
              selectedSubCategory == FoodState.allCategoryLabel
                  ? label
                  : selectedSubCategory,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2563EB),
            ),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NetImage(
              url: item.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(item.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.quantity > 0) ...[
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: () => context
                            .read<FoodCubit>()
                            .updateQuantity(item.id, -1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    _QuantityButton(
                      icon: Icons.add,
                      filled: true,
                      onTap: () =>
                          context.read<FoodCubit>().updateQuantity(item.id, 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _BottomCartBar extends StatelessWidget {
  const _BottomCartBar();

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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${state.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
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
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _formatCurrency(state.totalPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => _submitOrder(context, state.restaurantName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Đặt trước',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitOrder(BuildContext context, String restaurantName) async {
    try {
      await context.read<FoodCubit>().submitOrder();
      if (!context.mounted) return;

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
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đặt món: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

class _FoodMenuMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FoodMenuMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer}đ';
}
