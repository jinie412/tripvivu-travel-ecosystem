import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ReviewMediaList extends StatelessWidget {
  final List<String> mediaPaths;
  final VoidCallback onAddMedia;
  final ValueChanged<String> onRemoveMedia;
  final VoidCallback onClearAllMedia;
  final double imageSize;

  const ReviewMediaList({
    super.key,
    required this.mediaPaths,
    required this.onAddMedia,
    required this.onRemoveMedia,
    required this.onClearAllMedia,
    this.imageSize = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thêm hình ảnh & video',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(top: 12, right: 12, bottom: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAddMedia,
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
                ),
              ),
              ...mediaPaths.map((path) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -12,
                      right: -12,
                      child: GestureDetector(
                        onTap: () => onRemoveMedia(path),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(Icons.close,
                              size: 18, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        if (mediaPaths.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClearAllMedia,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Xóa toàn bộ ảnh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
