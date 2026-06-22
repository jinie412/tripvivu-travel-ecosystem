import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

class PlaceGallerySection extends StatelessWidget {
  final List<String> images;

  const PlaceGallerySection({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    final displayImages = images.where(_isRealPlaceImage).toList();

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
          if (displayImages.isEmpty)
            SizedBox(
              width: double.infinity,
              child: const Text(
                'Không có hình ảnh cho địa điểm này.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _imageItem(context, displayImages, 0),
                  ),
                  if (displayImages.length > 1) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Expanded(
                            child: _imageItem(context, displayImages, 1),
                          ),
                          if (displayImages.length > 2) ...[
                            const SizedBox(height: 8),
                            Expanded(
                              child: _imageItem(
                                context,
                                displayImages,
                                2,
                                remainingCount: displayImages.length - 3,
                              ),
                            ),
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

  Widget _imageItem(
    BuildContext context,
    List<String> images,
    int index, {
    int remainingCount = 0,
  }) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, images, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: NetImage(
              url: images[index],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          if (remainingCount > 0)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+$remainingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showImagePreview(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) =>
          _GalleryPreviewDialog(images: images, initialIndex: initialIndex),
    );
  }

  bool _isRealPlaceImage(String url) {
    final normalized = url.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return !normalized.contains('placehold.co') &&
        !normalized.contains('no+image') &&
        !normalized.contains('no-image') &&
        !normalized.contains('no image');
  }
}

class _GalleryPreviewDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _GalleryPreviewDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GalleryPreviewDialog> createState() => _GalleryPreviewDialogState();
}

class _GalleryPreviewDialogState extends State<_GalleryPreviewDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canNavigate = widget.images.length > 1;

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: NetImage(
                    url: widget.images[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _roundIconButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (canNavigate) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _roundIconButton(
                    icon: Icons.chevron_left,
                    onTap: _currentIndex == 0
                        ? null
                        : () => _animateTo(_currentIndex - 1),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _roundIconButton(
                    icon: Icons.chevron_right,
                    onTap: _currentIndex == widget.images.length - 1
                        ? null
                        : () => _animateTo(_currentIndex + 1),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _animateTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;

    return Material(
      color: Colors.black.withValues(alpha: enabled ? 0.55 : 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.35),
            size: 26,
          ),
        ),
      ),
    );
  }
}
