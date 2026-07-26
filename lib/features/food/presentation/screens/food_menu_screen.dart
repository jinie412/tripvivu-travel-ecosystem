import 'package:dio/dio.dart';
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
        backgroundColor: AppColors.premiumBackground,
        appBar: AppBar(
          backgroundColor: AppColors.premiumBackground,
          elevation: 0,
          centerTitle: true,
          title: BlocBuilder<FoodCubit, FoodState>(
            buildWhen: (previous, current) =>
                previous.restaurantName != current.restaurantName,
            builder: (context, state) {
              final name = state.restaurantName.isEmpty
                  ? restaurantName
                  : state.restaurantName;
              return Column(
                children: [
                  const Text(
                    'Khám phá ẩm thực',
                    style: TextStyle(
                      color: AppColors.premiumNavy,
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
              color: AppColors.premiumNavy,
              size: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<FoodCubit, FoodState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errorMessage != null) {
                    return _FoodMenuMessage(
                      message:
                          '[placeId: ${state.placeId}]\n\n${state.errorMessage!}',
                      actionLabel: 'Thử lại',
                      onAction: () =>
                          context.read<FoodCubit>().loadRestaurantMenu(
                            placeId: state.placeId,
                            restaurantName: state.restaurantName,
                            itineraryDetailId: state.itineraryDetailId,
                          ),
                    );
                  }

                  final items = state.allItems;
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

class _FoodItemCard extends StatelessWidget {
  final FoodItemEntity item;

  const _FoodItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFoodDetails(context, item),
      child: Container(
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
                          onTap: () => context.read<FoodCubit>().updateQuantity(
                            item.id,
                            -1,
                          ),
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
                        onTap: () => context.read<FoodCubit>().updateQuantity(
                          item.id,
                          1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showFoodDetails(BuildContext context, FoodItemEntity item) {
  final menuContext = context;
  final cubit = context.read<FoodCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: BlocBuilder<FoodCubit, FoodState>(
          builder: (context, state) {
            final currentItem = state.allItems.firstWhere(
              (candidate) => candidate.id == item.id,
              orElse: () => item,
            );
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: NetImage(
                          url: currentItem.imageUrl,
                          width: double.infinity,
                          height: 240,
                          memCacheWidth: 1440,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              currentItem.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatCurrency(currentItem.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentItem.description.trim().isEmpty
                            ? 'Món ăn chưa có mô tả.'
                            : currentItem.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (currentItem.quantity == 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<FoodCubit>().updateQuantity(
                                currentItem.id,
                                1,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm món vào giỏ hàng'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Thêm vào giỏ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              onTap: () => context
                                  .read<FoodCubit>()
                                  .updateQuantity(currentItem.id, -1),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '${currentItem.quantity}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            _QuantityButton(
                              icon: Icons.add,
                              filled: true,
                              onTap: () => context
                                  .read<FoodCubit>()
                                  .updateQuantity(currentItem.id, 1),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  Future<void>.delayed(Duration.zero, () {
                                    if (menuContext.mounted) {
                                      _showCart(menuContext);
                                    }
                                  });
                                },
                                icon: const Icon(Icons.shopping_cart_outlined),
                                label: const Text('Xem giỏ hàng'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
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
              Expanded(
                child: InkWell(
                  onTap: () => _showCart(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                'Tổng cộng · Xem giỏ hàng',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
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
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => _submitOrder(context, state.restaurantName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
    // Bottom cart bar biến mất ngay khi submitOrder reset giỏ về 0. Không dùng
    // BuildContext của bar sau await vì element đó có thể đã bị unmount.
    final cubit = context.read<FoodCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await cubit.submitOrder();

      if (!messenger.mounted) return;
      messenger.showSnackBar(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      if (navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể đặt món: ${_orderErrorMessage(e)}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

Future<void> _showCart(BuildContext context) async {
  final cubit = context.read<FoodCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final submission = await Navigator.of(context).push<_CartSubmission>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FoodCartPage(initialState: cubit.state),
    ),
  );

  if (submission == null || cubit.isClosed) return;
  cubit.replaceQuantities(submission.quantities);
  await _submitOrderFromCart(
    cubit,
    messenger,
    submission.restaurantName,
    submission.notes,
  );
}

// Giữ tạm implementation cũ để đối chiếu; flow runtime không còn gọi modal
// này nữa. Có thể xóa sau khi xác nhận bản route mới ổn định trên thiết bị.
// ignore: unused_element
Future<void> _showCartLegacy(BuildContext context) async {
  final cubit = context.read<FoodCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final noteController = TextEditingController();
  String? submittedNotes;
  var isClosingCart = false;
  try {
    submittedNotes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocBuilder<FoodCubit, FoodState>(
          bloc: cubit,
          builder: (context, state) {
            final selectedItems = state.allItems
                .where((item) => item.quantity > 0)
                .toList();
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Giỏ hàng của bạn',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: selectedItems.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Giỏ hàng đang trống',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                itemCount: selectedItems.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 24),
                                itemBuilder: (context, index) {
                                  final item = selectedItems[index];
                                  return Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: NetImage(
                                          url: item.imageUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatCurrency(item.price),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.remove,
                                        onTap: () =>
                                            cubit.updateQuantity(item.id, -1),
                                      ),
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add,
                                        filled: true,
                                        onTap: () =>
                                            cubit.updateQuantity(item.id, 1),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: noteController,
                              minLines: 2,
                              maxLines: 4,
                              maxLength: 500,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Ghi chú cho quán',
                                hintText:
                                    'Ví dụ: Không cay, ít đá, không dùng hành...',
                                prefixIcon: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.primary,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.totalItems} món',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(state.totalPrice),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    state.isSubmitting || selectedItems.isEmpty
                                    ? null
                                    : () {
                                        // Chặn double tap: pop lần hai trong lúc
                                        // animation đóng sheet sẽ pop luôn màn
                                        // hình FoodMenu và close FoodCubit.
                                        if (isClosingCart) return;
                                        isClosingCart = true;
                                        // Đóng bàn phím và bottom sheet trước. API
                                        // chỉ được gọi sau khi route modal đã tháo
                                        // hoàn toàn khỏi widget tree.
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        Navigator.of(
                                          context,
                                        ).pop(noteController.text);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: state.isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Đặt món',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    noteController.dispose();
  }

  if (submittedNotes == null || cubit.isClosed) return;
  await _submitOrderFromCart(
    cubit,
    messenger,
    cubit.state.restaurantName,
    submittedNotes,
  );
}

class _CartSubmission {
  final String restaurantName;
  final String notes;
  final Map<String, int> quantities;

  const _CartSubmission({
    required this.restaurantName,
    required this.notes,
    required this.quantities,
  });
}

class _FoodCartPage extends StatefulWidget {
  final FoodState initialState;

  const _FoodCartPage({required this.initialState});

  @override
  State<_FoodCartPage> createState() => _FoodCartPageState();
}

class _FoodCartPageState extends State<_FoodCartPage> {
  late final TextEditingController _noteController;
  late List<FoodItemEntity> _items;
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _items = List<FoodItemEntity>.from(widget.initialState.allItems);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _updateQuantity(String id, int delta) {
    if (_isReturning) return;
    setState(() {
      _items = _items.map((item) {
        if (item.id != id) return item;
        return item.copyWith(quantity: (item.quantity + delta).clamp(0, 99));
      }).toList();
    });
  }

  void _returnSubmission() {
    if (_isReturning) return;
    _isReturning = true;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _CartSubmission(
        restaurantName: widget.initialState.restaurantName,
        notes: _noteController.text.trim(),
        quantities: {for (final item in _items) item.id: item.quantity},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          final selectedItems = _items
              .where((item) => item.quantity > 0)
              .toList();
          final totalItems = _items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          );
          final totalPrice = _items.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );
          return Column(
            children: [
              Expanded(
                child: selectedItems.isEmpty
                    ? const Center(child: Text('Giỏ hàng đang trống'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: selectedItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = selectedItems[index];
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: NetImage(
                                      url: item.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(item.price),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: () => _updateQuantity(item.id, -1),
                                  ),
                                  SizedBox(
                                    width: 34,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    filled: true,
                                    onTap: () => _updateQuantity(item.id, 1),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú cho quán',
                        hintText: 'Ví dụ: Không cay, ít đá, không dùng hành...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$totalItems món'),
                        Text(
                          _formatCurrency(totalPrice),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedItems.isEmpty || _isReturning
                            ? null
                            : _returnSubmission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Đặt món'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _submitOrderFromCart(
  FoodCubit cubit,
  ScaffoldMessengerState messenger,
  String restaurantName,
  String notes,
) async {
  try {
    await cubit.submitOrder(notes: notes.trim());
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đặt món thành công tại $restaurantName!'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  } catch (error) {
    if (!messenger.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Không thể đặt món: ${_orderErrorMessage(error)}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

String _orderErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is List) {
        return message.map((item) => item.toString()).join(', ');
      }
      if (message != null) return message.toString();
    }

    return 'Máy chủ không thể xử lý yêu cầu. Vui lòng thử lại.';
  }

  return error.toString().replaceFirst('Exception: ', '');
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
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
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
