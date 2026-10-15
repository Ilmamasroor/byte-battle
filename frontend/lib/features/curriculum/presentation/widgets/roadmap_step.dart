import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';

/// Status of one step on [RoadmapScreen] — same completed/current/locked
/// idea as `ConceptProgress`'s `isDone`/`isActive` pattern, just
/// expressed as an enum here since each step also needs its own status
/// label text (not just an icon).
enum RoadmapStepStatus { completed, current, locked }

/// One row on the vertical curriculum roadmap (e.g. "Java", "Data
/// Structures & Algorithms"...) — a status icon, the domain name and a
/// status label, in the app's shared [GlowCard] look. Screens stack
/// these in a `Column` with a vertical connector line drawn between
/// them, the rotated equivalent of `ConceptProgress`'s horizontal
/// connector.
class RoadmapStep extends StatelessWidget {
  final String domainName;
  final RoadmapStepStatus status;
  final VoidCallback? onTap;

  const RoadmapStep({
    super.key,
    required this.domainName,
    required this.status,
    this.onTap,
  });

  IconData get _icon {
    switch (status) {
      case RoadmapStepStatus.completed:
        return Icons.check_rounded;
      case RoadmapStepStatus.current:
        return Icons.bolt_rounded;
      case RoadmapStepStatus.locked:
        return Icons.lock_outline_rounded;
    }
  }

  String get _label {
    switch (status) {
      case RoadmapStepStatus.completed:
        return 'Completed';
      case RoadmapStepStatus.current:
        return 'In Progress';
      case RoadmapStepStatus.locked:
        return 'Locked';
    }
  }

  Color get _color {
    switch (status) {
      case RoadmapStepStatus.completed:
        return AppColors.success;
      case RoadmapStepStatus.current:
        return AppColors.accentCyan;
      case RoadmapStepStatus.locked:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = status == RoadmapStepStatus.locked;
    final color = _color;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        glowColor: color,
        borderColor: isLocked ? AppColors.border : color,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == RoadmapStepStatus.current
                    ? AppColors.accentCyan.withOpacity(0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: status == RoadmapStepStatus.current ? 2 : 1,
                ),
                boxShadow: status == RoadmapStepStatus.current
                    ? [
                        BoxShadow(
                          color: AppColors.accentCyan.withOpacity(0.35),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Icon(_icon, size: 16, color: color),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(domainName, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(
                    _label,
                    style: AppTextStyles.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked)
              Icon(Icons.chevron_right_rounded, color: color)
            else
              const Icon(Icons.lock_outline_rounded, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
