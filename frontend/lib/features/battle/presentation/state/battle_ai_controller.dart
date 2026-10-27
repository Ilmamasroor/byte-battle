import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../../learning/explanation/data/models/canonical_knowledge_model.dart';
import '../../data/datasources/battle_ai_remote_datasource.dart';
import '../../data/models/battle_hint_model.dart';
import '../../data/models/boss_battle_model.dart';
import '../../../learning/explanation/presentation/state/explanation_controller.dart';
import '../../data/repositories/battle_repository.dart';

/// Single source of truth for the two AI calls that belong to the battle
/// experience: `POST /api/ai/battle-hint` (while solving a battle
/// question) and `POST /api/ai/boss-battle` (the Boss Battle screen).
/// Same plain-singleton pattern as `AuthController.instance` /
/// `MnemonicController.instance`.
class BattleAiController extends ChangeNotifier {
  BattleAiController._(this._repository);

  static BattleAiController? _instance;

  static BattleAiController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = BattleRepository(BattleAiRemoteDatasource(apiClient));
    _instance = BattleAiController._(repository);
    return _instance!;
  }

  final BattleRepository _repository;

  // ---- Battle hint state ----
  bool isHintLoading = false;
  String? hintErrorMessage;
  BattleHintModel? battleHint;

  // ---- Boss battle state ----
  bool isBossBattleLoading = false;
  String? bossBattleErrorMessage;
  BossBattleModel? bossBattle;

  /// The AI endpoints want the concept's canonical knowledge as context. It is fetched once per concept; if it
  /// cannot be loaded the hint/briefing is still requested with an empty one rather than failing.
  Future<CanonicalKnowledgeModel> canonicalFor(String conceptId) async {
    final explanation = ExplanationController.instance;
    try {
      await explanation.loadCanonicalKnowledge(conceptId);
    } catch (_) {}
    return explanation.knowledge ?? const CanonicalKnowledgeModel(keyPoints: [], rules: [], examples: []);
  }

  /// `POST /api/ai/battle-hint`. `hintLevel`: 1 -> gentle, 2 -> stronger,
  /// 3 -> almost-solution-level.
  Future<void> loadBattleHint({
    required ConceptModel concept,
    required String question,
    required CanonicalKnowledgeModel canonicalKnowledge,
    required int hintLevel,
  }) async {
    isHintLoading = true;
    hintErrorMessage = null;
    notifyListeners();

    try {
      battleHint = await _repository.getBattleHint(
        concept: concept,
        question: question,
        canonicalKnowledge: canonicalKnowledge,
        hintLevel: hintLevel,
      );
      debugPrint('⚔️ [BattleAiController] loaded battle hint (level $hintLevel) for ${concept.id}');
    } on NetworkException catch (e) {
      hintErrorMessage = e.message;
      debugPrint('⚔️ [BattleAiController] battle-hint FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      hintErrorMessage = 'Something went wrong. Please try again.';
      debugPrint('⚔️ [BattleAiController] battle-hint FAILED -> unexpected error: $e');
    } finally {
      isHintLoading = false;
      notifyListeners();
    }
  }

  /// `POST /api/ai/boss-battle`.
  Future<void> loadBossBattle({
    required ConceptModel concept,
    required CanonicalKnowledgeModel canonicalKnowledge,
  }) async {
    isBossBattleLoading = true;
    bossBattleErrorMessage = null;
    notifyListeners();

    try {
      bossBattle = await _repository.getBossBattle(
        concept: concept,
        canonicalKnowledge: canonicalKnowledge,
      );
      debugPrint('👹 [BattleAiController] loaded boss battle scenario for ${concept.id}');
    } on NetworkException catch (e) {
      bossBattleErrorMessage = e.message;
      debugPrint('👹 [BattleAiController] boss-battle FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      bossBattleErrorMessage = 'Something went wrong. Please try again.';
      debugPrint('👹 [BattleAiController] boss-battle FAILED -> unexpected error: $e');
    } finally {
      isBossBattleLoading = false;
      notifyListeners();
    }
  }
}
