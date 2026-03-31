import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/widgets/net_image.dart';

class PlaceHeader extends StatelessWidget {
  final String imageUrl;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

  const PlaceHeader({
    super.key,
    required this.imageUrl,
    this.isFavorite = false,
    required this.onBack,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }

  Widget _circularButton(IconData icon, VoidCallback onTap, {Color? color, double? iconSize}) {
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