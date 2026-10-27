import 'package:byte_battle/core/models/backend_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SubmissionResult keeps hidden cases masked and parses the verdict', () {
    final r = SubmissionResult.fromJson({
      'submissionId': 's1',
      'status': 'FAILED',
      'executionTimeMs': 120,
      'testCasesPassed': 1,
      'testCasesTotal': 3,
      'errorMessage': null,
      'aiFeedback': null,
      'testCaseResults': [
        {'caseNumber': 1, 'passed': true, 'status': 'PASSED', 'hidden': false, 'timeMs': 5, 'input': '4', 'expectedOutput': '10', 'actualOutput': '10'},
        {'caseNumber': 2, 'passed': false, 'status': 'WRONG_ANSWER', 'hidden': true, 'timeMs': 7},
      ],
    });
    expect(r.allPassed, isFalse);
    expect(r.passed, 1);
    expect(r.total, 3);
    expect(r.errorMessage, '');
    expect(r.aiFeedback, '');
    expect(r.cases[1].hidden, isTrue);
    expect(r.cases[1].input, '');
  });

  test('DebugAttemptResult parses streak and next action', () {
    final a = DebugAttemptResult.fromJson({
      'passed': false,
      'status': 'FAILED',
      'testsPassed': 0,
      'testsTotal': 2,
      'errorCategory': 'LOGIC_ERROR',
      'hintsUsed': 1,
      'consecutiveFailures': 3,
      'nextAction': 'DIAGNOSE',
      'persistentWeakness': true,
      'testCaseResults': [],
    });
    expect(a.persistentWeakness, isTrue);
    expect(a.nextAction, 'DIAGNOSE');
    expect(a.consecutiveFailures, 3);
  });
}
