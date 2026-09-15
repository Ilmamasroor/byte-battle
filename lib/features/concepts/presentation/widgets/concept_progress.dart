import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// One step in the 7-stage learning flow shown by [ConceptProgress]:
/// Concept -> Understand -> Visualize -> Relate -> Remember -> Battle
/// -> Coding.
enum ConceptStage { concept, understand, visualize, relate, remember, battle, coding }

/// Horizontal stepper used at the top of every screen in a concept's
/// learning flow (see the "Concept / Understand / Visualize / Relate /
/// Remember / Battle / Coding" reference header). Completed stages show
/// a checkmark; the current stage shows its own icon in a highlighted
/// ring; anything after that shows its own icon dimmed.
///
/// A stage is tappable only when [routes] has a non-null route for it
/// *and* it isn't further ahead than [current] — this is what keeps
/// navigation from ever jumping the person into a stage/screen out of
/// order.
class ConceptProgress extends StatelessWidget {
  final ConceptStage current;
  final Map<ConceptStage, String?> routes;
  /// Carried forward as route arguments (`{'conceptId': conceptId}`) when
  /// navigating between stages, so e.g. tapping "Relate" from the
  /// Understand screen opens the Relate screen for the *same* concept
  /// instead of falling back to the default demo concept.
  final String? conceptId;

  const ConceptProgress({
    super.key,
    required this.current,
    this.routes = const {},
    this.conceptId,
  });

  static const _stages = ConceptStage.values;

  static const _icons = {
    ConceptStage.concept: Icons.check_rounded,
    ConceptStage.understand: Icons.menu_book_rounded,
    ConceptStage.visualize: Icons.visibility_outlined,
    ConceptStage.relate: Icons.link_rounded,
    ConceptStage.remember: Icons.psychology_outlined,
    ConceptStage.battle: Icons.emoji_events_rounded,
    ConceptStage.coding: Icons.code_rounded,
  };

  static const _labels = {
    ConceptStage.concept: 'Concept',
    ConceptStage.understand: 'Understand',
    ConceptStage.visualize: 'Visualize',
    ConceptStage.relate: 'Relate',
    ConceptStage.remember: 'Remember',
    ConceptStage.battle: 'Battle',
    ConceptStage.coding: 'Coding',
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stages.indexOf(current);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: List.generate(_stages.length, (i) {
          final stage = _stages[i];
          final isDone = i < currentIndex;
          final isActive = i == currentIndex;
          final route = routes[stage];
          // Only reachable if it's a completed/current stage, or the
          // very next one and a route for it actually exists.
          final canTap = route != null && i <= currentIndex + 1;

          final color = isActive
              ? AppColors.accentCyan
              : (isDone ? AppColors.success : AppColors.textHint);

          final dot = InkWell(
            onTap: canTap
                ? () => Navigator.of(context).pushReplacementNamed(
                      route,
                      arguments: conceptId != null ? {'conceptId': conceptId} : null,
                    )
                : null,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.accentCyan.withOpacity(0.15) : Colors.transparent,
                    border: Border.all(color: color, width: isActive ? 2 : 1),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.accentCyan.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : _icons[stage],
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[stage]!,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );

          final wrapped = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: dot,
          );

          if (i == _stages.length - 1) return wrapped;

          return Row(
            children: [
              wrapped,
              Container(
                width: 18,
                height: 1,
                margin: const EdgeInsets.only(bottom: 14),
                color: isDone ? AppColors.success.withOpacity(0.5) : AppColors.border,
              ),
            ],
          );
        }),
      ),
    );
  }
}
