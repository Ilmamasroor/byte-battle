import '../../../../../app/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../models/mnemonic_model.dart';

/// Talks to `POST /api/ai/mnemonic` and nothing else.
class MnemonicRemoteDatasource {
  const MnemonicRemoteDatasource(this._apiClient);

  final ApiClient _apiClient;

  /// `POST /api/ai/mnemonic?conceptId={conceptId}` — no JSON body. Uses
  /// [ApiClient.postRaw] since the response isn't wrapped in
  /// `{success, data}`.
  Future<MnemonicModel> getMnemonic(String conceptId) async {
    final json = await _apiClient.postRaw(
      ApiEndpoints.aiMnemonic,
      query: {'conceptId': conceptId},
    );
    return MnemonicModel.fromJson(json);
  }
}
