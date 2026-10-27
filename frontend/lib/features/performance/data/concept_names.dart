import '../../../core/network/backend_api.dart';

/// Resolves concept ids (as found in performance records and recommendations) to their real names via
/// `GET /api/concepts/{id}`. Names never change during a session, so they are cached.
class ConceptNames {
  ConceptNames._();

  static final Map<String, String> _cache = {};

  static String? cached(String id) => _cache[id];

  /// Best effort: an id that cannot be resolved is simply left out of the result.
  static Future<Map<String, String>> resolve(Iterable<String> ids) async {
    final wanted = ids.where((id) => id.isNotEmpty).toSet();
    await Future.wait(wanted.where((id) => !_cache.containsKey(id)).map((id) async {
      try {
        final concept = await BackendApi.instance.concept(id);
        if (concept.name.isNotEmpty) _cache[id] = concept.name;
      } catch (_) {
        // leave unresolved
      }
    }));
    return {for (final id in wanted) if (_cache.containsKey(id)) id: _cache[id]!};
  }
}
