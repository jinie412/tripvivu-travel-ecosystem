import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

class PlaceHeader extends StatelessWidget {
  final String imageUrl;
  final String? typeName;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const PlaceHeader({
    super.key,
    required this.imageUrl,
    this.typeName,
    this.isFavorite = false,
    required this.onBack,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = typeName?.trim();

    return Stack(
      children: [
        NetImage(
          url: imageUrl,
          height: 350,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circularButton(Icons.arrow_back_ios_new, onBack, iconSize: 20),
                _circularButton(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  onFavorite,
                  color: isFavorite ? Colors.red : null,
                ),
              ],
            ),
          ),
        ),
        if (typeLabel != null && typeLabel.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                typeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _circularButton(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    double? iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.black, size: iconSize ?? 22),
      ),
    );
  }
}
