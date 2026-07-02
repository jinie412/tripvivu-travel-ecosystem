import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';

class BudgetSliderSection extends StatefulWidget {
  final double currentBudget;
  final ValueChanged<double> onChanged;

  const BudgetSliderSection({
    super.key,
    required this.currentBudget,
    required this.onChanged,
  });

  @override
  State<BudgetSliderSection> createState() => _BudgetSliderSectionState();
}

class _BudgetSliderSectionState extends State<BudgetSliderSection> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late bool _unlimited;

  /// Các mức ngân sách gợi ý (đơn vị: VND/người)
  static const List<_BudgetPreset> _presets = [
    _BudgetPreset(label: '5tr', value: 5000000),
    _BudgetPreset(label: '10tr', value: 10000000),
    _BudgetPreset(label: '15tr', value: 15000000),
    _BudgetPreset(label: '20tr', value: 20000000),
    _BudgetPreset(label: '30tr', value: 30000000),
  ];

  @override
  void initState() {
    super.initState();
    _unlimited = widget.currentBudget <= 0;
    _focusNode = FocusNode();
    final initialText = _unlimited 
        ? '' 
        : NumberFormat.decimalPattern('vi').format(widget.currentBudget);
    _controller = TextEditingController(text: initialText);
  }

  @override
  void didUpdateWidget(covariant BudgetSliderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBudget != widget.currentBudget) {
      _unlimited = widget.currentBudget <= 0;
      _controller.text = _unlimited 
          ? '' 
          : NumberFormat.decimalPattern('vi').format(widget.currentBudget);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectPreset(double value) {
    setState(() {
      _unlimited = false;
      _controller.text = NumberFormat.decimalPattern('vi').format(value);
    });
    widget.onChanged(value);
    _focusNode.unfocus();
  }

  /// Được gọi khi user tap vào TextField trong lúc đang _unlimited.
  /// Tự động tắt unlimited để user không cần bấm toggle trước.
  void _onTextFieldTap() {
    if (_unlimited) {
      setState(() => _unlimited = false);
    }
  }

  void _toggleUnlimited() {
    setState(() {
      _unlimited = !_unlimited;
      if (_unlimited) {
        _controller.clear();
        widget.onChanged(0);
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleUnlimited,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _unlimited ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _unlimited ? AppColors.primary : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _unlimited ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: _unlimited ? AppColors.primary : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không giới hạn ngân sách',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          // Không disabled — tap vào sẽ tự tắt unlimited qua _onTextFieldTap
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Ngân sách dự kiến / người',
            hintText: _unlimited ? 'Bấm để nhập ngân sách...' : 'Nhập số tiền',
            suffixText: 'VND',
            filled: true,
            fillColor: _unlimited ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _unlimited
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onTap: _onTextFieldTap,
          onChanged: (value) {
            if (_unlimited) {
              setState(() => _unlimited = false);
            }
            final text = value.replaceAll(RegExp(r'\D'), '');
            final amount = double.tryParse(text) ?? 0;
            widget.onChanged(amount);
          },
        ),
        const SizedBox(height: 10),
        // ── Nút gợi ý nhanh ──────────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final isSelected =
                !_unlimited && widget.currentBudget.round() == preset.value;
            return GestureDetector(
              // Cho phép tap ngay cả khi _unlimited — _selectPreset sẽ tắt unlimited
              onTap: () => _selectPreset(preset.value.toDouble()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : _unlimited
                          ? const Color(0xFFF1F5F9)
                          : AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : _unlimited
                            ? const Color(0xFFE2E8F0)
                            : AppColors.primary.withValues(alpha: 0.35),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  preset.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : _unlimited
                            ? const Color(0xFFB0BEC5)
                            : AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _unlimited
              ? 'Hệ thống sẽ không giới hạn lịch trình theo ngân sách.'
              : 'Đang đặt giới hạn: ${formatter.format(widget.currentBudget)} / người',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BudgetPreset {
  final String label;
  final int value;
  const _BudgetPreset({required this.label, required this.value});
}
