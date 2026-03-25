import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SearchHeaderWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  const SearchHeaderWidget({
    super.key,
    required this.controller,
    required this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Nút Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black, // Theo thiết kế là đen
                size: 20,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4), // Background xám nhạt (F1F3F4)
                border: Border.all(color: Colors.black, width: 1.0), // Viền màu đen
                borderRadius: BorderRadius.circular(24), // Border radius 24px
              ),
              padding: const EdgeInsets.only(left: 12, right: 16), // Padding trái icon là 12px
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo trục dọc
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.black, // Kính lúp màu đen (#000000)
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      readOnly: false, // Sử dụng bàn phím thật
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center, // Đảm bảo text align center
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm thành phố, địa điểm, nhà hàng...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500, // Màu xám nhạt
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none, // Bỏ viền mặc định
                        focusedBorder: InputBorder.none, // Bỏ viền khi focus
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black, // Text input màu đen (#000000)
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.cancel,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
