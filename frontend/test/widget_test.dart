import 'package:byte_battle/app/app.dart';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BytlBattleApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  // Payloads shaped exactly like the Spring backend's DTOs (see e2e_smoke.py).
  test('battle start / answer models parse backend JSON', () {
    final q = {'id': 'q1', 'questionText': 'T?', 'questionType': 'MCQ', 'options': '["a","b"]', 'points': 10, 'displayOrder': 1};
    final start = BattleStart.fromJson({'sessionId': 's1', 'firstQuestion': q, 'remainingLives': 3, 'timeLimitSeconds': 60});
    expect(start.sessionId, 's1');
    expect(start.firstQuestion.options.length, 2);
    final res = BattleAnswerResult.fromJson({
      'correct': true, 'pointsEarned': 10, 'remainingLives': 3, 'currentScore': 10, 'sessionCompleted': false, 'nextQuestion': q,
    });
    expect(res.correct, isTrue);
    expect(res.nextQuestion, isNotNull);
  });

  test('coding submission model parses backend JSON', () {
    final r = SubmissionResult.fromJson({
      'submissionId': 'x', 'status': 'FAILED', 'executionTimeMs': 12, 'testCasesPassed': 1, 'testCasesTotal': 3,
      'testCaseResults': [
        {'caseNumber': 1, 'passed': true, 'status': 'PASSED', 'hidden': false, 'timeMs': 3, 'input': '1', 'expectedOutput': '2', 'actualOutput': '2'},
      ],
    });
    expect(r.passed, 1);
    expect(r.total, 3);
    expect(r.cases.single.passed, isTrue);
  });

  test('visualization model reads both response shapes', () {
    final flat = VisualizationModel.fromJson({'title': 't', 'schedules': [], 'hazards': [], 'fixSuggestion': 'lock it'});
    final nested = VisualizationModel.fromJson({'title': 't', 'visualization': {'schedules': [], 'hazards': [], 'fixSuggestion': 'lock it'}});
    expect(flat.fixSuggestion, 'lock it');
    expect(nested.fixSuggestion, 'lock it');
  });
}
