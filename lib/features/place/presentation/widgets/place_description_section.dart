import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';

class PlaceDescriptionSection extends StatefulWidget {
  final String description;

  const PlaceDescriptionSection({super.key, required this.description});

  @override
  State<PlaceDescriptionSection> createState() => _PlaceDescriptionSectionState();
}

class _PlaceDescriptionSectionState extends State<PlaceDescriptionSection> {
  bool _isExpanded = false;

  List<String> _splitSentences(String text) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final parts = normalized
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.isEmpty ? [normalized] : parts;
  }

  String _buildCollapsedDescription(List<String> sentences) {
    if (sentences.length <= 3) {
      return sentences.join(' ');
    }

    return '${sentences.take(3).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    final sentences = _splitSentences(widget.description);
    final canExpand = sentences.length > 3;
    final displayedDescription = _isExpanded
        ? widget.description.trim()
        : _buildCollapsedDescription(sentences);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            displayedDescription,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          if (canExpand)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isExpanded ? 'Thu gọn' : 'Xem thêm',
                  style: const TextStyle(
                    color: Color(0xFF1D7BD7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}