import 'package:flutter/material.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'scene_models.dart';

/// A teaser on a concept's page: "Watch it happen", naming the animated scene for this concept and what kind of
/// view it is (inside the computer, a data-structure walkthrough, a protocol conversation...). Tapping opens it.
class ScenePreviewCard extends StatelessWidget {
  final String conceptId;
  const ScenePreviewCard({super.key, required this.conceptId});

  static (String, IconData, Color) _look(SceneKind k) {
    switch (k) {
      case SceneKind.computer:
        return ('INSIDE YOUR COMPUTER', Icons.memory_rounded, AppColors.primary);
      case SceneKind.structure:
        return ('STEP-BY-STEP WALKTHROUGH', Icons.account_tree_rounded, AppColors.accentCyan);
      case SceneKind.table:
        return ('WATCH THE DATA MOVE', Icons.table_chart_rounded, AppColors.success);
      case SceneKind.sequence:
        return ('WHO TALKS TO WHOM', Icons.swap_calls_rounded, AppColors.orchid);
      case SceneKind.flow:
        return ('THE PLAYBOOK', Icons.checklist_rounded, AppColors.xp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SceneDoc?>(
      future: SceneRepository.forConcept(conceptId),
      builder: (context, snap) {
        final doc = snap.data;
        if (doc == null) return const SizedBox.shrink();
        final (label, icon, color) = _look(doc.kind);
        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: () => Navigator.of(context).pushNamed(RouteNames.explore, arguments: {'conceptId': conceptId}),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                gradient: LinearGradient(colors: [color.withOpacity(0.2), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: color.withOpacity(0.6)),
              ),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: AppColors.onAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label, style: AppTextStyles.eyebrow.copyWith(color: color, fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyBold.copyWith(fontSize: 14.5, height: 1.3)),
                    const SizedBox(height: 3),
                    Text('${doc.steps.length} steps, narrated by Bit', style: AppTextStyles.caption),
                  ]),
                ),
                Icon(Icons.play_circle_fill_rounded, color: color, size: 34),
              ]),
            ),
          ),
        );
      },
    );
  }
}
