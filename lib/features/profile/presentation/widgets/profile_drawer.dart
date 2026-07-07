import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/features/auth/presentation/screens/login_screen.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/home/data/datasources/tourist_more_info_datasource.dart';
import 'package:travel_advisor_mobile/features/home/data/models/tourist_order_model.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/activity_item_entity.dart';
import 'package:travel_advisor_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/review_catalog_screen.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: BlocProvider(
        create: (_) => sl<ProfileCubit>()..loadProfile(includeActivities: true),
        child: const _DrawerContent(),
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileError) {
          return Center(child: Text(state.message));
        }
        if (state is ProfileLoaded) {
          return _buildBody(context, state.profile, state.activities);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileEntity profile,
    List<ActivityItemEntity> activities,
  ) {
    final itineraryItems = const <ActivityItemEntity>[];
    final ratedItems = activities
        .where((a) => a.type == ActivityType.rated)
        .toList();
    final pendingItems = activities
        .where((a) => a.type == ActivityType.reviewPending)
        .toList();
    final orderDataSource = TouristMoreInfoDataSource(sl<DioClient>());

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _ProfileDrawerAvatar(avatarUrl: profile.avatarUrl),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.membershipTier,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),

            // Lich trinh
            const _PillHeader(
              icon: Icons.calendar_today_outlined,
              label: 'LỊCH TRÌNH & ĐỊA ĐIỂM',
            ),
            const SizedBox.shrink(),
            ...itineraryItems.map(
              (e) => _ActivityTile(
                item: e,
                icon: Icons.bed_outlined,
                isImage: false,
              ),
            ),
            const SizedBox(height: 16),

            // Danh gia
            const _PillHeader(
              icon: Icons.star_border_rounded,
              label: 'ĐÁNH GIÁ LỊCH TRÌNH & ĐỊA ĐIỂM',
            ),
            const SizedBox.shrink(),
            const _SectionSubHeader(label: 'Đã đánh giá'),
            if (ratedItems.isEmpty)
              const _SectionEmptyHint(label: 'Bạn chưa có đánh giá nào')
            else
              ...ratedItems.map(
                (e) => _ActivityTile(
                  item: e,
                  icon: Icons.location_on_outlined,
                  isImage: false,
                ),
              ),

            const SizedBox.shrink(),
            _SectionSubHeader(
              label: 'Chờ đánh giá',
              trailing: profile.reviewPendingCount > 0
                  ? _CountBadge(value: profile.reviewPendingCount)
                  : null,
            ),
            if (pendingItems.isEmpty)
              const _SectionEmptyHint(label: 'Không có đánh giá đang chờ')
            else
              ...pendingItems.map(
                (e) => _ActivityTile(
                  item: e,
                  icon: Icons.image_outlined,
                  isImage: true,
                ),
              ),

            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReviewCatalogScreen(),
                  ),
                );
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 8, top: 4),
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Am thuc
            const _PillHeader(
              icon: Icons.restaurant_outlined,
              label: 'ẨM THỰC ĐÃ ĐẶT',
            ),
            const SizedBox.shrink(),
            _FoodOrdersSection(dataSource: orderDataSource),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          _MenuTile(
            icon: Icons.exit_to_app_rounded,
            label: 'Đăng xuất',
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileDrawerAvatar extends StatelessWidget {
  final String avatarUrl;

  const _ProfileDrawerAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = avatarUrl.trim();

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blobLight, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: normalizedUrl.isEmpty
          ? const _ProfileAvatarFallback()
          : CachedNetworkImage(
              imageUrl: normalizedUrl,
              fit: BoxFit.cover,
              memCacheWidth: 150, // avatar 50dp — không giải mã full-res
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (context, imageUrl) =>
                  const _ProfileAvatarFallback(),
              errorWidget: (context, imageUrl, error) =>
                  const _ProfileAvatarFallback(),
            ),
    );
  }
}

class _ProfileAvatarFallback extends StatelessWidget {
  const _ProfileAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blobLight.withValues(alpha: 0.22),
      child: const Icon(
        Icons.person_outline,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}
          
class _PillHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    if (icon == Icons.calendar_today_outlined) {
      return const SizedBox.shrink();
    }

    final displayLabel = icon == Icons.star_border_rounded
        ? 'ĐÁNH GIÁ LỊCH TRÌNH & ĐỊA ĐIỂM'
        : icon == Icons.restaurant_outlined
            ? 'ẨM THỰC ĐÃ ĐẶT'
            : label;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blobLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                icon == Icons.exit_to_app_rounded ? 'Đăng xuất' : label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItemEntity item;
  final IconData icon;
  final bool isImage;
  const _ActivityTile({
    required this.item,
    required this.icon,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final catalog = await sl<ReviewRepository>().getReviewCatalog();
        if (!context.mounted) return;
        final parts = item.id.split(':');
        final kind = parts.first;
        final itineraryId = parts.length > 1 ? parts[1] : '';
        final detailId = parts.length > 2 ? parts[2] : '';
        final reviewId = parts.length > 3 ? parts[3] : '';
        final source = item.status == ActivityStatus.pendingReview
            ? catalog.pending
            : catalog.reviewed;
        ReviewCatalogItem? target;
        for (final review in source) {
          final matches = reviewId.isNotEmpty
              ? review.reviewId == reviewId
              : review.kind == kind &&
                    review.itineraryId == itineraryId &&
                    (detailId.isEmpty || review.itineraryDetailId == detailId);
          if (matches) {
            target = review;
            break;
          }
        }
        if (target != null) {
          await openReviewItem(context, target);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 36, right: 20, top: 4, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: isImage ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isImage ? BorderRadius.circular(12) : null,
              ),
              child: Icon(
                isImage ? Icons.landscape_outlined : icon,
                color: Colors.grey.shade600,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.status == ActivityStatus.pendingReview)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Chờ bạn chia sẻ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        if (item.rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFA500),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.date != null)
                          Text(
                            DateFormat('dd/MM/yyyy').format(item.date!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
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

class _FoodOrdersSection extends StatelessWidget {
  final TouristMoreInfoDataSource dataSource;

  const _FoodOrdersSection({required this.dataSource});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TouristOrderSummary>>(
      future: dataSource.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _SectionEmptyHint(label: 'Chưa tải được đơn hàng');
        }

        final orders = snapshot.data ?? const <TouristOrderSummary>[];
        if (orders.isEmpty) {
          return const _SectionEmptyHint(label: 'Bạn chưa có đơn đặt hàng nào');
        }

        return _FoodOrdersGrouped(
          orders: orders,
          dataSource: dataSource,
        );

      },
    );
  }
}

class _FoodOrdersGrouped extends StatelessWidget {
  final List<TouristOrderSummary> orders;
  final TouristMoreInfoDataSource dataSource;

  const _FoodOrdersGrouped({
    required this.orders,
    required this.dataSource,
  });

  @override
  Widget build(BuildContext context) {
    final activeOrders = orders
        .where((order) =>
            order.status == 'pending' || order.status == 'processing')
        .take(2)
        .toList();
    final historyOrders = orders
        .where((order) =>
            order.status == 'completed' || order.status == 'cancelled')
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionSubHeader(
          label: 'Chờ nhận món',
          trailing: activeOrders.isNotEmpty
              ? _CountBadge(value: activeOrders.length)
              : null,
        ),
        if (activeOrders.isEmpty)
          const _SectionEmptyHint(label: 'Không có đơn hàng đang diễn ra')
        else
          ...activeOrders.map(
            (order) => _TouristOrderCard(
              order: order,
              onTap: () => _showOrderDetail(context, dataSource, order),
            ),
          ),

        _SectionSubHeader(
          label: 'Lịch sử đơn hàng',
          trailing: historyOrders.isNotEmpty
              ? _CountBadge(value: historyOrders.length)
              : null,
        ),
        if (historyOrders.isEmpty)
          const _SectionEmptyHint(label: 'Chưa có đơn hàng nào')
        else
          ...historyOrders.map(
            (order) => _TouristOrderCard(
              order: order,
              onTap: () => _showOrderDetail(context, dataSource, order),
            ),
          ),
        InkWell(
          onTap: () => _showAllOrders(context, dataSource),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 8, top: 2),
              child: Text(
                'Xem tất cả',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionSubHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionSubHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 20, top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          trailing ?? const SizedBox(),
        ],
      ),
    );
  }
}

class _SectionEmptyHint extends StatelessWidget {
  final String label;
  const _SectionEmptyHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 20, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF9CA3AF),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int value;
  const _CountBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Color(0xFFF44336),
        shape: BoxShape.circle,
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TouristOrderCard extends StatelessWidget {
  final TouristOrderSummary order;
  final VoidCallback onTap;

  const _TouristOrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFF3F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor(order.status).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _statusIcon(order.status),
                color: _statusColor(order.status),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.orderCode,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7C8794),
                    ),
                  ),
                ],
              ),
            ),
            _OrderStatusChip(order: order),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final TouristOrderSummary order;

  const _OrderStatusChip({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'processing':
      return AppColors.primary;
    case 'completed':
      return const Color(0xFF16A34A);
    case 'cancelled':
    case 'canceled':
      return const Color(0xFFEF4444);
    default:
      return AppColors.primary;
  }
}

IconData _statusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'processing':
      return Icons.restaurant_menu_rounded;
    case 'completed':
      return Icons.check_circle_outline_rounded;
    case 'cancelled':
    case 'canceled':
      return Icons.cancel_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}

String _formatMoney(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value);
}

void _showAllOrders(
  BuildContext context,
  TouristMoreInfoDataSource dataSource,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Tất cả đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<TouristOrderSummary>>(
                  future: dataSource.getOrders(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Chưa tải được đơn hàng'));
                    }
                    final orders =
                        snapshot.data ?? const <TouristOrderSummary>[];
                    if (orders.isEmpty) {
                      return const Center(
                        child: Text('Bạn chưa có đơn đặt hàng nào'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) => _TouristOrderCard(
                        order: orders[index],
                        onTap: () =>
                            _showOrderDetail(context, dataSource, orders[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showOrderDetail(
  BuildContext context,
  TouristMoreInfoDataSource dataSource,
  TouristOrderSummary order,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: FutureBuilder<TouristOrderDetail>(
          future: dataSource.getOrderDetail(order.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('Chưa tải được chi tiết đơn hàng')),
              );
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const SizedBox.shrink();
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.42,
              maxChildSize: 0.9,
              builder: (context, controller) {
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail.order.restaurantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        _OrderStatusChip(order: detail.order),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.order.orderCode,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7C8794),
                      ),
                    ),
                    if (detail.order.orderedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(detail.order.orderedAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C8794),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Món đã đặt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...detail.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} x ${_formatMoney(item.unitPrice)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF7C8794),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatMoney(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng cộng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatMoney(detail.order.totalAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

