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
    final placeholder = Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: placeholderColor != null ? Color(placeholderColor!) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}