import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exception.dart';
import '../../data/models/curriculum_tree.dart';
import '../../data/repositories/curriculum_repository.dart';

/// Holds the curriculum tree shared by the roadmap, domain, topic and concept screens (one load serves all four).
class CurriculumController extends ChangeNotifier {
  CurriculumController({CurriculumRepository repository = const CurriculumRepository()}) : _repository = repository;

  static final CurriculumController instance = CurriculumController();

  final CurriculumRepository _repository;

  bool isLoading = false;
  String? errorMessage;
  CurriculumTree? tree;

  /// Loads once; pass [force] to re-read (pull to refresh, Retry, or after returning from learning).
  Future<void> load({bool force = false}) async {
    if (isLoading || (tree != null && !force)) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tree = await _repository.load();
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      debugPrint('[CurriculumController] unexpected error: $e');
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
