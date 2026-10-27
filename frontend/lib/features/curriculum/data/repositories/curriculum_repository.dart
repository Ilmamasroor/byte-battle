import '../../../../core/network/backend_api.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../models/curriculum_tree.dart';
import '../models/domain_model.dart';
import '../models/topic_model.dart';

/// Reads the curriculum from `/api/curriculum/*` and the learner's progress from `/api/learning`.
class CurriculumRepository {
  const CurriculumRepository();

  Future<CurriculumTree> load() async {
    final api = BackendApi.instance;
    final domains = (await api.curriculumDomains()).map(DomainModel.fromJson).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final nodes = await Future.wait(domains.map((d) async {
      final topics = (await api.curriculumTopics(d.id)).map(TopicModel.fromJson).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      final topicNodes = await Future.wait(topics.map((t) async {
        final concepts = (await api.curriculumConcepts(t.id)).map(ConceptModel.fromJson).toList()
          ..sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
        return TopicNode(t, concepts);
      }));
      return DomainNode(d, topicNodes);
    }));

    // Progress is a nice-to-have: the curriculum is still browsable if it cannot be read.
    final progress = <String, int>{};
    try {
      for (final p in await api.learningProgress()) {
        progress[p.conceptId] = p.completed ? 100 : p.progressPercentage;
      }
    } catch (_) {}
    return CurriculumTree(nodes, progress);
  }
}
