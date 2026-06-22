import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

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
    final placeholder = Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: placeholderColor != null
            ? Color(placeholderColor!)
            : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (rawUrl.isEmpty || _isUnsafeImageUrl(rawUrl)) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: rawUrl,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }

  bool _isUnsafeImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return true;
    }

    // Some shortened URLs in older itinerary data return non-image payloads
    // on Android and trigger native ImageDecoder errors before Flutter can
    // show errorWidget. Treat them as missing images.
    return uri.host.toLowerCase() == 'tinyurl.vn';
  }
}
