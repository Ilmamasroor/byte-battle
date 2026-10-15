import '../battle_question_bank.dart';
import '../datasources/battle_ai_remote_datasource.dart';
import '../models/battle_hint_model.dart';
import '../models/boss_battle_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';

/// BattleRepository — data layer repository.
/// Sits between the battle presentation layer and [BattleAiRemoteDatasource]
/// for the two AI-backed calls (battle-hint, boss-battle). Session/question
/// fetching for the battle itself is a separate concern and is wired up
/// here once that backend contract exists.
class BattleRepository {
  const BattleRepository(this._aiRemote);

  final BattleAiRemoteDatasource _aiRemote;

  /// Returns the pool of questions a Boss Battle round is drawn from.
  ///
  /// There is no backend endpoint yet that serves a fixed "battle
  /// questions" list — `/api/ai/battle-hint` and `/api/ai/boss-battle`
  /// only take a question the app already has and generate a hint / boss
  /// briefing for it (see [BattleAiRemoteDatasource]). So this always
  /// resolves to [kBattleQuestionBank] for now.
  ///
  /// This method is the single seam [BattleScreen] reads through — once a
  /// real "list battle questions" endpoint exists, only the body here
  /// needs to change (try the API, fall back to [kBattleQuestionBank] on
  /// failure); no caller elsewhere needs to know.
  Future<List<BattleQuestionData>> getQuestions() async {
    return kBattleQuestionBank;
  }

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
