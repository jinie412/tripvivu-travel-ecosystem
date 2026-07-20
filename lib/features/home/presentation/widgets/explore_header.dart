import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/location_state.dart';
import 'package:travel_advisor_mobile/features/search/presentation/screens/search_screen.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF091F3A), Color(0xFF145E9F), Color(0xFF168A9C)],
          stops: [0, .62, 1],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.s12,
        left: AppSizes.s20,
        right: AppSizes.s20,
        bottom: AppSizes.s24,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -26,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.iconButtonSize,
                    height: AppSizes.iconButtonSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .18),
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: AppSizes.iconMd,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  // Vị trí
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              color: Color(0xFF88E5D6),
                              size: AppSizes.iconXs,
                            ),
                            const SizedBox(width: AppSizes.s4),
                            Text(
                              'VỊ TRÍ CỦA BẠN',
                              style: AppTextStylesExt.overline.copyWith(
                                color: Colors.white.withValues(alpha: .7),
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.s2),
                        BlocBuilder<LocationCubit, LocationState>(
                          builder: (context, state) {
                            String text;
                            if (state is LocationLoaded) {
                              text = state.location.displayText;
                            } else if (state is LocationLoading) {
                              text = 'ĐANG LẤY VỊ TRÍ...';
                            } else if (state is LocationError) {
                              text = state.permissionDenied
                                  ? 'NHẤN ĐỂ CẤP QUYỀN VỊ TRÍ'
                                  : 'NHẤN ĐỂ THỬ LẠI';
                            } else {
                              text = 'ĐANG LẤY VỊ TRÍ...';
                            }
                            return GestureDetector(
                              onTap: state is LocationError
                                  ? () => context
                                        .read<LocationCubit>()
                                        .fetchLocation()
                                  : null,
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.s12),
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      bool hasUnread = false;
                      if (state is NotificationLoaded) {
                        hasUnread = state.notifications.any((n) => n.isUnread);
                      }

                      return Container(
                        width: AppSizes.iconButtonSize,
                        height: AppSizes.iconButtonSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .18),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white,
                                  size: AppSizes.iconMd,
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openEndDrawer();
                                },
                              ),
                            ),
                            if (hasUnread)
                              Positioned(
                                top: 10,
                                right: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC857),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .8),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF001B33).withValues(alpha: .18),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FB),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s12),
                      Expanded(
                        child: Text(
                          'Tìm kiếm thành phố, địa điểm, nhà hàng...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF74849A),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
