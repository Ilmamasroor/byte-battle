import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/mnemonic_model.dart';

/// Talks to `POST /api/ai/mnemonic` and nothing else.
class MnemonicRemoteDatasource {
  const MnemonicRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/mnemonic?conceptId={conceptId}` — no JSON body. Uses
  /// [ApiClient.postJson] since the response isn't wrapped in
  /// `{success, data}`.
  Future<MnemonicModel> getMnemonic(String conceptId, {String? lens}) async {
    final json = await _apiClient.postJson(
      ApiEndpoints.aiMnemonic,
      query: {'conceptId': conceptId, if (lens != null) 'lens': lens},
      timeout: ApiClient.slowTimeout,
    );
    return MnemonicModel.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
