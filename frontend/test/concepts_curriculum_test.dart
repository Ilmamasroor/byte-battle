import 'package:byte_battle/features/concepts/data/models/concept_model.dart';
import 'package:byte_battle/features/curriculum/data/models/curriculum_tree.dart';
import 'package:byte_battle/features/curriculum/data/models/domain_model.dart';
import 'package:byte_battle/features/curriculum/data/models/topic_model.dart';
import 'package:byte_battle/features/learning/explanation/data/models/explanation_model.dart';
import 'package:flutter_test/flutter_test.dart';

DomainNode _domain(String id, List<ConceptModel> cs) => DomainNode(
    DomainModel(id: id, name: id), [TopicNode(TopicModel(id: 't$id', domainId: id, name: 't'), cs)]);

void main() {
  test('difficultyLabel formats backend enums', () {
    expect(difficultyLabel('HARD'), 'Hard');
    expect(difficultyLabel(null), 'Medium');
  });

  test('curriculum progress and domain status come from learning progress', () {
    const a = ConceptModel(id: 'a', difficulty: 'EASY');
    const b = ConceptModel(id: 'b', difficulty: 'HARD');
    final tree = CurriculumTree([_domain('d1', [a]), _domain('d2', [b])], {'a': 100, 'b': 50});
    expect(tree.statusOf(tree.domains[0]), DomainStatus.completed);
    expect(tree.statusOf(tree.domains[1]), DomainStatus.current);
    expect(tree.domainProgress(tree.domains[1]), 0.5);
    expect(CurriculumTree.levelLabel([a, b]), 'Advanced');
  });

  test('explanation model reads grounded/fallback flags', () {
    final e = ExplanationModel.fromJson({
      'success': true, 'content': ' hi ', 'fallback': false,
      'metadata': {'grounded': true, 'personalized': true},
    });
    expect(e.content, 'hi');
    expect(e.grounded && e.personalized && !e.fallback, isTrue);
    expect(ExplanationModel.fromJson({'success': false, 'content': 'x', 'fallback': true}).fallback, isTrue);
  });
}
