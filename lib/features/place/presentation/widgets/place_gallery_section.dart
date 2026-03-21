import 'package:flutter/material.dart';
import '../../../../core/widgets/net_image.dart';

class PlaceGallerySection extends StatelessWidget {
  final List<String> images;

  const PlaceGallerySection({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _imageItem(images[0]),
                ),
                if (images.length > 1) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(child: _imageItem(images[1])),
                        if (images.length > 2) ...[
                          const SizedBox(height: 8),
                          Expanded(child: _imageItem(images[2])),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageItem(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: NetImage(
        url: url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
