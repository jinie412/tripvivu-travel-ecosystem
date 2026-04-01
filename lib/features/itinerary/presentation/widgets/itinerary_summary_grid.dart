import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';

/// Lưới thống kê 2×2 — Tổng số · Đã đi · Sắp đi · Đang tạo
///
/// Mỗi ô hiển thị label + số lượng với màu nhấn riêng.
class ItinerarySummaryGrid extends StatelessWidget {
  final ItinerarySummary summary;
  const ItinerarySummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê của lịch trình',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tổng số',
                  valueStr: '${summary.total} lịch trình',
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Hoàn thành',
                  valueStr: '${summary.completed} chuyến',
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Sắp tới',
                  valueStr: '${summary.upcoming} chuyến',
                  icon: Icons.upcoming_outlined,
                  iconColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Bản nháp',
                  valueStr: '${summary.draft} bản',
                  icon: Icons.edit_note_outlined,
                  iconColor: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valueStr;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.valueStr,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            valueStr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}