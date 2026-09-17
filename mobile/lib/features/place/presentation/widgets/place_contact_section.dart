import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceContactSection extends StatelessWidget {
  final String? openHourCompressed;
  final String? phone;
  final String address;
  final VoidCallback? onLocationTap;

  const PlaceContactSection({
    super.key,
    required this.openHourCompressed,
    required this.phone,
    required this.address,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          OpeningHoursDropdown(openHourCompressed: openHourCompressed),
          const SizedBox(height: 12),
          _contactItem(
            Icons.phone_outlined,
            phone?.trim().isNotEmpty == true
                ? phone!
                : 'Chưa cập nhật số điện thoại',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _contactItem(
            Icons.location_on_outlined,
            address,
            const Color(0xFFF43F5E),
            onTap: onLocationTap,
            isLink: true,
          ),
        ],
      ),
    );
  }

  Widget _contactItem(
    IconData icon,
    String text,
    Color iconColor, {
    VoidCallback? onTap,
    bool isLink = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isLink
                      ? const Color(0xFF2563EB)
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: isLink ? TextDecoration.underline : null,
                  decorationColor: const Color(
                    0xFF2563EB,
                  ).withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpeningHoursDropdown extends StatefulWidget {
  final String? openHourCompressed;

  const OpeningHoursDropdown({super.key, required this.openHourCompressed});

  @override
  State<OpeningHoursDropdown> createState() => _OpeningHoursDropdownState();
}

class _OpeningHoursDropdownState extends State<OpeningHoursDropdown> {
  bool _isExpanded = false;

  static const List<_WeekdayInfo> _weekdays = [
    _WeekdayInfo('Monday', 'Thứ Hai'),
    _WeekdayInfo('Tuesday', 'Thứ Ba'),
    _WeekdayInfo('Wednesday', 'Thứ Tư'),
    _WeekdayInfo('Thursday', 'Thứ Năm'),
    _WeekdayInfo('Friday', 'Thứ Sáu'),
    _WeekdayInfo('Saturday', 'Thứ Bảy'),
    _WeekdayInfo('Sunday', 'Chủ Nhật'),
  ];

  @override
  Widget build(BuildContext context) {
    final days = _parseOpeningHours(widget.openHourCompressed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: days != null && _isExpanded
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: days == null
                ? const Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      'Chưa cập nhật giờ mở cửa - đóng cửa',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : _buildDays(days),
          ),
        ],
      ),
    );
  }

  Widget _buildDays(List<_OpeningDay> days) {
    final visibleDays = _isExpanded ? days : days.take(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visibleDays.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: _dayRow(visibleDays[i], showToggle: i == 0),
          ),
      ],
    );
  }

  Widget _dayRow(_OpeningDay day, {required bool showToggle}) {
    final muted = !day.hasData;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            day.label,
            style: TextStyle(
              fontSize: 14,
              color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              fontWeight: showToggle && _isExpanded
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            day.hoursText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              fontWeight: showToggle && _isExpanded
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        if (showToggle) ...[
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  List<_OpeningDay>? _parseOpeningHours(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final todayIndex = DateTime.now().weekday - 1;
      final orderedDays = [
        ..._weekdays.skip(todayIndex),
        ..._weekdays.take(todayIndex),
      ];

      return orderedDays.map((day) {
        final ranges = decoded[day.key];
        final hours = _formatRanges(ranges);

        return _OpeningDay(
          label: day.label,
          hoursText: hours ?? 'Không có dữ liệu',
          hasData: hours != null,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  String? _formatRanges(dynamic ranges) {
    if (ranges is! List || ranges.isEmpty) {
      return null;
    }

    final formatted = ranges
        .whereType<List<dynamic>>()
        .map((range) {
          if (range.length < 2) {
            return null;
          }

          final open = _formatTime(range[0]);
          final close = _formatTime(range[1]);
          if (open == null || close == null) {
            return null;
          }

          return '$open-$close';
        })
        .whereType<String>()
        .toList();

    return formatted.isEmpty ? null : formatted.join(', ');
  }

  String? _formatTime(dynamic value) {
    if (value is! String) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _WeekdayInfo {
  final String key;
  final String label;

  const _WeekdayInfo(this.key, this.label);
}

class _OpeningDay {
  final String label;
  final String hoursText;
  final bool hasData;

  const _OpeningDay({
    required this.label,
    required this.hoursText,
    required this.hasData,
  });
}
