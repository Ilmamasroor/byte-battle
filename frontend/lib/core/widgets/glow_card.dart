import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// Shared "glass" card used across the dashboard sections (Current
/// Mission, Byte DNA, XP & Streak, Recommended Battles) — a light,
/// mostly see-through fill with a bright, shiny border and a soft
/// outer glow, replacing the old heavy solid-filled box look.
///
/// Horizontal padding is intentionally tighter than the vertical
/// padding so content sits closer to the edges (matches the reference
/// dashboard — the old containers wasted too much space on the sides).
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color glowColor;
  final Color borderColor;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingSm + 4, // 12
      vertical: AppDimensions.spacingMd, // 16
    ),
    this.glowColor = AppColors.accentCyan,
    this.borderColor = AppColors.borderLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: borderColor.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.18),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
