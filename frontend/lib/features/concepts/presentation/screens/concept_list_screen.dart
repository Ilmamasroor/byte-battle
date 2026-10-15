import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_bottom_nav.dart';

class ConceptListScreen extends StatefulWidget {
  const ConceptListScreen({super.key});

  @override
  State<ConceptListScreen> createState() => _ConceptListScreenState();
}

class _ConceptListScreenState extends State<ConceptListScreen> {
  int _navIndex = 1;

  // TODO: replace with data from ConceptRepository / concept_model.dart
  final _concepts = const [
    {'name': 'Arrays', 'level': 'Beginner', 'progress': 'Progress 20%'},
    {'name': 'Linked List', 'level': 'Beginner', 'progress': 'Not Started'},
    {'name': 'Binary Search', 'level': 'Beginner', 'progress': 'Progress 60%'},
    {'name': 'Recursion', 'level': 'Beginner', 'progress': 'Not Started'},
    {'name': 'SQL Joins', 'level': 'Beginner', 'progress': 'Progress 60%'},
  ];

  @override
  void initState() {
    super.initState();
    Helpers.noApiYet('ConceptListScreen');
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text('Choose Your Concept', style: AppTextStyles.heading2),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: _concepts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          final c = _concepts[index];
          return InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.conceptDetail),
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
                        Text(c['name']!, style: AppTextStyles.bodyBold),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusSm),
                              ),
                              child: Text(
                                c['level']!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primaryLight),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c['progress']!, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
