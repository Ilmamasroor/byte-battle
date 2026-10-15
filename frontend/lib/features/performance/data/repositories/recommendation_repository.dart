import '../datasources/recommendation_remote_datasource.dart';
import '../models/recommendation_model.dart';

/// Sits between [RecommendationController] and
/// [RecommendationRemoteDatasource].
class RecommendationRepository {
  const RecommendationRepository(this._remote);

  final RecommendationRemoteDatasource _remote;

  Future<RecommendationAiResponse> getRecommendation(RecommendationAiRequest request) {
    return _remote.getRecommendation(request);
  }
}
