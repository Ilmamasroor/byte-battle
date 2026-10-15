import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/helpers.dart';
import '../widgets/topic_card.dart';

typedef _Topic = ({String name, String difficulty, double progress});

/// TopicListScreen — the topics within one curriculum domain (e.g.
/// "Fundamentals", "OOP", "Collections"... under "Java"). Which domain
/// is showing comes from the `domainName` route argument set by
/// [DomainListScreen]; falls back to "Java" so this screen still works
/// if opened directly with no arguments.
class TopicListScreen extends StatelessWidget {
  final String? domainName;

  const TopicListScreen({super.key, this.domainName});

  // TODO: replace with data from CurriculumRepository once the
  // `/api/curriculum/domains/{id}/topics` endpoint exists — this is
  // placeholder data matching the product's stated curriculum spec.
  static const Map<String, List<_Topic>> _topicsByDomain = {
    'Java': [
      (name: 'Fundamentals', difficulty: 'Beginner', progress: 0.9),
      (name: 'OOP', difficulty: 'Beginner', progress: 0.75),
      (name: 'Exception Handling', difficulty: 'Beginner', progress: 0.4),
      (name: 'Collections', difficulty: 'Intermediate', progress: 0.5),
      (name: 'Generics', difficulty: 'Intermediate', progress: 0.2),
      (name: 'Streams', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Multithreading & Concurrency', difficulty: 'Advanced', progress: 0.0),
      (name: 'JVM', difficulty: 'Advanced', progress: 0.0),
      (name: 'Advanced Java', difficulty: 'Advanced', progress: 0.0),
    ],
    'Backend Development': [
      (name: 'REST APIs', difficulty: 'Beginner', progress: 0.6),
      (name: 'Authentication & Authorization', difficulty: 'Intermediate', progress: 0.3),
      (name: 'Caching', difficulty: 'Intermediate', progress: 0.1),
      (name: 'Message Queues', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Microservices', difficulty: 'Advanced', progress: 0.0),
      (name: 'API Gateways', difficulty: 'Advanced', progress: 0.0),
      (name: 'Rate Limiting', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Logging & Monitoring', difficulty: 'Intermediate', progress: 0.0),
    ],
    'Data Structures & Algorithms': [
      (name: 'Arrays', difficulty: 'Beginner', progress: 0.8),
      (name: 'Strings', difficulty: 'Beginner', progress: 0.7),
      (name: 'Linked Lists', difficulty: 'Beginner', progress: 0.5),
      (name: 'Stacks & Queues', difficulty: 'Beginner', progress: 0.4),
      (name: 'Trees', difficulty: 'Intermediate', progress: 0.3),
      (name: 'Graphs', difficulty: 'Intermediate', progress: 0.1),
      (name: 'Recursion', difficulty: 'Intermediate', progress: 0.2),
      (name: 'Dynamic Programming', difficulty: 'Advanced', progress: 0.0),
      (name: 'Sorting', difficulty: 'Beginner', progress: 0.6),
      (name: 'Searching', difficulty: 'Beginner', progress: 0.6),
      (name: 'Hashing', difficulty: 'Intermediate', progress: 0.2),
      (name: 'Greedy Algorithms', difficulty: 'Advanced', progress: 0.0),
    ],
    'DBMS & SQL': [
      (name: 'ER Modeling', difficulty: 'Beginner', progress: 0.5),
      (name: 'Normalization', difficulty: 'Intermediate', progress: 0.2),
      (name: 'Joins', difficulty: 'Beginner', progress: 0.3),
      (name: 'Indexing', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Transactions', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Query Optimization', difficulty: 'Advanced', progress: 0.0),
      (name: 'NoSQL Basics', difficulty: 'Intermediate', progress: 0.0),
    ],
    'Operating Systems': [
      (name: 'Processes & Threads', difficulty: 'Beginner', progress: 0.0),
      (name: 'Scheduling', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Memory Management', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Deadlocks', difficulty: 'Advanced', progress: 0.0),
      (name: 'File Systems', difficulty: 'Beginner', progress: 0.0),
      (name: 'Concurrency', difficulty: 'Advanced', progress: 0.0),
    ],
    'Computer Networks': [
      (name: 'OSI Model', difficulty: 'Beginner', progress: 0.0),
      (name: 'TCP/IP', difficulty: 'Beginner', progress: 0.0),
      (name: 'HTTP/HTTPS', difficulty: 'Beginner', progress: 0.0),
      (name: 'DNS', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Load Balancing', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Network Security', difficulty: 'Advanced', progress: 0.0),
    ],
    'System Design': [
      (name: 'Scalability', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Load Balancing', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Caching', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Database Sharding', difficulty: 'Advanced', progress: 0.0),
      (name: 'CAP Theorem', difficulty: 'Advanced', progress: 0.0),
      (name: 'Message Queues', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Rate Limiting', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Case Studies', difficulty: 'Advanced', progress: 0.0),
    ],
    'Technical Interview Preparation': [
      (name: 'Behavioral Questions', difficulty: 'Beginner', progress: 0.0),
      (name: 'Whiteboarding', difficulty: 'Intermediate', progress: 0.0),
      (name: 'System Design Interviews', difficulty: 'Advanced', progress: 0.0),
      (name: 'Mock Interviews', difficulty: 'Intermediate', progress: 0.0),
      (name: 'Resume Review', difficulty: 'Beginner', progress: 0.0),
    ],
  };

  static const String _defaultDomain = 'Java';

  @override
  Widget build(BuildContext context) {
    Helpers.noApiYet('TopicListScreen');
    final effectiveDomain =
        (domainName != null && _topicsByDomain.containsKey(domainName)) ? domainName! : _defaultDomain;
    final topics = _topicsByDomain[effectiveDomain] ?? _topicsByDomain[_defaultDomain]!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(effectiveDomain, style: AppTextStyles.heading2),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spacingMd),
        itemBuilder: (context, index) {
          final topic = topics[index];
          return TopicCard(
            name: topic.name,
            difficulty: topic.difficulty,
            progress: topic.progress,
            onTap: () {
              // TODO: navigate to a concept list filtered by this topic
              // once that endpoint exists — for now this opens the
              // general concept list, the closest existing screen that
              // lists learnable concepts.
              Navigator.of(context).pushNamed(RouteNames.conceptList);
            },
          );
        },
      ),
    );
  }
}
