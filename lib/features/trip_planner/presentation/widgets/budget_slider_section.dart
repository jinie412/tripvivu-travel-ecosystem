import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

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
  late bool _unlimited;

  @override
  void initState() {
    super.initState();
    _unlimited = widget.currentBudget <= 0;
    _controller = TextEditingController(
      text: _unlimited ? '' : widget.currentBudget.round().toString(),
    );
  }

  @override
  void didUpdateWidget(covariant BudgetSliderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentBudget != widget.currentBudget) {
      _unlimited = widget.currentBudget <= 0;
      _controller.text = _unlimited ? '' : widget.currentBudget.round().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Ngân sách',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
          enabled: !_unlimited,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Ngân sách dự kiến',
            hintText: 'Nhập số tiền',
            suffixText: 'VND',
            filled: true,
            fillColor: _unlimited ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0;
            widget.onChanged(amount);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _unlimited
              ? 'Hệ thống sẽ không giới hạn lịch trình theo ngân sách.'
              : 'Đang đặt giới hạn: ${formatter.format(widget.currentBudget)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _toggleUnlimited() {
    setState(() {
      _unlimited = !_unlimited;
      if (_unlimited) {
        _controller.clear();
        widget.onChanged(0);
      }
    });
  }
}
