import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'app_image_cache_manager.dart';

class NetImage extends StatelessWidget {
  final String? url;
  final int? placeholderColor;
  final double borderRadius;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NetImage({
    super.key,
    required this.url,
    this.placeholderColor,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = url?.trim() ?? '';
    final bg = placeholderColor != null
        ? Color(placeholderColor!)
        : const Color(0xFFE5E7EB);
    final placeholder = _Placeholder(
      color: bg,
      borderRadius: borderRadius,
      width: width,
      height: height,
    );

    if (rawUrl.isEmpty || _isUnsafeImageUrl(rawUrl)) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: rawUrl,
        cacheManager: AppImageCacheManager(),
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }

  bool _isUnsafeImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return true;
    return uri.host.toLowerCase() == 'tinyurl.vn';
  }
}

class _Placeholder extends StatelessWidget {
  final Color color;
  final double borderRadius;
  final double? width;
  final double? height;

  const _Placeholder({
    required this.color,
    required this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
