import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

enum StageStatus { completed, inProgress, locked }

class _Stage {
  final String label;
  final String status;
  final StageStatus state;
  final String? route;

  const _Stage(this.label, this.status, this.state, {this.route});
}

class LearningJourneyScreen extends StatelessWidget {
  const LearningJourneyScreen({super.key});

  static const _stages = [
    _Stage('Understand', 'Completed', StageStatus.completed,
        route: RouteNames.understand),
    _Stage('Explore', 'Completed', StageStatus.completed,
        route: RouteNames.explore),
    _Stage('Relate & Remember', 'Completed', StageStatus.completed,
        route: RouteNames.relate),
    _Stage('Challenge', '1/1 Questions', StageStatus.inProgress,
        route: RouteNames.battle),
    _Stage('Implement', 'Locked', StageStatus.locked, route: RouteNames.coding),
    _Stage('Boss Battle', 'Locked', StageStatus.locked,
        route: RouteNames.bossBattleIntro),
    _Stage('Interview', 'Locked', StageStatus.locked,
        route: RouteNames.interviewIntro),
  ];

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('LearningJourneyScreen', note: 'stage progress is hardcoded');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Your Learning Journey', style: AppTextStyles.heading2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _stages.length,
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  final isLast = index == _stages.length - 1;
                  return _StageTile(
                    stage: stage,
                    isLast: isLast,
                    onTap: stage.state == StageStatus.locked || stage.route == null
                        ? null
                        : () => Navigator.of(context).pushNamed(stage.route!),
                  );
                },
              ),
            ),
            Center(
              child: Text(
                'Complete all stages to master this concept',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final _Stage stage;
  final bool isLast;
  final VoidCallback? onTap;

  const _StageTile({required this.stage, required this.isLast, this.onTap});

  Color get _dotColor {
    switch (stage.state) {
      case StageStatus.completed:
        return AppColors.success;
      case StageStatus.inProgress:
        return AppColors.warning;
      case StageStatus.locked:
        return AppColors.border;
    }
  }

  IconData get _icon {
    switch (stage.state) {
      case StageStatus.completed:
        return Icons.check_rounded;
      case StageStatus.inProgress:
        return Icons.play_arrow_rounded;
      case StageStatus.locked:
        return Icons.lock_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _dotColor.withOpacity(stage.state == StageStatus.locked ? 0.15 : 1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon,
                      size: 16,
                      color: stage.state == StageStatus.locked
                          ? AppColors.textHint
                          : AppColors.white),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stage.label, style: AppTextStyles.bodyBold),
                    const SizedBox(height: 2),
                    Text(stage.status,
                        style: AppTextStyles.caption.copyWith(color: _dotColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
