import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../widgets/roadmap_step.dart';

/// RoadmapScreen — the learner's overall curriculum roadmap as a
/// vertical step sequence, in the product's stated learning order:
/// Java -> DSA -> DBMS -> Operating Systems -> Computer Networks ->
/// System Design -> Technical Interviews.
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  // TODO: replace with data from CurriculumRepository once a
  // `/api/curriculum/roadmap` (or similar progress-aware) endpoint
  // exists — status is hardcoded here to demonstrate the three states.
  static const _steps = [
    (domain: 'Java', status: RoadmapStepStatus.completed),
    (domain: 'Data Structures & Algorithms', status: RoadmapStepStatus.current),
    (domain: 'DBMS & SQL', status: RoadmapStepStatus.locked),
    (domain: 'Operating Systems', status: RoadmapStepStatus.locked),
    (domain: 'Computer Networks', status: RoadmapStepStatus.locked),
    (domain: 'System Design', status: RoadmapStepStatus.locked),
    (domain: 'Technical Interview Preparation', status: RoadmapStepStatus.locked),
  ];

  void _openDomain(BuildContext context, String domain) {
    Navigator.of(context).pushNamed(
      RouteNames.domainList,
      arguments: {'domainName': domain},
    );
  }

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('RoadmapScreen');
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
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          children: [
            for (int i = 0; i < _steps.length; i++) ...[
              RoadmapStep(
                domainName: _steps[i].domain,
                status: _steps[i].status,
                onTap: () => _openDomain(context, _steps[i].domain),
              ),
              if (i != _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 29),
                      width: 2,
                      height: 20,
                      color: _steps[i].status == RoadmapStepStatus.completed
                          ? AppColors.success.withOpacity(0.5)
                          : AppColors.border,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
