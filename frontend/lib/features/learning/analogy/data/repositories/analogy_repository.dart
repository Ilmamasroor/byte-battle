import '../datasources/analogy_remote_datasource.dart';
import '../models/analogy_model.dart';

/// Sits between [AnalogyController] and [AnalogyRemoteDatasource].
class AnalogyRepository {
  const AnalogyRepository(this._remote);

  final AnalogyRemoteDatasource _remote;

  Future<AnalogyModel> getAnalogy(String conceptId, {String? lens}) {
    return _remote.getAnalogy(conceptId, lens: lens);
  }
}
