import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/curriculum_tree.dart';
import '../widgets/curriculum_body.dart';
import '../widgets/roadmap_step.dart';

/// RoadmapScreen: the learner's curriculum roadmap, one step per backend domain in curriculum order, with a
/// status derived from the learner's real progress (`/api/learning`).
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  static RoadmapStepStatus _status(DomainStatus s) => switch (s) {
        DomainStatus.completed => RoadmapStepStatus.completed,
        DomainStatus.current => RoadmapStepStatus.current,
        DomainStatus.notStarted => RoadmapStepStatus.notStarted,
      };

  void _openDomain(BuildContext context, String domain) {
    Navigator.of(context).pushNamed(
      RouteNames.domainList,
      arguments: {'domainName': domain},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Roadmap', style: AppTextStyles.heading2),
      ),
      body: SafeArea(
        child: CurriculumBody(
          emptyMessage: 'The curriculum has no domains yet.',
          builder: (context, tree) {
            if (tree.domains.isEmpty) return null;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.screenPadding),
              children: [
                for (int i = 0; i < tree.domains.length; i++) ...[
                  RoadmapStep(
                    domainName: tree.domains[i].domain.name,
                    status: _status(tree.statusOf(tree.domains[i])),
                    onTap: () => _openDomain(context, tree.domains[i].domain.name),
                  ),
                  if (i != tree.domains.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(left: 29),
                          width: 2,
                          height: 20,
                          color: tree.statusOf(tree.domains[i]) == DomainStatus.completed
                              ? AppColors.success.withOpacity(0.5)
                              : AppColors.border,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
