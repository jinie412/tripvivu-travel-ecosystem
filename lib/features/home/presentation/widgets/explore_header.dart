import 'package:flutter/material.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.s16,
        left: AppSizes.s24,
        right: AppSizes.s24,
        bottom: AppSizes.s16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Nút filter dạng tròn màu trắng
              Container(
                width: AppSizes.iconButtonSize,
                height: AppSizes.iconButtonSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.primary, size: AppSizes.iconMd),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              // Vị trí
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white, size: AppSizes.iconXs),
                        SizedBox(width: AppSizes.s4),
                        Text(
                          'VỊ TRÍ CỦA BẠN',
                          style: AppTextStylesExt.overline,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.s2),
                    Text(
                      'QUẬN 1, HỒ CHÍ MINH',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.s12),
              Container(
                width: AppSizes.iconButtonSize,
                height: AppSizes.iconButtonSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none, color: AppColors.primary, size: AppSizes.iconMd),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          // Thanh tìm kiếm
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              height: AppSizes.searchBarHeight,
              decoration: BoxDecoration(
                color: AppColorsExt.searchBarBg,
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(AppSizes.r24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black, size: AppSizes.iconMd),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: Text(
                      'Tìm kiếm thành phố, địa điểm, nhà hàng...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
