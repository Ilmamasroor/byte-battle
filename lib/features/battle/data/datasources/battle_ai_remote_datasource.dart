import '../../../../app/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../models/battle_hint_model.dart';
import '../models/boss_battle_model.dart';

/// Talks to `POST /api/ai/battle-hint` and `POST /api/ai/boss-battle` —
/// the two AI calls that belong to the battle experience.
class BattleAiRemoteDatasource {
  const BattleAiRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/battle-hint`. Unlike the AI Analogy/Mnemonic/Canonical
  /// Knowledge endpoints, this one takes a full JSON body (no
  /// `conceptId` query param) since the backend needs the exact question
  /// and hint level being played right now. Uses [ApiClient.postRaw]
  /// because the response isn't wrapped in `{success, data}`.
  Future<BattleHintModel> getBattleHint({
    required ConceptModel concept,
    required String question,
    required CanonicalKnowledgeModel canonicalKnowledge,
    required int hintLevel,
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiBattleHint,
      body: {
        'concept': concept.toJson(),
        'question': question,
        'canonicalKnowledge': canonicalKnowledge.toJson(),
        'hintLevel': hintLevel,
      },
    );
    return BattleHintModel.fromJson(json);
  }

  /// `POST /api/ai/boss-battle`. Same JSON-body/`postRaw` shape as
  /// [getBattleHint].
  Future<BossBattleModel> getBossBattle({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
  }) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiBossBattle,
      body: {
        'concept': concept.toJson(),
        'canonicalKnowledge': canonicalKnowledge.toJson(),
      },
    );
    return BossBattleModel.fromJson(json);
  }
}
