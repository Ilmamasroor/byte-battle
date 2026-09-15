import '../../../../concepts/data/models/concept_model.dart';

/// The nested `mnemonic` object inside the AI Mnemonic response:
/// `{ "mnemonic": "...", "memoryTip": "..." }`.
class MnemonicDetail {
  final String mnemonic;
  final String memoryTip;

  const MnemonicDetail({required this.mnemonic, required this.memoryTip});

  factory MnemonicDetail.fromJson(Map<String, dynamic> json) {
    return MnemonicDetail(
      mnemonic: json['mnemonic']?.toString() ?? '',
      memoryTip: json['memoryTip']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'mnemonic': mnemonic, 'memoryTip': memoryTip};
}

/// Response model for `POST /api/ai/mnemonic?conceptId=...`.
/// Not wrapped in the usual `{success, data}` envelope. Shape:
/// ```json
/// { "concept": { "id": "...", "name": "..." },
///   "mnemonic": { "mnemonic": "...", "memoryTip": "..." } }
/// ```
/// Note the `concept` here only ever includes `id`/`name` (unlike the
/// fuller `concept` on the Analogy response) — [ConceptModel]'s other
/// fields are simply left null.
class MnemonicModel {
  final ConceptModel concept;
  final MnemonicDetail mnemonic;

  const MnemonicModel({required this.concept, required this.mnemonic});

  factory MnemonicModel.fromJson(Map<String, dynamic> json) {
    return MnemonicModel(
      concept: ConceptModel.fromJson(
        (json['concept'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      mnemonic: MnemonicDetail.fromJson(
        (json['mnemonic'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'concept': concept.toJson(), 'mnemonic': mnemonic.toJson()};
  }
}
