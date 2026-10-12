import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color? color;
  final double size;
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final palette = [
      AppColors.primaryLight,
      const Color(0xFFFFE0E0),
      const Color(0xFFFFF4D6),
      const Color(0xFFDCEEFF),
      const Color(0xFFE2F8E2),
    ];
    final c =
        color ??
        palette[initials.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
