import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  String? _startError;
  String? _endError;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.startTime ?? '07:00');
    _endCtrl = TextEditingController(text: widget.endTime ?? '22:00');
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  bool _isComplete(String value) => RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);

  void _onStartChanged(String value) {
    if (_isComplete(value)) {
      setState(() => _startError = null);
      widget.onStartChanged(value);
    }
  }

  void _onEndChanged(String value) {
    if (_isComplete(value)) {
      setState(() => _endError = null);
      widget.onEndChanged(value);
    }
  }

  void _validateStart() {
    if (!_isComplete(_startCtrl.text)) {
      setState(() => _startError = 'Chưa đủ giờ hợp lệ');
    }
  }

  void _validateEnd() {
    if (!_isComplete(_endCtrl.text)) {
      setState(() => _endError = 'Chưa đủ giờ hợp lệ');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Nhập 4 chữ số — dấu : tự thêm (hệ 24 giờ)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeField(
                  label: 'GIỜ BẮT ĐẦU',
                  controller: _startCtrl,
                  errorText: _startError,
                  onChanged: _onStartChanged,
                  onFocusLost: _validateStart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimeField(
                  label: 'GIỜ KẾT THÚC',
                  controller: _endCtrl,
                  errorText: _endError,
                  onChanged: _onEndChanged,
                  onFocusLost: _validateEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Auto-format formatter ─────────────────────────────────────────────────────

class _TimeAutoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Chỉ giữ lại chữ số
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Giới hạn tối đa 4 chữ số
    final capped = digits.length > 4 ? digits.substring(0, 4) : digits;

    // Chèn dấu : sau 2 chữ số đầu
    String formatted;
    if (capped.length <= 2) {
      formatted = capped;
    } else {
      formatted = '${capped.substring(0, 2)}:${capped.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Time Field widget ─────────────────────────────────────────────────────────

class _TimeField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocusLost;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onFocusLost,
  });

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onFocusLost();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [_TimeAutoFormatter()],
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            counterText: '',
            hintText: '--:--',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              letterSpacing: 2,
            ),
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
                color: widget.errorText != null
                    ? Colors.red.shade300
                    : AppColors.inputBorder.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.errorText != null ? Colors.red.shade400 : AppColors.primary,
                width: 1.5,
              ),
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(fontSize: 10),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
