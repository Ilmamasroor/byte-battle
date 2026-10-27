import '../../../concepts/data/models/concept_model.dart';
import 'domain_model.dart';
import 'topic_model.dart';

class TopicNode {
  final TopicModel topic;
  final List<ConceptModel> concepts;
  const TopicNode(this.topic, this.concepts);
}

class DomainNode {
  final DomainModel domain;
  final List<TopicNode> topics;
  const DomainNode(this.domain, this.topics);

  Iterable<ConceptModel> get concepts => topics.expand((t) => t.concepts);
}

enum DomainStatus { completed, current, notStarted }

/// The whole curriculum (domains -> topics -> concepts) plus the learner's per-concept progress (0-100).
class CurriculumTree {
  final List<DomainNode> domains;
  final Map<String, int> progressByConcept;
  const CurriculumTree(this.domains, [this.progressByConcept = const {}]);

  int conceptProgress(String conceptId) => progressByConcept[conceptId] ?? 0;

  double _average(Iterable<ConceptModel> concepts) {
    final list = concepts.toList();
    if (list.isEmpty) return 0;
    final sum = list.fold<int>(0, (a, c) => a + conceptProgress(c.id));
    return sum / list.length / 100;
  }

  double topicProgress(TopicNode t) => _average(t.concepts);
  double domainProgress(DomainNode d) => _average(d.concepts);

  DomainNode? domainById(String? id) {
    for (final d in domains) {
      if (d.domain.id == id) return d;
    }
    return null;
  }

  DomainNode? domainByName(String? name) {
    for (final d in domains) {
      if (d.domain.name == name) return d;
    }
    return null;
  }

  TopicNode? topicById(String? id) {
    for (final d in domains) {
      for (final t in d.topics) {
        if (t.topic.id == id) return t;
      }
    }
    return null;
  }

  /// A domain is completed once every concept is at 100%; the first unfinished domain that has been started
  /// (or, failing that, the first unfinished one) is "current"; the rest have simply not been started.
  /// Nothing is locked: the backend lets a learner open any concept.
  DomainStatus statusOf(DomainNode d) {
    if (_isDone(d)) return DomainStatus.completed;
    final firstOpen = domains.firstWhere((x) => !_isDone(x), orElse: () => d);
    return identical(firstOpen, d) ? DomainStatus.current : DomainStatus.notStarted;
  }

  bool _isDone(DomainNode d) => d.concepts.isNotEmpty && d.concepts.every((c) => conceptProgress(c.id) >= 100);

  /// Backend `EASY|MEDIUM|HARD` as the Beginner / Intermediate / Advanced labels the badges use; a topic takes
  /// the hardest level among its concepts.
  static String levelLabel(Iterable<ConceptModel> concepts) {
    var rank = 0;
    for (final c in concepts) {
      rank = rank < _rank(c.difficulty) ? _rank(c.difficulty) : rank;
    }
    return const ['Beginner', 'Beginner', 'Intermediate', 'Advanced'][rank];
  }

  static int _rank(String? d) {
    switch ((d ?? '').toUpperCase()) {
      case 'HARD':
      case 'ADVANCED':
        return 3;
      case 'MEDIUM':
      case 'INTERMEDIATE':
        return 2;
      default:
        return 1;
    }
  }
}
