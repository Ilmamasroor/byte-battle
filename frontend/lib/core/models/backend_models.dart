import 'dart:convert';

/// Typed views of the Spring backend's JSON for the live learning loop (onboarding, battles, Judge0 coding,
/// debugging, AI interview, visualization, XP). Parsing is deliberately tolerant: a missing field becomes a
/// safe default instead of crashing a screen during a demo.

String _s(dynamic v, [String d = '']) => v == null ? d : v.toString();
int _i(dynamic v, [int d = 0]) => v is num ? v.toInt() : (int.tryParse(_s(v)) ?? d);
double _d(dynamic v, [double d = 0]) => v is num ? v.toDouble() : (double.tryParse(_s(v)) ?? d);
bool _b(dynamic v, [bool d = false]) => v is bool ? v : (v == null ? d : _s(v).toLowerCase() == 'true');
List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
List<String> _strings(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];

// ---------------------------------------------------------------- onboarding

class OnboardingOption {
  final String value;
  final String label;
  const OnboardingOption(this.value, this.label);
  factory OnboardingOption.fromJson(Map<String, dynamic> j) => OnboardingOption(_s(j['value']), _s(j['label']));
}

class OnboardingQuestionModel {
  final String id;
  final String prompt;
  final String type; // SINGLE_CHOICE | MULTI_SELECT | NUMBER_CHOICE
  final bool required;
  final int? maxSelections;
  final bool allowCustom;
  final List<OnboardingOption> options;

  const OnboardingQuestionModel({
    required this.id,
    required this.prompt,
    required this.type,
    required this.required,
    required this.maxSelections,
    required this.allowCustom,
    required this.options,
  });

  bool get isMulti => type == 'MULTI_SELECT';

  factory OnboardingQuestionModel.fromJson(Map<String, dynamic> j) => OnboardingQuestionModel(
        id: _s(j['id']),
        prompt: _s(j['prompt']),
        type: _s(j['type'], 'SINGLE_CHOICE'),
        required: _b(j['required']),
        maxSelections: j['maxSelections'] == null ? null : _i(j['maxSelections']),
        allowCustom: _b(j['allowCustom']),
        options: _maps(j['options']).map(OnboardingOption.fromJson).toList(),
      );
}

class OnboardingStatus {
  final bool completed;
  final bool hasLearnerProfile;
  final bool hasByteDna;
  const OnboardingStatus(this.completed, this.hasLearnerProfile, this.hasByteDna);
  factory OnboardingStatus.fromJson(Map<String, dynamic> j) =>
      OnboardingStatus(_b(j['completed']), _b(j['hasLearnerProfile']), _b(j['hasByteDna']));
}

// ------------------------------------------------------------------- concept

class ConceptInfo {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  const ConceptInfo({required this.id, required this.name, required this.description, required this.difficulty});
  factory ConceptInfo.fromJson(Map<String, dynamic> j) => ConceptInfo(
      id: _s(j['id']), name: _s(j['name']), description: _s(j['description']), difficulty: _s(j['difficulty'], 'MEDIUM'));
}

class LearningProgressModel {
  final String id;
  final String conceptId;
  final String currentStage;
  final bool completed;
  final int progressPercentage;
  const LearningProgressModel(this.id, this.conceptId, this.currentStage, this.completed, this.progressPercentage);
  factory LearningProgressModel.fromJson(Map<String, dynamic> j) => LearningProgressModel(
      _s(j['id']), _s(j['conceptId']), _s(j['currentStage'], 'UNDERSTAND'), _b(j['completed']), _i(j['progressPercentage']));
}

// -------------------------------------------------------------------- battle

class BattleInfo {
  final String id;
  final String conceptId;
  final String title;
  final String description;
  final String battleType;
  final String difficulty;
  final int totalQuestions;
  final int timeLimitSeconds;
  final int totalLives;
  const BattleInfo({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.description,
    required this.battleType,
    required this.difficulty,
    required this.totalQuestions,
    required this.timeLimitSeconds,
    required this.totalLives,
  });
  bool get isBoss => battleType == 'BOSS_BATTLE';
  factory BattleInfo.fromJson(Map<String, dynamic> j) => BattleInfo(
        id: _s(j['id']),
        conceptId: _s(j['conceptId']),
        title: _s(j['title']),
        description: _s(j['description']),
        battleType: _s(j['battleType']),
        difficulty: _s(j['difficulty'], 'MEDIUM'),
        totalQuestions: _i(j['totalQuestions']),
        timeLimitSeconds: _i(j['timeLimitSeconds']),
        totalLives: _i(j['totalLives'], 3),
      );
}

class BattleQuestionModel {
  final String id;
  final String text;
  final String type;
  final List<String> options;
  final int points;
  final int order;
  const BattleQuestionModel(this.id, this.text, this.type, this.options, this.points, this.order);

  factory BattleQuestionModel.fromJson(Map<String, dynamic> j) {
    // the backend stores the options as a JSON-array string
    var options = <String>[];
    final raw = j['options'];
    if (raw is List) {
      options = _strings(raw);
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        options = _strings(jsonDecode(raw));
      } catch (_) {
        options = [];
      }
    }
    return BattleQuestionModel(
        _s(j['id']), _s(j['questionText']), _s(j['questionType']), options, _i(j['points']), _i(j['displayOrder']));
  }
}

class BattleStart {
  final String sessionId;
  final BattleQuestionModel firstQuestion;
  final int lives;
  final int timeLimitSeconds;
  const BattleStart(this.sessionId, this.firstQuestion, this.lives, this.timeLimitSeconds);
  factory BattleStart.fromJson(Map<String, dynamic> j) => BattleStart(
        _s(j['sessionId']),
        BattleQuestionModel.fromJson(Map<String, dynamic>.from(j['firstQuestion'] as Map)),
        _i(j['remainingLives'], 3),
        _i(j['timeLimitSeconds']),
      );
}

class BattleAnswerResult {
  final bool correct;
  final int pointsEarned;
  final int lives;
  final int score;
  final bool sessionCompleted;
  final BattleQuestionModel? nextQuestion;
  const BattleAnswerResult(this.correct, this.pointsEarned, this.lives, this.score, this.sessionCompleted, this.nextQuestion);
  factory BattleAnswerResult.fromJson(Map<String, dynamic> j) => BattleAnswerResult(
        _b(j['correct']),
        _i(j['pointsEarned']),
        _i(j['remainingLives']),
        _i(j['currentScore']),
        _b(j['sessionCompleted']),
        j['nextQuestion'] is Map ? BattleQuestionModel.fromJson(Map<String, dynamic>.from(j['nextQuestion'] as Map)) : null,
      );
}

class BattleResultModel {
  final int finalScore;
  final int totalQuestions;
  final int correctAnswers;
  final bool won;
  const BattleResultModel(this.finalScore, this.totalQuestions, this.correctAnswers, this.won);
  factory BattleResultModel.fromJson(Map<String, dynamic> j) =>
      BattleResultModel(_i(j['finalScore']), _i(j['totalQuestions']), _i(j['correctAnswers']), _b(j['won']));
}

// -------------------------------------------------------------------- coding

class SampleCase {
  final int number;
  final String input;
  final String expectedOutput;
  const SampleCase(this.number, this.input, this.expectedOutput);
}

class CodingChallengeModel {
  final String id;
  final String conceptId;
  final String title;
  final String description;
  final String difficulty;
  final String language;
  final String inputDescription;
  final String outputDescription;
  final String constraints;
  final String starterCode;
  final List<SampleCase> samples;
  final int totalTestCases;
  const CodingChallengeModel({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.language,
    required this.inputDescription,
    required this.outputDescription,
    required this.constraints,
    required this.starterCode,
    required this.samples,
    required this.totalTestCases,
  });
  factory CodingChallengeModel.fromJson(Map<String, dynamic> j) => CodingChallengeModel(
        id: _s(j['id']),
        conceptId: _s(j['conceptId']),
        title: _s(j['title']),
        description: _s(j['description']),
        difficulty: _s(j['difficulty'], 'MEDIUM'),
        language: _s(j['language'], 'JAVA'),
        inputDescription: _s(j['inputDescription']),
        outputDescription: _s(j['outputDescription']),
        constraints: _s(j['constraints']),
        starterCode: _s(j['starterCode']),
        samples: _maps(j['sampleTestCases'])
            .map((m) => SampleCase(_i(m['caseNumber']), _s(m['input']), _s(m['expectedOutput'])))
            .toList(),
        totalTestCases: _i(j['totalTestCases']),
      );
}

class CaseOutcome {
  final int number;
  final bool passed;
  final String status;
  final bool hidden;
  final int timeMs;
  final String input;
  final String expected;
  final String actual;
  const CaseOutcome({
    required this.number,
    required this.passed,
    required this.status,
    required this.hidden,
    required this.timeMs,
    required this.input,
    required this.expected,
    required this.actual,
  });
  factory CaseOutcome.fromJson(Map<String, dynamic> j) => CaseOutcome(
        number: _i(j['caseNumber']),
        passed: _b(j['passed']),
        status: _s(j['status']),
        hidden: _b(j['hidden']),
        timeMs: _i(j['timeMs']),
        input: _s(j['input']),
        expected: _s(j['expectedOutput']),
        actual: _s(j['actualOutput']),
      );
}

class SubmissionResult {
  final String submissionId;
  final String status; // PASSED | FAILED | COMPILATION_ERROR | RUNTIME_ERROR | TIMEOUT
  final int executionTimeMs;
  final int passed;
  final int total;
  final String errorMessage;
  final String aiFeedback;
  final List<CaseOutcome> cases;
  const SubmissionResult({
    required this.submissionId,
    required this.status,
    required this.executionTimeMs,
    required this.passed,
    required this.total,
    required this.errorMessage,
    required this.aiFeedback,
    required this.cases,
  });
  bool get allPassed => status == 'PASSED';
  factory SubmissionResult.fromJson(Map<String, dynamic> j) => SubmissionResult(
        submissionId: _s(j['submissionId']),
        status: _s(j['status']),
        executionTimeMs: _i(j['executionTimeMs']),
        passed: _i(j['testCasesPassed']),
        total: _i(j['testCasesTotal']),
        errorMessage: _s(j['errorMessage']),
        aiFeedback: _s(j['aiFeedback']),
        cases: _maps(j['testCaseResults']).map(CaseOutcome.fromJson).toList(),
      );
}

// ----------------------------------------------------------------- debugging

class DebugExerciseModel {
  final String id;
  final String conceptId;
  final String title;
  final String description;
  final String language;
  final String buggyCode;
  final String bugCategory;
  final String difficulty;
  final int hintCount;
  final List<SampleCase> samples;
  const DebugExerciseModel({
    required this.id,
    required this.conceptId,
    required this.title,
    required this.description,
    required this.language,
    required this.buggyCode,
    required this.bugCategory,
    required this.difficulty,
    required this.hintCount,
    required this.samples,
  });
  factory DebugExerciseModel.fromJson(Map<String, dynamic> j) => DebugExerciseModel(
        id: _s(j['id']),
        conceptId: _s(j['conceptId']),
        title: _s(j['title']),
        description: _s(j['description']),
        language: _s(j['language'], 'JAVA'),
        buggyCode: _s(j['buggyCode']),
        bugCategory: _s(j['bugCategory']),
        difficulty: _s(j['difficulty'], 'MEDIUM'),
        hintCount: _i(j['hintCount']),
        samples: _maps(j['sampleTests'])
            .map((m) => SampleCase(_i(m['caseNumber']), _s(m['input']), _s(m['expectedOutput'])))
            .toList(),
      );
}

class DebugAttemptResult {
  final bool passed;
  final String status;
  final int testsPassed;
  final int testsTotal;
  final String errorCategory;
  final String errorMessage;
  final int hintsUsed;
  final int consecutiveFailures;
  final String nextAction; // CONTINUE | RETRY | DIAGNOSE
  final bool persistentWeakness;
  final List<CaseOutcome> cases;
  const DebugAttemptResult({
    required this.passed,
    required this.status,
    required this.testsPassed,
    required this.testsTotal,
    required this.errorCategory,
    required this.errorMessage,
    required this.hintsUsed,
    required this.consecutiveFailures,
    required this.nextAction,
    required this.persistentWeakness,
    required this.cases,
  });
  factory DebugAttemptResult.fromJson(Map<String, dynamic> j) => DebugAttemptResult(
        passed: _b(j['passed']),
        status: _s(j['status']),
        testsPassed: _i(j['testsPassed']),
        testsTotal: _i(j['testsTotal']),
        errorCategory: _s(j['errorCategory']),
        errorMessage: _s(j['errorMessage']),
        hintsUsed: _i(j['hintsUsed']),
        consecutiveFailures: _i(j['consecutiveFailures']),
        nextAction: _s(j['nextAction'], 'RETRY'),
        persistentWeakness: _b(j['persistentWeakness']),
        cases: _maps(j['testCaseResults']).map(CaseOutcome.fromJson).toList(),
      );
}

class DebugHint {
  final int level;
  final int totalLevels;
  final String hint;
  const DebugHint(this.level, this.totalLevels, this.hint);
  factory DebugHint.fromJson(Map<String, dynamic> j) => DebugHint(_i(j['level']), _i(j['totalLevels']), _s(j['hint']));
}

// ----------------------------------------------------------------- interview

class InterviewSessionModel {
  final String id;
  final String status;
  final int? score;
  const InterviewSessionModel(this.id, this.status, this.score);
  factory InterviewSessionModel.fromJson(Map<String, dynamic> j) =>
      InterviewSessionModel(_s(j['id']), _s(j['status']), j['score'] == null ? null : _i(j['score']));
}

class InterviewTurn {
  final String role; // ASSISTANT | USER
  final String content;
  final int? score;
  final String feedback;
  /// The five AI rubric dimensions (0-1) for the answer that was just evaluated, when present.
  final Map<String, double> rubric;
  const InterviewTurn(this.role, this.content, this.score, this.feedback, this.rubric);
  factory InterviewTurn.fromJson(Map<String, dynamic> j) {
    final rubric = <String, double>{};
    if (j['rubric'] is Map) {
      (j['rubric'] as Map).forEach((k, v) => rubric[k.toString()] = _d(v));
    }
    return InterviewTurn(_s(j['role']), _s(j['content']), j['score'] == null ? null : _i(j['score']), _s(j['feedback']), rubric);
  }
}

class InterviewResultModel {
  final int score;
  final int totalMessages;
  final String status;
  const InterviewResultModel(this.score, this.totalMessages, this.status);
  factory InterviewResultModel.fromJson(Map<String, dynamic> j) =>
      InterviewResultModel(_i(j['score']), _i(j['totalMessages']), _s(j['status']));
}

// ------------------------------------------------------------- visualization

class VizStep {
  final int index;
  final String thread;
  final String kind; // READ | WRITE | LOCK | UNLOCK | START | JOIN ...
  final String target;
  final String text;
  final bool hazard;
  final String? value;

  /// The thread's private copy of the value it last read ("local" in the backend simulation), if any.
  final String? local;
  final int opIndex;
  final int line;

  /// A LOCK attempt that could not proceed because another thread holds the lock ([waitingFor] names that thread).
  final bool blocked;
  final String? waitingFor;

  /// For a COMPUTE, the private copy before the calculation; for a WRITE, the shared value before it overwrote it.
  final String? before;

  /// A WRITE whose thread had read an older value than the one it replaced: the update that was lost.
  final bool stale;

  /// A LOCK / UNLOCK the synchronized version adds; it is not in the learner's own code.
  final bool synthetic;
  const VizStep({
    required this.index,
    required this.thread,
    required this.kind,
    required this.target,
    required this.text,
    required this.hazard,
    required this.value,
    this.local,
    this.opIndex = 0,
    this.line = 0,
    this.blocked = false,
    this.waitingFor,
    this.before,
    this.stale = false,
    this.synthetic = false,
  });
  factory VizStep.fromJson(Map<String, dynamic> j) => VizStep(
        index: _i(j['index']),
        thread: _s(j['thread']),
        kind: _s(j['kind']),
        target: _s(j['target']),
        text: _s(j['text']),
        hazard: _b(j['hazard']),
        value: j['value'] == null ? (j['wrote'] == null ? null : _s(j['wrote'])) : _s(j['value']),
        local: j['local'] == null ? null : _s(j['local']),
        opIndex: _i(j['opIndex']),
        line: _i(j['line']),
        blocked: _b(j['blocked']),
        waitingFor: j['waitingFor'] == null ? null : _s(j['waitingFor']),
        before: j['before'] == null ? null : _s(j['before']),
        stale: _b(j['stale']),
        synthetic: _b(j['synthetic']),
      );
}

class VizSchedule {
  final String kind; // SAFE | RACE | RACE_ALT | SYNC | DEADLOCK
  final List<String> threads;
  final List<VizStep> steps;
  final String? expected;
  final String? actual;

  /// One-line description of which interleaving this is, from the simulator.
  final String label;
  const VizSchedule(this.kind, this.threads, this.steps, this.expected, this.actual, {this.label = ''});

  static String? _firstValue(dynamic m) =>
      m is Map && m.isNotEmpty ? m.values.first.toString() : (m == null ? null : m.toString());

  factory VizSchedule.fromJson(Map<String, dynamic> j) => VizSchedule(
        _s(j['kind']),
        _strings(j['threads']),
        _maps(j['steps']).map(VizStep.fromJson).toList(),
        _firstValue(j['expected']),
        _firstValue(j['actual'] ?? j['finalValues']),
        label: j['label'] == null ? '' : _s(j['label']),
      );
}

/// How faithfully the teaching simulation represents the program it was given.
enum VizSupport { supported, partial, unsupported }

class VizSupportInfo {
  final VizSupport status;
  final List<String> reasons;
  const VizSupportInfo(this.status, [this.reasons = const []]);

  static const supported = VizSupportInfo(VizSupport.supported);

  factory VizSupportInfo.fromJson(dynamic j) {
    if (j is! Map) return supported; // an older backend sent no verdict
    final status = switch (_s(j['status'])) {
      'unsupported' => VizSupport.unsupported,
      'partial' => VizSupport.partial,
      _ => VizSupport.supported,
    };
    return VizSupportInfo(status, _strings(j['reasons']));
  }
}

class VizHazard {
  final String type;
  final String explanation;
  final String fixSuggestion;
  final List<int> steps;
  const VizHazard(this.type, this.explanation, this.fixSuggestion, this.steps);
  factory VizHazard.fromJson(Map<String, dynamic> j) => VizHazard(
        _s(j['type']),
        _s(j['explanation']),
        _s(j['fixSuggestion']),
        j['steps'] is List ? (j['steps'] as List).map((e) => _i(e)).toList() : <int>[],
      );
}

class VisualizationModel {
  final String title;
  final String code;
  final List<VizSchedule> schedules;
  final List<VizHazard> hazards;
  final String fixSuggestion;

  /// True when the schedules were authored into the app (backend unreachable), not produced by the simulator.
  final bool authored;
  final VizSupportInfo support;
  const VisualizationModel(this.title, this.code, this.schedules, this.hazards, this.fixSuggestion,
      {this.authored = false, this.support = VizSupportInfo.supported});

  VizSchedule? schedule(String kind) {
    for (final s in schedules) {
      if (s.kind.toUpperCase() == kind) return s;
    }
    return null;
  }

  /// Accepts both `/api/visualize` and `/api/visualize/concepts/{id}` (which nests it under `visualization`).
  factory VisualizationModel.fromJson(Map<String, dynamic> j, {String code = ''}) {
    final viz = j['visualization'] is Map ? Map<String, dynamic>.from(j['visualization'] as Map) : j;
    return VisualizationModel(
      _s(j['title']),
      code.isNotEmpty ? code : _s(j['code']), // the concept endpoint returns the source it simulated
      _maps(viz['schedules']).map(VizSchedule.fromJson).toList(),
      _maps(viz['hazards']).map(VizHazard.fromJson).toList(),
      _s(viz['fixSuggestion']),
      support: VizSupportInfo.fromJson(viz['support']),
    );
  }
}

// -------------------------------------------------------------- progress / XP

class GamificationStats {
  final int xp;
  final int level;
  final int streakDays;
  const GamificationStats(this.xp, this.level, this.streakDays);
  factory GamificationStats.fromJson(Map<String, dynamic> j) =>
      GamificationStats(_i(j['xp']), _i(j['level'], 1), _i(j['streakDays']));
}

class PerformanceSummaryModel {
  final double averageAccuracy;
  final double averageScore;
  final double successRate;
  final int totalActivities;
  final List<String> weakConcepts; // concept ids
  final List<String> strongConcepts;
  const PerformanceSummaryModel(this.averageAccuracy, this.averageScore, this.successRate, this.totalActivities,
      {this.weakConcepts = const [], this.strongConcepts = const []});
  factory PerformanceSummaryModel.fromJson(Map<String, dynamic> j) => PerformanceSummaryModel(
      _d(j['averageAccuracy']), _d(j['averageScore']), _d(j['successRate']), _i(j['totalActivities']),
      weakConcepts: _strings(j['weakConcepts']), strongConcepts: _strings(j['strongConcepts']));
}

class RecommendationModel {
  final String type;
  final String priority;
  final String title;
  final String message;
  final String reason;
  final String conceptId;
  final String id;
  final bool completed;
  final DateTime? createdAt;
  const RecommendationModel(this.type, this.priority, this.title, this.message, this.reason, this.conceptId,
      {this.id = '', this.completed = false, this.createdAt});
  factory RecommendationModel.fromJson(Map<String, dynamic> j) => RecommendationModel(
      _s(j['type']), _s(j['priority']), _s(j['title']), _s(j['message']), _s(j['reason']), _s(j['conceptId']),
      id: _s(j['id']), completed: _b(j['isCompleted']), createdAt: DateTime.tryParse(_s(j['createdAt'])));
}

/// One stored evidence record (`GET /api/performance`): a finished battle, coding, debugging or interview run.
class PerformanceRecordModel {
  final String conceptId;
  final String activityType; // BATTLE | CODING | DEBUGGING | INTERVIEW
  final int score;
  final double accuracy; // 0..1
  final int timeSpentSeconds;
  final int attemptCount;
  final bool success;
  final DateTime? createdAt;
  const PerformanceRecordModel({
    required this.conceptId,
    required this.activityType,
    required this.score,
    required this.accuracy,
    required this.timeSpentSeconds,
    required this.attemptCount,
    required this.success,
    required this.createdAt,
  });
  factory PerformanceRecordModel.fromJson(Map<String, dynamic> j) => PerformanceRecordModel(
        conceptId: _s(j['conceptId']),
        activityType: _s(j['activityType']).toUpperCase(),
        score: _i(j['score']),
        accuracy: _d(j['accuracy']).clamp(0.0, 1.0),
        timeSpentSeconds: _i(j['timeSpentSeconds']),
        attemptCount: _i(j['attemptCount']),
        success: _b(j['success']),
        createdAt: DateTime.tryParse(_s(j['createdAt']))?.toLocal(),
      );

  /// The shape `POST /api/ai/diagnose/summary` wants. The userId is deliberately absent: the backend binds it
  /// to the authenticated user. The AI service expects lower-case activity types.
  Map<String, dynamic> toDiagnosisActivity() => {
        'activityType': activityType.toLowerCase(),
        'accuracy': accuracy,
        'score': score,
        'attemptCount': attemptCount,
        'timeSpentSeconds': timeSpentSeconds,
        'hintsUsed': 0,
        'success': success,
      };
}

/// Aggregate AI diagnosis (`POST /api/ai/diagnose/summary`): 0-100 per dimension, null when there was no
/// evidence for it. [hintDependency] is "higher is worse".
class DiagnosisScores {
  final double? conceptUnderstanding;
  final double? decisionMaking;
  final double? boundaryConditions;
  final double? codingImplementation;
  final double? hintDependency;
  const DiagnosisScores(
      this.conceptUnderstanding, this.decisionMaking, this.boundaryConditions, this.codingImplementation, this.hintDependency);
  static double? _n(dynamic v) => v is num ? v.toDouble() : null;
  factory DiagnosisScores.fromJson(Map<String, dynamic> j) => DiagnosisScores(_n(j['conceptUnderstanding']),
      _n(j['decisionMaking']), _n(j['boundaryConditions']), _n(j['codingImplementation']), _n(j['hintDependency']));

  bool get isEmpty =>
      conceptUnderstanding == null &&
      decisionMaking == null &&
      boundaryConditions == null &&
      codingImplementation == null &&
      hintDependency == null;
}

/// The learner's Byte DNA (`GET /api/byte-dna`), which the backend evolves from verified evidence.
class ByteDnaModel {
  final String technicalExperience;
  final String careerGoal;
  final String preferredLanguage;
  final List<String> interests;
  final List<String> confidenceAreas;
  final List<String> difficultyAreas;
  final List<String> repeatedMistakes;

  /// topic -> `{attemptCount, averageAccuracy}` (accuracy 0..1)
  final Map<String, ({int attempts, double accuracy})> topicAccuracy;

  /// topic -> `{currentDifficulty, consecutiveFailures, consecutiveSuccesses}`
  final Map<String, String> topicDifficulty;
  const ByteDnaModel({
    required this.technicalExperience,
    required this.careerGoal,
    required this.preferredLanguage,
    required this.interests,
    required this.confidenceAreas,
    required this.difficultyAreas,
    required this.repeatedMistakes,
    required this.topicAccuracy,
    required this.topicDifficulty,
  });
  factory ByteDnaModel.fromJson(Map<String, dynamic> j) {
    final accuracy = <String, ({int attempts, double accuracy})>{};
    if (j['topicAccuracy'] is Map) {
      (j['topicAccuracy'] as Map).forEach((k, v) {
        if (v is Map) accuracy[k.toString()] = (attempts: _i(v['attemptCount']), accuracy: _d(v['averageAccuracy']));
      });
    }
    final difficulty = <String, String>{};
    if (j['difficultyProgression'] is Map) {
      (j['difficultyProgression'] as Map).forEach((k, v) {
        if (v is Map) difficulty[k.toString()] = _s(v['currentDifficulty']);
      });
    }
    return ByteDnaModel(
      technicalExperience: _s(j['technicalExperience']),
      careerGoal: _s(j['careerGoal']),
      preferredLanguage: _s(j['preferredLanguage']),
      interests: _strings(j['interests']),
      confidenceAreas: _strings(j['confidenceAreas']),
      difficultyAreas: _strings(j['difficultyAreas']),
      repeatedMistakes: _strings(j['repeatedMistakes']),
      topicAccuracy: accuracy,
      topicDifficulty: difficulty,
    );
  }
}
