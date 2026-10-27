import 'package:flutter/foundation.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../data/concept_names.dart';

/// State behind Performance, AI feedback, Next move and Byte DNA: all of it is read from the backend for the
/// logged-in learner (the JWT identifies the user, the client never sends a userId).
///  - evidence: `GET /api/performance`, `/api/performance/summary`, `/api/learning`
///  - AI diagnosis: `POST /api/ai/diagnose/summary` over those records
///  - recommendations: `GET /api/recommendations`, `POST /api/recommendations/generate`
///  - Byte DNA: `GET /api/byte-dna`
class PerformanceController extends ChangeNotifier {
  PerformanceController._();
  static final PerformanceController instance = PerformanceController._();

  final BackendApi _api = BackendApi.instance;

  bool isLoading = false;
  String? errorMessage;
  bool loaded = false;
  List<PerformanceRecordModel> records = const [];
  PerformanceSummaryModel? summary;
  List<LearningProgressModel> progress = const [];
  Map<String, String> conceptNames = const {};

  bool isDiagnosing = false;
  String? diagnosisError;
  DiagnosisScores? diagnosis;
  String? _diagnosedFor;

  bool isLoadingRecommendations = false;
  String? recommendationError;
  List<RecommendationModel> recommendations = const [];

  bool isLoadingByteDna = false;
  String? byteDnaError;
  ByteDnaModel? byteDna;

  String conceptName(String id) => conceptNames[id] ?? ConceptNames.cached(id) ?? 'this concept';

  String _message(Object e) => e is Exception ? e.toString() : 'Something went wrong. Please try again.';

  /// Loads the learner's evidence. [force] re-reads even when already loaded (pull to refresh / retry).
  Future<void> load({bool force = false}) async {
    if (loaded && !force) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _api.performanceHistory(),
        _api.performanceSummary(),
        _api.learningProgress().catchError((_) => <LearningProgressModel>[]),
      ]);
      records = results[0] as List<PerformanceRecordModel>;
      summary = results[1] as PerformanceSummaryModel;
      progress = results[2] as List<LearningProgressModel>;
      conceptNames = await ConceptNames.resolve(records.map((r) => r.conceptId));
      loaded = true;
    } catch (e) {
      errorMessage = _message(e);
      debugPrint('📈 [PerformanceController.load] FAILED -> $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// AI diagnosis over [records]. With no evidence there is nothing to diagnose, so no call is made.
  Future<void> diagnose({bool force = false}) async {
    if (isDiagnosing) return;
    final signature = '${records.length}:${records.isEmpty ? '' : records.map((r) => r.createdAt?.millisecondsSinceEpoch ?? 0).reduce((a, b) => a > b ? a : b)}';
    if (diagnosis != null && !force && _diagnosedFor == signature) return;
    if (records.isEmpty) {
      diagnosis = null;
      return;
    }
    _diagnosedFor = signature;
    isDiagnosing = true;
    diagnosisError = null;
    notifyListeners();
    try {
      diagnosis = await _api.diagnoseSummary(records);
    } catch (e) {
      diagnosisError = _message(e);
      _diagnosedFor = null;
      debugPrint('📈 [PerformanceController.diagnose] FAILED -> $e');
    } finally {
      isDiagnosing = false;
      notifyListeners();
    }
  }

  /// Active recommendations from the backend. With [analyse] it first asks the backend to derive new ones
  /// from the latest results, but only for concepts that do not already have an open recommendation (the
  /// endpoint itself would store duplicates on every call).
  Future<void> loadRecommendations({bool analyse = false}) async {
    isLoadingRecommendations = true;
    recommendationError = null;
    notifyListeners();
    try {
      var active = await _api.activeRecommendations();
      final weak = summary?.weakConcepts ?? const <String>[];
      final covered = active.map((r) => r.conceptId).toSet();
      final needsGenerating = weak.any((id) => !covered.contains(id));
      if ((analyse || active.isEmpty) && needsGenerating) {
        await _api.generateRecommendations();
        active = await _api.activeRecommendations();
      }
      recommendations = _sorted(active);
      conceptNames = {...conceptNames, ...await ConceptNames.resolve(recommendations.map((r) => r.conceptId))};
    } catch (e) {
      recommendationError = _message(e);
      debugPrint('📈 [PerformanceController.loadRecommendations] FAILED -> $e');
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<void> completeRecommendation(RecommendationModel r) async {
    try {
      await _api.completeRecommendation(r.id);
      recommendations = recommendations.where((x) => x.id != r.id).toList();
    } catch (e) {
      recommendationError = _message(e);
    }
    notifyListeners();
  }

  static const _rank = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2};

  /// Highest priority first, newest first within a priority.
  static List<RecommendationModel> _sorted(List<RecommendationModel> list) => [...list]..sort((a, b) {
      final byPriority = (_rank[a.priority] ?? 3).compareTo(_rank[b.priority] ?? 3);
      if (byPriority != 0) return byPriority;
      final at = a.createdAt, bt = b.createdAt;
      return at == null || bt == null ? 0 : bt.compareTo(at);
    });

  Future<void> loadByteDna({bool force = false}) async {
    if (byteDna != null && !force) return;
    isLoadingByteDna = true;
    byteDnaError = null;
    notifyListeners();
    try {
      byteDna = await _api.byteDna();
    } catch (e) {
      byteDnaError = _message(e);
      debugPrint('📈 [PerformanceController.loadByteDna] FAILED -> $e');
    } finally {
      isLoadingByteDna = false;
      notifyListeners();
    }
  }

  /// Forget everything (used by tests and after logout/account switch).
  void reset() {
    loaded = false;
    records = const [];
    summary = null;
    progress = const [];
    conceptNames = const {};
    diagnosis = null;
    recommendations = const [];
    byteDna = null;
    errorMessage = diagnosisError = recommendationError = byteDnaError = null;
    notifyListeners();
  }
}
