import '../datasources/diagnosis_summary_remote_datasource.dart';
import '../models/performance_model.dart';

/// Sits between [DiagnosisSummaryController] and
/// [DiagnosisSummaryRemoteDatasource].
class DiagnosisSummaryRepository {
  const DiagnosisSummaryRepository(this._remote);

  final DiagnosisSummaryRemoteDatasource _remote;

  Future<DiagnosisSummaryResultModel> summarizeActivities(DiagnosisSummaryRequest request) {
    return _remote.summarizeActivities(request);
  }
}
