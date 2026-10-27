import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Question card shown at the top of the Technical Interview screen —
/// a small purple topic tag ("EXPLAIN BINARY SEARCH") above the
/// full question text.
class InterviewQuestionCard extends StatelessWidget {
  final String topicTag;
  final String question;

  const InterviewQuestionCard({
    super.key,
    required this.topicTag,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topicTag.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(question, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}
