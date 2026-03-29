import 'package:flutter/material.dart';


class VisitingTimeSlider extends StatefulWidget {
  final String start;
  final String end;
  final Function(String, String) onChanged;

  const VisitingTimeSlider({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
  });

  @override
  State<VisitingTimeSlider> createState() => _VisitingTimeSliderState();
}

class _VisitingTimeSliderState extends State<VisitingTimeSlider> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = RangeValues(
      _timeToDouble(widget.start),
      _timeToDouble(widget.end),
    );
  }

  double _timeToDouble(String time) {
    final parts = time.split(':');
    return double.parse(parts[0]) + double.parse(parts[1]) / 60;
  }

  String _doubleToTime(double val) {
    final hour = val.floor();
    final minute = ((val - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thời gian tham quan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_currentRange.end - _currentRange.start).toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _timeLabel(_doubleToTime(_currentRange.start)),
            const SizedBox(width: 16),
            _timeLabel(_doubleToTime(_currentRange.end)),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _currentRange,
          min: 8.0,
          max: 22.0,
          divisions: 56, // 15 min intervals
          activeColor: const Color(0xFF2563EB),
          inactiveColor: const Color(0xFFF1F5F9),
          labels: RangeLabels(
            _doubleToTime(_currentRange.start),
            _doubleToTime(_currentRange.end),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _currentRange = values;
            });
            widget.onChanged(
              _doubleToTime(values.start),
              _doubleToTime(values.end),
            );
          },
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('8:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            Text('22:00', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _timeLabel(String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
