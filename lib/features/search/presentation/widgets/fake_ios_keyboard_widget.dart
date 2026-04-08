import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class FakeIOSKeyboardWidget extends StatelessWidget {
  const FakeIOSKeyboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD1D5DB), // Xám nhạt của bàn phím
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSuggestionBar(),
          const SizedBox(height: 8),
          _buildKeyboardRows(),
          const SizedBox(height: 32), // Safe area bottom
        ],
      ),
    );
  }

  Widget _buildSuggestionBar() {
    return Container(
      height: 44,
      color: const Color(0xFFD1D5DB),
      child: Row(
        children: [
          Expanded(child: _buildSuggestionItem('hcm')),
          Container(width: 1, height: 24, color: Colors.grey[400]),
          Expanded(child: _buildSuggestionItem('HCM City')),
          Container(width: 1, height: 24, color: Colors.grey[400]),
          Expanded(child: _buildSuggestionItem('Hồ Chí Minh')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.mic, color: Color(0xFF555555), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1C1C1E),
        ),
      ),
    );
  }

  Widget _buildKeyboardRows() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: 'qwertyuiop'.split('').map((char) => _buildKey(char)).toList(),
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              ...('asdfghjkl'.split('').map((char) => _buildKey(char))),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionKey(Icons.arrow_upward, Colors.black),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: 'zxcvbnm'.split('').map((char) => _buildKey(char)).toList(),
                ),
              ),
              _buildActionKey(Icons.backspace_outlined, Colors.black),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextKey('123', width: 44, color: const Color(0xFFB3B6BB)),
              const SizedBox(width: 6),
              _buildTextKey(',', width: 44, color: const Color(0xFFB3B6BB)),
              const SizedBox(width: 6),
              Expanded(child: _buildTextKey('Dấu cách', color: Colors.white)),
              const SizedBox(width: 6),
              _buildTextKey('.', width: 44, color: const Color(0xFFB3B6BB)),
              const SizedBox(width: 6),
              _buildActionKey(Icons.search, Colors.white, bgColor: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String char) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            char,
            style: const TextStyle(fontSize: 22, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildTextKey(String text, {double? width, Color color = Colors.white}) {
    return Container(
      height: 42,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: color == Colors.white ? Colors.black : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, Color iconColor, {Color bgColor = const Color(0xFFB3B6BB)}) {
    return Container(
      height: 42,
      width: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}