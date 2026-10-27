import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// Shared content card. Calm by default: a solid raised surface with a hairline border. `emphasized` is the
/// spotlight, for the ONE card per screen that matters most (the next step): a Flame-to-Aqua gradient edge with
/// a soft warm glow. (Name kept from earlier iterations so every call site keeps working.)
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color glowColor;
  final Color borderColor;
  final bool emphasized;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.glowColor = AppColors.primary,
    this.borderColor = AppColors.border,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusLg);
    if (!emphasized) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.92),
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0x33FF7A3D), AppColors.accentCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(0.22), blurRadius: 30, spreadRadius: -8, offset: const Offset(0, 10)),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 1.4),
        ),
        child: child,
      ),
    );
  }
}
