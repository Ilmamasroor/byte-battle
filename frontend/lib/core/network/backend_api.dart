import '../models/backend_models.dart';
import '../storage/secure_storage_service.dart';
import 'api_client.dart';

/// One facade for the backend endpoints behind the live learning loop. Every method returns typed models
/// and throws [NetworkException] (via [ApiClient]) on failure, so screens only deal with that one error type.
class BackendApi {
  BackendApi._(this._client);

  static BackendApi? _instance;

  static BackendApi get instance =>
      _instance ??= BackendApi._(ApiClient(secureStorage: SecureStorageService()));

  /// For tests: swap the client (e.g. a Dio with a fake adapter).
  static void useClient(ApiClient client) => _instance = BackendApi._(client);

  final ApiClient _client;

  Map<String, dynamic> _map(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic v) =>
      v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];

  // ---- onboarding
  Future<List<OnboardingQuestionModel>> onboardingQuestions() async =>
      _list(await _client.getJson('/api/onboarding/questions')).map(OnboardingQuestionModel.fromJson).toList();

  Future<OnboardingStatus> onboardingStatus() async =>
      OnboardingStatus.fromJson(_map(await _client.getJson('/api/onboarding/status')));

  /// [answers] uses the question ids as keys, exactly as served by [onboardingQuestions].
  Future<void> submitOnboarding(Map<String, dynamic> answers) =>
      _client.postJson('/api/onboarding', body: answers);

  // ---- curriculum / learning
  Future<ConceptInfo> concept(String id) async => ConceptInfo.fromJson(_map(await _client.getJson('/api/concepts/$id')));

  Future<LearningProgressModel> startLearning(String conceptId) async =>
      LearningProgressModel.fromJson(_map(await _client.postJson('/api/learning/start', body: {'conceptId': conceptId})));

  Future<LearningProgressModel> completeStage(String progressId) async =>
      LearningProgressModel.fromJson(_map(await _client.postJson('/api/learning/complete-stage', body: {'progressId': progressId})));

  // ---- battles
  Future<List<BattleInfo>> battles() async => _list(await _client.getJson('/api/battles')).map(BattleInfo.fromJson).toList();

  Future<BattleStart> startBattle(String battleId) async =>
      BattleStart.fromJson(_map(await _client.postJson('/api/battles/$battleId/start')));

  Future<BattleAnswerResult> answerBattle(String sessionId, String questionId, String answer, int seconds) async =>
      BattleAnswerResult.fromJson(_map(await _client.postJson('/api/battle-sessions/$sessionId/attempts',
          body: {'battleQuestionId': questionId, 'answer': answer, 'timeTakenSeconds': seconds})));

  Future<BattleResultModel> completeBattle(String sessionId) async =>
      BattleResultModel.fromJson(_map(await _client.postJson('/api/battle-sessions/$sessionId/complete')));

  // ---- coding (Judge0)
  Future<List<CodingChallengeModel>> challengesForConcept(String conceptId) async =>
      _list(await _client.getJson('/api/coding/concepts/$conceptId/challenges')).map(CodingChallengeModel.fromJson).toList();

  Future<CodingChallengeModel> challenge(String id) async =>
      CodingChallengeModel.fromJson(_map(await _client.getJson('/api/coding/challenges/$id')));

  Future<SubmissionResult> submitCode(String challengeId, String code, String language) async =>
      SubmissionResult.fromJson(_map(await _client.postJson('/api/coding/challenges/$challengeId/submissions',
          body: {'sourceCode': code, 'language': language}, timeout: ApiClient.slowTimeout)));

  /// Re-reads a stored submission (the AI feedback is attached a few seconds after the result).
  Future<SubmissionResult> submission(String id) async =>
      SubmissionResult.fromJson(_map(await _client.getJson('/api/coding/submissions/$id')));

  // ---- debugging
  Future<List<DebugExerciseModel>> debugExercises(String conceptId) async =>
      _list(await _client.getJson('/api/debugging/exercises', query: {'conceptId': conceptId}))
          .map(DebugExerciseModel.fromJson)
          .toList();

  Future<DebugExerciseModel> debugExercise(String id) async =>
      DebugExerciseModel.fromJson(_map(await _client.getJson('/api/debugging/exercises/$id')));

  Future<DebugAttemptResult> debugAttempt(String id, String code, int seconds) async =>
      DebugAttemptResult.fromJson(_map(await _client.postJson('/api/debugging/exercises/$id/attempts',
          body: {'code': code, 'timeSpentSeconds': seconds}, timeout: ApiClient.slowTimeout)));

  Future<DebugHint> debugHint(String id, int level) async =>
      DebugHint.fromJson(_map(await _client.getJson('/api/debugging/exercises/$id/hint', query: {'level': level})));

  // ---- interview
  Future<InterviewSessionModel> startInterview(String conceptId, String difficulty) async =>
      InterviewSessionModel.fromJson(_map(await _client.postJson('/api/interviews',
          body: {'conceptId': conceptId, 'difficulty': difficulty}, timeout: ApiClient.slowTimeout)));

  Future<List<InterviewTurn>> interviewMessages(String sessionId) async =>
      _list(await _client.getJson('/api/interviews/$sessionId/messages')).map(InterviewTurn.fromJson).toList();

  Future<InterviewTurn> sendInterviewAnswer(String sessionId, String content) async =>
      InterviewTurn.fromJson(_map(await _client.postJson('/api/interviews/$sessionId/messages',
          body: {'content': content}, timeout: ApiClient.slowTimeout)));

  Future<InterviewResultModel> completeInterview(String sessionId) async =>
      InterviewResultModel.fromJson(_map(await _client.postJson('/api/interviews/$sessionId/complete')));

  // ---- visualization
  Future<VisualizationModel> conceptVisualization(String conceptId) async => VisualizationModel.fromJson(
      _map(await _client.getJson('/api/visualize/concepts/$conceptId', timeout: ApiClient.slowTimeout)));

  Future<VisualizationModel> visualizeCode(String code) async => VisualizationModel.fromJson(
      _map(await _client.postJson('/api/visualize', body: {'code': code}, timeout: ApiClient.slowTimeout)),
      code: code);

  /// One page of a curriculum listing (`{content: [...]}`), unwrapped to its items.
  Future<List<Map<String, dynamic>>> _curriculumPage(String path) async =>
      _list(_map(await _client.getJson(path, query: {'size': 100}))['content']);

  Future<List<Map<String, dynamic>>> curriculumDomains() => _curriculumPage('/api/curriculum/domains');

  Future<List<Map<String, dynamic>>> curriculumTopics(String domainId) =>
      _curriculumPage('/api/curriculum/domains/$domainId/topics');

  Future<List<Map<String, dynamic>>> curriculumConcepts(String topicId) =>
      _curriculumPage('/api/curriculum/topics/$topicId/concepts');

  /// Grounded + personalized explanation text (`/api/ai/explanation`): `{content, fallback, metadata}`.
  Future<Map<String, dynamic>> aiExplanation(String conceptId) async => _map(await _client.postJson(
      '/api/ai/explanation', query: {'conceptId': conceptId}, timeout: ApiClient.slowTimeout));

  // ---- progress
  Future<GamificationStats> gamification() async =>
      GamificationStats.fromJson(_map(await _client.getJson('/api/gamification/me')));

  Future<PerformanceSummaryModel> performanceSummary() async =>
      PerformanceSummaryModel.fromJson(_map(await _client.getJson('/api/performance/summary')));

  /// Every stored performance record of the learner: `{activityType, accuracy, success, ...}`.
  Future<List<Map<String, dynamic>>> performanceRecords() async => _list(await _client.getJson('/api/performance'));

  Future<List<LearningProgressModel>> learningProgress() async =>
      _list(await _client.getJson('/api/learning')).map(LearningProgressModel.fromJson).toList();

  Future<List<RecommendationModel>> recommendations() async =>
      _list(await _client.getJson('/api/recommendations/all')).map(RecommendationModel.fromJson).toList();

  /// Typed performance records, newest first as stored.
  Future<List<PerformanceRecordModel>> performanceHistory() async =>
      (await performanceRecords()).map(PerformanceRecordModel.fromJson).toList();

  /// Recommendations the backend derives from the learner's performance records (rule based).
  Future<List<RecommendationModel>> generateRecommendations() async =>
      _list(await _client.postJson('/api/recommendations/generate', timeout: ApiClient.slowTimeout))
          .map(RecommendationModel.fromJson)
          .toList();

  /// AI diagnosis across the learner's activities. The user is identified by the JWT, never by the body.
  Future<DiagnosisScores> diagnoseSummary(List<PerformanceRecordModel> records) async => DiagnosisScores.fromJson(
      _map(await _client.postJson('/api/ai/diagnose/summary',
          body: {'activities': records.map((r) => r.toDiagnosisActivity()).toList()}, timeout: ApiClient.slowTimeout)));

  /// Active (not yet completed) recommendations, as stored for the learner.
  Future<List<RecommendationModel>> activeRecommendations() async =>
      _list(await _client.getJson('/api/recommendations')).map(RecommendationModel.fromJson).toList();

  Future<void> completeRecommendation(String id) => _client.postJson('/api/recommendations/$id/complete');

  Future<ByteDnaModel> byteDna() async => ByteDnaModel.fromJson(_map(await _client.getJson('/api/byte-dna')));
}
