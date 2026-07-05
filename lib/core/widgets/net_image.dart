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
      child: LayoutBuilder(
        builder: (context, constraints) => CachedNetworkImage(
          imageUrl: rawUrl,
          cacheManager: AppImageCacheManager(),
          fit: fit,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          // Giải mã ảnh đúng kích thước hiển thị thay vì full resolution —
          // ảnh 4000px hiển thị trong card 160px vẫn chiếm hàng chục MB RAM
          // nếu không giới hạn; RAM cao là lý do Android kill app khi chạy nền.
          memCacheWidth: _decodeWidth(context, constraints),
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) => placeholder,
          errorWidget: (context, url, error) => placeholder,
        ),
      ),
    );
  }

  /// Bề rộng (pixel vật lý) cần giải mã: lấy cạnh lớn nhất của khung hiển thị
  /// × devicePixelRatio (cạnh lớn nhất để ảnh BoxFit.cover trong khung cao/hẹp
  /// không bị vỡ nét), chặn trần 1440px cho ảnh mở toàn màn hình.
  int _decodeWidth(BuildContext context, BoxConstraints constraints) {
    double logical = 0;
    for (final candidate in [
      width,
      height,
      constraints.maxWidth,
      constraints.maxHeight,
    ]) {
      if (candidate != null && candidate.isFinite && candidate > logical) {
        logical = candidate;
      }
    }
    if (logical <= 0) logical = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).ceil().clamp(64, 1440);
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
