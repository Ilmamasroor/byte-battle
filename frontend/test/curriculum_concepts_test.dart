import 'package:byte_battle/features/concepts/data/models/concept_model.dart';
import 'package:byte_battle/features/curriculum/data/models/curriculum_tree.dart';
import 'package:byte_battle/features/curriculum/data/models/domain_model.dart';
import 'package:byte_battle/features/curriculum/data/models/topic_model.dart';
import 'package:byte_battle/features/learning/explanation/data/models/explanation_model.dart';
import 'package:flutter_test/flutter_test.dart';

ConceptModel _c(String id, String d) => ConceptModel(id: id, name: id, difficulty: d);

DomainNode _domain(String id, List<ConceptModel> concepts) => DomainNode(
      DomainModel(id: id, name: id),
      [TopicNode(TopicModel(id: 't$id', domainId: id, name: 't$id'), concepts)],
    );

void main() {
  test('explanation model reads grounded / personalized / fallback flags', () {
    final ok = ExplanationModel.fromJson({
      'success': true,
      'content': ' A race condition... ',
      'metadata': {'grounded': true, 'personalized': true},
      'fallback': false,
    });
    expect(ok.content, 'A race condition...');
    expect(ok.grounded && ok.personalized, isTrue);
    expect(ok.fallback, isFalse);

    final fb = ExplanationModel.fromJson({'success': false, 'content': 'basic', 'fallback': true});
    expect(fb.fallback, isTrue);
  });

  test('difficulty labels', () {
    expect(difficultyLabel('HARD'), 'Hard');
    expect(difficultyLabel(null), 'Medium');
    expect(CurriculumTree.levelLabel([_c('a', 'EASY'), _c('b', 'HARD')]), 'Advanced');
    expect(CurriculumTree.levelLabel([_c('a', 'EASY')]), 'Beginner');
  });

  test('progress and domain status come from learner progress, nothing is locked', () {
    final a = _domain('a', [_c('1', 'EASY'), _c('2', 'EASY')]);
    final b = _domain('b', [_c('3', 'EASY')]);
    final c = _domain('c', [_c('4', 'EASY')]);
    final tree = CurriculumTree([a, b, c], {'1': 100, '2': 100, '3': 50});

    expect(tree.domainProgress(a), 1.0);
    expect(tree.domainProgress(b), 0.5);
    expect(tree.domainProgress(c), 0.0);
    expect(tree.statusOf(a), DomainStatus.completed);
    expect(tree.statusOf(b), DomainStatus.current);
    expect(tree.statusOf(c), DomainStatus.notStarted);
    expect(tree.topicById('tb')?.concepts.single.id, '3');
    expect(tree.domainByName('c'), same(c));
  });

  test('concept model parses the backend DTO including topicId', () {
    final m = ConceptModel.fromJson({
      'id': 'x', 'topicId': 'tp', 'name': 'Race Conditions', 'difficulty': 'HARD', 'displayOrder': 3, 'slug': 'race-conditions',
    });
    expect(m.topicId, 'tp');
    expect(m.displayOrder, 3);
  });
}
