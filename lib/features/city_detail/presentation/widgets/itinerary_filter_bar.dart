import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ItineraryFilterBar extends StatelessWidget {
  const ItineraryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'Số ngày', 'hasDropdown': true, 'isActive': true},
      {'label': 'Ngân sách', 'hasDropdown': false, 'isActive': false},
      {'label': 'Phổ biến', 'hasDropdown': true, 'isActive': false},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final bool isActive = filter['isActive'] as bool;
          final bool hasDropdown = filter['hasDropdown'] as bool;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (hasDropdown) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: isActive ? Colors.white : Colors.black54,
                    ),
                  ],
                ],
              ),
              selected: isActive,
              onSelected: (_) {},
              backgroundColor: const Color(0xFFF2F2F7),
              selectedColor: AppColors.primary,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isActive ? AppColors.primary : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
