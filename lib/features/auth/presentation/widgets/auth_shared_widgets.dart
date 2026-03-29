import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

/// Shared decorative background blobs used across auth screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          top: -100, right: -80,
          child: _blob(280, const Color(0xFFB8D8F8), 0.55),
        ),
        Positioned(
          top: 60, right: 30,
          child: _blob(120, const Color(0xFFD6ECFF), 0.7),
        ),
        Positioned(
          top: 280, left: -40,
          child: _blob(140, const Color(0xFFBFD9F8), 0.3),
        ),
        Positioned(
          bottom: -100, left: -80,
          child: _blob(300, const Color(0xFFB8D8F8), 0.5),
        ),
        Positioned(
          bottom: 80, right: w * 0.12,
          child: _blob(70, const Color(0xFFD6ECFF), 0.6),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
        ),
      );
}

/// "Hoặc" divider with horizontal lines on both sides.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.s12),
          child: Text('Hoặc',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Google Sign-In button
// ─────────────────────────────────────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.s48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleGLogo(),
            const SizedBox(width: 10),
            Text(
              'Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google "G" multicolor logo via official SVG asset.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/google_g.svg',
      width: 24,
      height: 24,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Facebook Sign-In button
// ─────────────────────────────────────────────────────────────────────────────
class FacebookSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const FacebookSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.s48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _FacebookIcon(),
            const SizedBox(width: 10),
            Text(
              'Facebook',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  const _FacebookIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/facebook_f.svg',
      width: 24,
      height: 24,
    );
  }
}

/// Legacy alias — kept for any code still using [SocialButton].
/// Prefer [GoogleSignInButton] or [FacebookSignInButton] directly.
class SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.s48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDADCE0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}
