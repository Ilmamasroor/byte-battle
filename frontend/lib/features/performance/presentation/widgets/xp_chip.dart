import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/backend_api.dart';

/// The "⚡ N XP" pill in screen headers, showing the learner's real XP (`GET /api/gamification/me`).
/// While loading, or if the call fails, it shows a dash rather than a made-up number.
class LiveXpChip extends StatefulWidget {
  const LiveXpChip({super.key});

  @override
  State<LiveXpChip> createState() => _LiveXpChipState();
}

class _LiveXpChipState extends State<LiveXpChip> {
  int? _xp;

  @override
  void initState() {
    super.initState();
    BackendApi.instance.gamification().then((g) {
      if (mounted) setState(() => _xp = g.xp);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 4),
          Text(_xp == null ? '— XP' : '$_xp XP', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// A friendly empty state with an optional call to action, for screens that have no evidence to show yet.
class EmptyEvidence extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyEvidence({super.key, required this.title, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, color: AppColors.accentCyan, size: 36),
            const SizedBox(height: AppDimensions.spacingMd),
            Text(title, style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spacingSm),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            if (actionLabel != null) ...[
              const SizedBox(height: AppDimensions.spacingLg),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
