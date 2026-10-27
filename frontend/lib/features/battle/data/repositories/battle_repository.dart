import '../datasources/battle_ai_remote_datasource.dart';
import '../models/battle_hint_model.dart';
import '../models/boss_battle_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';

/// BattleRepository — data layer repository.
/// Sits between the battle presentation layer and [BattleAiRemoteDatasource]
/// for the two AI-backed calls (battle-hint, boss-battle). The battle session
/// itself (questions, grading, result) lives in [BattleController].
class BattleRepository {
  const BattleRepository(this._aiRemote);

  final BattleAiRemoteDatasource _aiRemote;

  /// `POST /api/ai/battle-hint`.
  Future<BattleHintModel> getBattleHint({
    required ConceptModel concept,
    required String question,
    required CanonicalKnowledgeModel canonicalKnowledge,
    required int hintLevel,
  }) {
    return _aiRemote.getBattleHint(
      concept: concept,
      question: question,
      canonicalKnowledge: canonicalKnowledge,
      hintLevel: hintLevel,
    );
  }

  /// `POST /api/ai/boss-battle`.
  Future<BossBattleModel> getBossBattle({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
  }) {
    return _aiRemote.getBossBattle(
      concept: concept,
      canonicalKnowledge: canonicalKnowledge,
    );
  }
}
