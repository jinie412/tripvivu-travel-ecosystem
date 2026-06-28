import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'app_image_cache_manager.dart';

class DefaultAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const DefaultAvatar({super.key, this.imageUrl, this.radius = 20});

  static const String _assetFallback = 'assets/images/0583188d-feeb-4dad-94fd-f7baecf4b800.jpg';

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        cacheManager: AppImageCacheManager(),
        fadeInDuration: const Duration(milliseconds: 150),
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        errorWidget: (context, _, __) => _assetAvatar(),
        placeholder: (context, _) => _assetAvatar(),
      );
    }

    return _assetAvatar();
  }

  Widget _assetAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0E0E0),
      child: ClipOval(
        child: Image.asset(
          _assetFallback,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => Icon(
            Icons.person,
            size: radius,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}
