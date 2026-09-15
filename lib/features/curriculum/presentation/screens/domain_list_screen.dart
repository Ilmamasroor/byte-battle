import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../widgets/domain_card.dart';

/// DomainListScreen — the top-level curriculum browser: every technical
/// domain in the curriculum, with a topic count and overall progress
/// for each. Reached either from the dashboard's "Explore Curriculum"
/// entry point or by tapping an unlocked step on [RoadmapScreen] (in
/// which case [highlightDomain] is passed so that step's card can be
/// called out).
class DomainListScreen extends StatelessWidget {
  final String? highlightDomain;

  const DomainListScreen({super.key, this.highlightDomain});

  // TODO: replace with data from CurriculumRepository once the
  // `/api/curriculum/domains` endpoint exists — this is placeholder
  // data matching the product's stated curriculum spec.
  static const _domains = [
    (icon: Icons.coffee_rounded, name: 'Java', topics: 9, progress: 0.62),
    (icon: Icons.dns_rounded, name: 'Backend Development', topics: 8, progress: 0.35),
    (
      icon: Icons.account_tree_rounded,
      name: 'Data Structures & Algorithms',
      topics: 12,
      progress: 0.48,
    ),
    (icon: Icons.storage_rounded, name: 'DBMS & SQL', topics: 7, progress: 0.20),
    (icon: Icons.memory_rounded, name: 'Operating Systems', topics: 6, progress: 0.0),
    (icon: Icons.lan_rounded, name: 'Computer Networks', topics: 6, progress: 0.0),
    (icon: Icons.architecture_rounded, name: 'System Design', topics: 8, progress: 0.0),
    (
      icon: Icons.record_voice_over_rounded,
      name: 'Technical Interview Preparation',
      topics: 5,
      progress: 0.0,
    ),
  ];

  void _openTopics(BuildContext context, String domainName) {
    Navigator.of(context).pushNamed(
      RouteNames.topicList,
      arguments: {'domainName': domainName},
    );
  }

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('DomainListScreen');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Domains', style: AppTextStyles.heading2),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: _domains.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          final domain = _domains[index];
          return DomainCard(
            icon: domain.icon,
            name: domain.name,
            topicCount: domain.topics,
            progress: domain.progress,
            highlighted: highlightDomain != null && highlightDomain == domain.name,
            onTap: () => _openTopics(context, domain.name),
          );
        },
      ),
    );
  }
}
