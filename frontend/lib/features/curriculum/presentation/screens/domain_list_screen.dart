import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/curriculum_body.dart';
import '../widgets/domain_card.dart';

/// DomainListScreen: every curriculum domain from `/api/curriculum/domains`, with its real topic count and the
/// learner's progress across its concepts. Reached from the dashboard or by tapping a [RoadmapScreen] step (in
/// which case [highlightDomain] calls that card out).
class DomainListScreen extends StatelessWidget {
  final String? highlightDomain;

  const DomainListScreen({super.key, this.highlightDomain});

  static IconData _iconFor(String slug) {
    switch (slug) {
      case 'java-programming':
        return Icons.coffee_rounded;
      case 'data-structures-algorithms':
        return Icons.account_tree_rounded;
      case 'dbms-sql':
        return Icons.storage_rounded;
      case 'operating-systems':
        return Icons.memory_rounded;
      case 'computer-networks':
        return Icons.lan_rounded;
      case 'system-design':
        return Icons.architecture_rounded;
      case 'technical-interview-prep':
        return Icons.record_voice_over_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  void _openTopics(BuildContext context, String domainId, String domainName) {
    Navigator.of(context).pushNamed(
      RouteNames.topicList,
      arguments: {'domainId': domainId, 'domainName': domainName},
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
        title: const Text('Domains', style: AppTextStyles.heading2),
      ),
      body: CurriculumBody(
        emptyMessage: 'The curriculum has no domains yet.',
        builder: (context, tree) {
          if (tree.domains.isEmpty) return null;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            itemCount: tree.domains.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
            itemBuilder: (context, index) {
              final node = tree.domains[index];
              return DomainCard(
                icon: _iconFor(node.domain.slug),
                name: node.domain.name,
                topicCount: node.topics.length,
                progress: tree.domainProgress(node),
                highlighted: highlightDomain != null && highlightDomain == node.domain.name,
                onTap: () => _openTopics(context, node.domain.id, node.domain.name),
              );
            },
          );
        },
      ),
    );
  }
}
