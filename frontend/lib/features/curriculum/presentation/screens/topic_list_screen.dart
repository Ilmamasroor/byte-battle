import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/curriculum_tree.dart';
import '../widgets/curriculum_body.dart';
import '../widgets/topic_card.dart';

/// TopicListScreen: the topics of one domain, from `/api/curriculum/domains/{id}/topics`. The domain comes
/// from the `domainId` (or `domainName`) route argument set by the domain list; with neither, the first domain
/// is shown. Tapping a topic opens the concepts inside it.
class TopicListScreen extends StatelessWidget {
  final String? domainId;
  final String? domainName;

  const TopicListScreen({super.key, this.domainId, this.domainName});

  DomainNode? _resolve(CurriculumTree tree) =>
      tree.domainById(domainId) ?? tree.domainByName(domainName) ?? (tree.domains.isEmpty ? null : tree.domains.first);

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
        title: Text(domainName ?? 'Topics', style: AppTextStyles.heading2),
      ),
      body: CurriculumBody(
        emptyMessage: 'This domain has no topics yet.',
        builder: (context, tree) {
          final domain = _resolve(tree);
          if (domain == null || domain.topics.isEmpty) return null;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.screenPadding),
            itemCount: domain.topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
            itemBuilder: (context, index) {
              final node = domain.topics[index];
              return TopicCard(
                name: node.topic.name,
                difficulty: CurriculumTree.levelLabel(node.concepts),
                progress: tree.topicProgress(node),
                onTap: () => Navigator.of(context).pushNamed(
                  RouteNames.conceptList,
                  arguments: {'topicId': node.topic.id, 'topicName': node.topic.name},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
