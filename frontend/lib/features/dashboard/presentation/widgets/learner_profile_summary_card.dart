import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_card.dart';
import '../../../learner_profile/data/models/learner_profile_model.dart';

/// "Your Learning Profile" card on the dashboard — the one section here
/// backed by a real, already-wired endpoint (`GET /api/learner-profile`).
/// Three states:
///  - [isLoading]: skeleton row while the request is in flight.
///  - [profile] null (and not loading): learner hasn't saved a profile
///    yet (`404` from the backend) — prompts them to set one up.
///  - [profile] present: experience level / preferred language / daily
///    goal read straight off the API response.
class LearnerProfileSummaryCard extends StatelessWidget {
  final bool isLoading;
  final LearnerProfileModel? profile;
  final VoidCallback onTap;

  const LearnerProfileSummaryCard({
    super.key,
    required this.isLoading,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlowCard(
        glowColor: AppColors.primaryLight,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(child: _content()),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (isLoading) {
      return Text('Loading your learning profile…',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary));
    }

    final profile = this.profile;
    if (profile == null) {
      return Text(
        "You haven't set up your learning profile yet — tap to add it.",
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Learning Profile', style: AppTextStyles.bodyBold),
        const SizedBox(height: 4),
        Text(
          '${profile.experienceLevel.label} · '
          '${profile.preferredLanguage} · '
          '${profile.dailyGoalMinutes} min/day',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
