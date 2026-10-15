import '../datasources/diagnosis_remote_datasource.dart';
import '../models/performance_model.dart';

/// Sits between [DiagnosisController] and [DiagnosisRemoteDatasource].
class DiagnosisRepository {
  const DiagnosisRepository(this._remote);

  final DiagnosisRemoteDatasource _remote;

  Future<DiagnosisResultModel> diagnoseActivity(DiagnosisActivityModel activity) {
    return _remote.diagnoseActivity(activity);
  }
}
