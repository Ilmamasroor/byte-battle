import 'package:flutter_test/flutter_test.dart';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/features/battle/presentation/state/battle_controller.dart';

BattleInfo _b(String id, String concept, String type) => BattleInfo(
    id: id,
    conceptId: concept,
    title: id,
    description: '',
    battleType: type,
    difficulty: 'EASY',
    totalQuestions: 5,
    timeLimitSeconds: 300,
    totalLives: 3);

void main() {
  test('pickBattle chooses the boss or the regular battle of the concept', () {
    final all = [_b('quiz-a', 'a', 'QUIZ'), _b('boss-a', 'a', 'BOSS_BATTLE'), _b('quiz-b', 'b', 'SURVIVAL')];
    expect(pickBattle(all, 'a', boss: false)?.id, 'quiz-a');
    expect(pickBattle(all, 'a', boss: true)?.id, 'boss-a');
    expect(pickBattle(all, 'b', boss: true), isNull);
    expect(pickBattle(all, 'zzz', boss: false), isNull);
  });

  test('question options are parsed from the backend JSON string, or a list, or garbage', () {
    final fromString = BattleQuestionModel.fromJson(
        {'id': 'q', 'questionText': 'T', 'questionType': 'MCQ', 'options': '["a", "b", "c"]', 'points': 10, 'displayOrder': 1});
    expect(fromString.options, ['a', 'b', 'c']);
    expect(BattleQuestionModel.fromJson({'id': 'q', 'options': ['x', 'y']}).options, ['x', 'y']);
    expect(BattleQuestionModel.fromJson({'id': 'q', 'options': 'not json'}).options, isEmpty);
    expect(BattleQuestionModel.fromJson({'id': 'q'}).options, isEmpty);
  });

  test('accuracy is the share of answered questions that were correct', () {
    const o = BattleOutcome(
        result: BattleResultModel(30, 5, 3, false),
        answered: 4,
        wrong: 1,
        boss: false,
        conceptId: 'a',
        conceptName: 'A',
        battleTitle: 'T');
    expect(o.accuracy, 75);
  });
}
