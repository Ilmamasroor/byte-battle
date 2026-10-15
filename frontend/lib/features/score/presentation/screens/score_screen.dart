import 'package:flutter/material.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/mastery_circle.dart';
import '../widgets/score_breakdown.dart';

/// "Battle Complete!" score summary screen. Matches the screenshot:
/// title bar, mastery circle + "Mastery Score / Improving" badge, four
/// metric breakdown bars, then VIEW PERFORMANCE cta.
///
/// Only ever reached as a post-battle result (pushed from
/// [BattleResultScreen]) — it no longer doubles as the "Profile" tab;
/// that's [ProfileScreen] now, reached directly from [AppBottomNav].
class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('ScoreScreen');
  }

  final int _navIndex = 2;

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(RouteNames.dashboard);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(RouteNames.conceptList);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(currentIndex: _navIndex, onTap: _onNavTap),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Battle Complete!', style: AppTextStyles.bodyBold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const MasteryCircle(score: 82),
                const SizedBox(width: AppDimensions.spacingMd),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mastery Score', style: AppTextStyles.bodyBold),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('Improving ↑',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXl),
            const ScoreBreakdown(
              label: 'Concept Understanding',
              value: 92,
              color: AppColors.success,
            ),
            const ScoreBreakdown(
              label: 'Implementation',
              value: 78,
              color: AppColors.primary,
            ),
            const ScoreBreakdown(
              label: 'Problem Solving',
              value: 85,
              color: AppColors.success,
            ),
            const ScoreBreakdown(
              label: 'Explanation',
              value: 55,
              color: AppColors.warning,
            ),
            const Spacer(),
            AppButton(
              label: 'VIEW PERFORMANCE',
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.performance),
            ),
          ],
        ),
      ),
    );
  }
}
