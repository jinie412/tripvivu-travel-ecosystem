import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(children: [
        SizedBox(width: 14),
        Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tìm địa điểm, lịch trình, trải nghiệm...',
            style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
          ),
        ),
      ]),
    );
  }
}