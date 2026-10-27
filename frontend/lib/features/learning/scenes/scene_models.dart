import 'dart:convert';
import 'package:flutter/services.dart';

/// Which stage renders a scene. Authors pick one per concept (see content-authoring/SCENE_SCHEMA.md).
enum SceneKind { computer, structure, table, sequence, flow }

class ScenePredict {
  final String question;
  final List<String> options;
  final int answer;
  final String reveal;
  const ScenePredict(this.question, this.options, this.answer, this.reveal);
}

/// One narrated step. [state] is the fully merged state for this step: every top-level key a step omits is
/// inherited from the previous step, so authors only write what changes.
class SceneStep {
  final String say;
  final String? note;
  final Map<String, dynamic> state;
  const SceneStep(this.say, this.note, this.state);
}

class SceneDoc {
  final String conceptId;
  final String title;
  final SceneKind kind;
  final String intro;
  final String takeaway;
  final ScenePredict? predict;
  final List<SceneStep> steps;
  const SceneDoc({
    required this.conceptId,
    required this.title,
    required this.kind,
    required this.intro,
    required this.takeaway,
    required this.predict,
    required this.steps,
  });

  static const _reserved = {'say', 'note'};

  factory SceneDoc.fromJson(Map<String, dynamic> j) {
    final kind = SceneKind.values.firstWhere(
      (k) => k.name == j['kind'],
      orElse: () => throw FormatException('unknown scene kind "${j['kind']}"'),
    );
    final raw = (j['steps'] as List?) ?? const [];
    final docCode = j['code'] is List ? [for (final l in j['code'] as List) l.toString()] : null;
    final steps = <SceneStep>[];
    var merged = <String, dynamic>{};
    for (final s in raw) {
      final m = Map<String, dynamic>.from(s as Map);
      final patch = {
        for (final e in m.entries)
          if (!_reserved.contains(e.key)) e.key: e.value
      };
      // `msg`/`msgs` are per-step events, not inherited state.
      merged = {
        ...merged
          ..remove('msg')
          ..remove('msgs'),
        ...patch
      };
      final state = _deepCopy(merged);
      // A doc-level `code` list plus a per-step `at` (inherited) becomes the code panel's state.
      if (docCode != null && state['code'] is! Map) state['code'] = {'lines': docCode, 'at': state['at']};
      steps.add(SceneStep(m['say']?.toString() ?? '', m['note']?.toString(), state));
    }
    ScenePredict? predict;
    if (j['predict'] is Map) {
      final p = Map<String, dynamic>.from(j['predict'] as Map);
      predict = ScenePredict(
        p['question']?.toString() ?? '',
        [for (final o in (p['options'] as List? ?? const [])) o.toString()],
        (p['answer'] as num?)?.toInt() ?? 0,
        p['reveal']?.toString() ?? '',
      );
    }
    return SceneDoc(
      conceptId: j['conceptId']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      kind: kind,
      intro: j['intro']?.toString() ?? '',
      takeaway: j['takeaway']?.toString() ?? '',
      predict: predict,
      steps: steps,
    );
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;
}

/// Loads the bundled scene for a concept (`assets/scenes/<conceptId>.json`), or null when it has none.
class SceneRepository {
  SceneRepository._();
  static final Map<String, SceneDoc?> _cache = {};

  static Future<SceneDoc?> forConcept(String conceptId, {AssetBundle? bundle}) async {
    if (_cache.containsKey(conceptId)) return _cache[conceptId];
    try {
      final text = await (bundle ?? rootBundle).loadString('assets/scenes/$conceptId.json');
      return _cache[conceptId] = SceneDoc.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return _cache[conceptId] = null;
    }
  }
}
