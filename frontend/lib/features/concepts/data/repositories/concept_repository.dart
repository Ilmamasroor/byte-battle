import '../../../../core/network/backend_api.dart';
import '../models/concept_model.dart';

/// Concept metadata from `GET /api/concepts/{id}`.
class ConceptRepository {
  const ConceptRepository();

  Future<ConceptModel> get(String conceptId) async {
    final info = await BackendApi.instance.concept(conceptId);
    return ConceptModel(id: info.id, name: info.name, description: info.description, difficulty: info.difficulty);
  }
}
