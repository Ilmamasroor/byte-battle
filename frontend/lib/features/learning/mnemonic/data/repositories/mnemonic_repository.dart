import '../datasources/mnemonic_remote_datasource.dart';
import '../models/mnemonic_model.dart';

/// Sits between [MnemonicController] and [MnemonicRemoteDatasource].
class MnemonicRepository {
  const MnemonicRepository(this._remote);

  final MnemonicRemoteDatasource _remote;

  Future<MnemonicModel> getMnemonic(String conceptId) {
    return _remote.getMnemonic(conceptId);
  }
}
