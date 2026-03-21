import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LocationSelectorCard extends StatelessWidget {
  final String? departureLocation;
  final String? destinationLocation;
  final VoidCallback onSwap;
  final VoidCallback onTapDeparture;
  final VoidCallback onTapDestination;

  const LocationSelectorCard({
    Key? key,
    this.departureLocation,
    this.destinationLocation,
    required this.onSwap,
    required this.onTapDeparture,
    required this.onTapDestination,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLocationTile(
                title: 'ĐỊA ĐIỂM KHỞI HÀNH',
                value: departureLocation,
                onTap: onTapDeparture,
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.background),
              _buildLocationTile(
                title: 'ĐỊA ĐIỂM ĐẾN',
                value: destinationLocation,
                onTap: onTapDestination,
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          child: GestureDetector(
            onTap: onSwap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_vert,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationTile({
    required String title,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? 'Chọn địa điểm',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
