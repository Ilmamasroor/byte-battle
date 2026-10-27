import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exception.dart';
import '../../data/models/concept_model.dart';
import '../../data/repositories/concept_repository.dart';

/// Loads (and caches per concept id, shared across screens) the real concept metadata every learning-stage screen shows in its header.
class ConceptController extends ChangeNotifier {
  ConceptController({ConceptRepository repository = const ConceptRepository()}) : _repository = repository;

  final ConceptRepository _repository;
  static final Map<String, ConceptModel> _cache = {};

  bool isLoading = false;
  String? errorMessage;
  ConceptModel? concept;

  /// Loads [conceptId]; a cached copy is shown immediately and refreshed only when [force] is true.
  Future<void> load(String conceptId, {bool force = false}) async {
    final cached = _cache[conceptId];
    if (cached != null && !force) {
      concept = cached;
      errorMessage = null;
      notifyListeners();
      return;
    }
    concept = cached;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final loaded = await _repository.get(conceptId);
      _cache[conceptId] = loaded;
      concept = loaded;
    } on NetworkException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[ConceptController] unexpected error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
