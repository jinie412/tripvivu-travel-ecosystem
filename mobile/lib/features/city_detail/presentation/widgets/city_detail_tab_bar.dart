import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class CityDetailTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CityDetailTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<Map<String, dynamic>> tabs = const [
    {'icon': Icons.menu_book_outlined, 'label': 'Tổng quan'},
    {'icon': Icons.map_outlined, 'label': 'Lịch trình'},
    {
      'icon': Icons.camera_alt_outlined,
      'label': 'Tham quan & giải trí',
    },
    {'icon': Icons.restaurant_outlined, 'label': 'Nhà hàng'},
    {'icon': Icons.apartment_outlined, 'label': 'Khách sạn'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            AppColors.premiumBlue,
                            AppColors.premiumTeal,
                          ],
                        )
                      : null,
                  color: isSelected ? null : AppColors.premiumSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.premiumBorder,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.premiumBlue.withValues(alpha: .2),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.premiumMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.premiumMuted,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
