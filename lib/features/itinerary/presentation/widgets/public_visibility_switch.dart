import 'package:flutter/material.dart';

class PublicVisibilitySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dark;
  final bool borderless;
  final bool compact;

  const PublicVisibilitySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.dark = false,
    this.borderless = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? Colors.white : const Color(0xFF0F172A);
    final secondary = dark
        ? Colors.white.withValues(alpha: 0.82)
        : const Color(0xFF64748B);
    final bg = borderless
        ? (dark
              ? Colors.black.withValues(alpha: 0.18)
              : const Color(0xFFF8FAFC))
        : dark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFF8FAFC);
    final border = dark
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFFE2E8F0);
    final switchColor = dark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF2563EB);

    return Container(
      padding: EdgeInsets.only(
        left: compact ? 8 : 10,
        right: compact ? 4 : 6,
        top: compact ? 3 : 4,
        bottom: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderless ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: compact ? 12 : 14,
            color: value ? switchColor : secondary,
          ),
          const SizedBox(width: 4),
          Text(
            value ? 'Công khai' : 'Riêng tư',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          SizedBox(
            width: compact ? 30 : 34,
            height: compact ? 18 : 22,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch.adaptive(
                value: value,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: switchColor,
                activeTrackColor: switchColor.withValues(alpha: 0.34),
                inactiveThumbColor: dark ? Colors.white : const Color(0xFFCBD5E1),
                inactiveTrackColor: dark
                    ? Colors.white.withValues(alpha: 0.24)
                    : const Color(0xFFE2E8F0),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
