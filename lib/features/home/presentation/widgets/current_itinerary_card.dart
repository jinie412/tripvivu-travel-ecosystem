import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CurrentItineraryCard extends StatelessWidget {
  const CurrentItineraryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.blobLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TH2',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '24 \u2013 26',
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐANG DIỄN RA',
                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'Du lịch thành phố Hồ Chí Minh',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('08:00 - 11:30', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    SizedBox(width: 12),
                    Icon(Icons.people_outline, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('2 người', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
