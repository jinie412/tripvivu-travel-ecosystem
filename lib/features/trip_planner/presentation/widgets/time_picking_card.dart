import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class TimePickingCard extends StatefulWidget {
  final String? startTime;
  final String? endTime;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;

  const TimePickingCard({
    super.key,
    this.startTime,
    this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<TimePickingCard> createState() => _TimePickingCardState();
}

class _TimePickingCardState extends State<TimePickingCard> {
  static final List<String> _timeOptions = List.generate(31, (index) {
    final totalMinutes = 6 * 60 + index * 30;
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  late String _startTime;
  late String _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = _normalizeTime(widget.startTime, fallback: '07:00');
    _endTime = _normalizeTime(widget.endTime, fallback: '22:00');
  }

  @override
  void didUpdateWidget(covariant TimePickingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStart = _normalizeTime(widget.startTime, fallback: _startTime);
    final nextEnd = _normalizeTime(widget.endTime, fallback: _endTime);
    if (nextStart != _startTime || nextEnd != _endTime) {
      setState(() {
        _startTime = nextStart;
        _endTime = nextEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInvalidRange = _toMinutes(_startTime) >= _toMinutes(_endTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Chọn khung giờ hoạt động trong ngày',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasInvalidRange ? Colors.red.shade500 : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeDropdownField(
                  label: 'GIỜ BẮT ĐẦU',
                  value: _startTime,
                  options: _timeOptions,
                  hasError: hasInvalidRange,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _startTime = value);
                    widget.onStartChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeDropdownField(
                  label: 'GIỜ KẾT THÚC',
                  value: _endTime,
                  options: _timeOptions,
                  hasError: hasInvalidRange,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _endTime = value);
                    widget.onEndChanged(value);
                  },
                ),
              ),
            ],
          ),
          if (hasInvalidRange) ...[
            const SizedBox(height: 8),
            Text(
              'Giờ kết thúc phải sau giờ bắt đầu',
              style: TextStyle(fontSize: 11, color: Colors.red.shade500),
            ),
          ],
        ],
      ),
    );
  }

  static String _normalizeTime(String? value, {required String fallback}) {
    if (value == null || !_timeOptions.contains(value)) {
      return fallback;
    }
    return value;
  }

  static int _toMinutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _TimeDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  const _TimeDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: options
              .map(
                (time) => DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.inputBorder.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red.shade300
                    : AppColors.inputBorder.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red.shade400 : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
          dropdownColor: AppColors.surface,
        ),
      ],
    );
  }
}
