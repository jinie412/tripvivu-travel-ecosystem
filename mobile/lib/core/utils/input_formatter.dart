import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Một format chung để tự động thêm dấu phân cách hàng nghìn khi nhập số tiền (chuẩn Việt Nam).
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Chỉ lấy các con số
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final double? value = double.tryParse(text);

    if (value == null) {
      return newValue;
    }

    final formatter = NumberFormat.decimalPattern('vi');
    final newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
