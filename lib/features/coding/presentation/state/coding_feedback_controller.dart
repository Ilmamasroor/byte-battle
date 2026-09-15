import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/models/diagnosis_model.dart';
import '../../../concepts/data/models/concept_model.dart';
import '../../data/datasources/coding_ai_remote_datasource.dart';
import '../../data/models/coding_feedback_model.dart';
import '../../data/repositories/coding_repository.dart';

/// Single source of truth for the AI-generated feedback shown after the
/// learner submits code and the backend has already diagnosed it. Same
/// plain-singleton pattern as `AuthController.instance` /
/// `MnemonicController.instance`.
class CodingFeedbackController extends ChangeNotifier {
  CodingFeedbackController._(this._repository);

  static CodingFeedbackController? _instance;

  static CodingFeedbackController get instance {
    if (_instance != null) return _instance!;
    final secureStorage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: secureStorage);
    final repository = CodingRepository(CodingAiRemoteDatasource(apiClient));
    _instance = CodingFeedbackController._(repository);
    return _instance!;
  }

  final CodingRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  CodingFeedbackModel? feedback;

  /// `POST /api/ai/coding-feedback`. Call this once the backend has
  /// produced a [DiagnosisModel] for the learner's submission.
  Future<void> loadFeedback({
    required ConceptModel concept,
    required DiagnosisModel diagnosis,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      feedback = await _repository.getCodingFeedback(
        concept: concept,
        diagnosis: diagnosis,
      );
      debugPrint('💻 [CodingFeedbackController] loaded feedback for ${concept.id}');
    } on NetworkException catch (e) {
      errorMessage = e.message;
      debugPrint('💻 [CodingFeedbackController] FAILED -> ${e.message} (status: ${e.statusCode})');
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('💻 [CodingFeedbackController] FAILED -> unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
