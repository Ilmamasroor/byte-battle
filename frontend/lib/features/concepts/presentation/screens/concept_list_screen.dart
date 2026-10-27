import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../curriculum/data/models/curriculum_tree.dart';
import '../../../curriculum/presentation/widgets/curriculum_body.dart';
import '../../data/models/concept_model.dart';

/// "Choose Your Concept": the real concepts from `/api/curriculum`, grouped by topic, each with the learner's
/// own progress. Opened with a [topicId] (from the topic list) it shows just that topic's concepts; opened from
/// the bottom nav it shows every concept.
class ConceptListScreen extends StatefulWidget {
  final String? topicId;
  final String? topicName;

  const ConceptListScreen({super.key, this.topicId, this.topicName});

  @override
  State<ConceptListScreen> createState() => _ConceptListScreenState();
}

class _ConceptListScreenState extends State<ConceptListScreen> {
  final int _navIndex = 1;

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(RouteNames.bossBattleIntro);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(RouteNames.coding);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        break;
      default:
        break;
    }
  }

  static String _progressLabel(int percent) =>
      percent >= 100 ? 'Completed' : (percent <= 0 ? 'Not started' : 'Progress $percent%');

  Widget _conceptTile(ConceptModel c, int percent) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: () => Navigator.of(context).pushNamed(
        RouteNames.conceptDetail,
        arguments: {'conceptId': c.id},
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name ?? 'Concept', style: AppTextStyles.bodyBold),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.difficulty(difficultyLabel(c.difficulty)).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Text(difficultyLabel(c.difficulty),
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.difficulty(difficultyLabel(c.difficulty)), fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text(_progressLabel(percent), style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget? _list(BuildContext context, CurriculumTree tree) {
    final topicId = widget.topicId;
    final topics = [
      for (final d in tree.domains)
        for (final t in d.topics)
          if (topicId == null || t.topic.id == topicId) t,
    ].where((t) => t.concepts.isNotEmpty).toList();
    if (topics.isEmpty) return null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      children: [
        for (final t in topics) ...[
          if (topicId == null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingSm, bottom: AppDimensions.spacingSm),
              child: Text(t.topic.name.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: AppColors.primaryLight)),
            ),
          for (final c in t.concepts) ...[
            _conceptTile(c, tree.conceptProgress(c.id)),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.topicId != null;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: scoped,
        title: Text(widget.topicName ?? 'Choose Your Concept', style: AppTextStyles.heading2),
      ),
      body: CurriculumBody(
        emptyMessage: 'No concepts are available here yet.',
        builder: _list,
      ),
    );
  }
}
