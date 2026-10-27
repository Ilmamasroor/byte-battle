/// Typed access to the loosely-typed JSON a scene document carries, so the layouts read like the schema.
Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> asList(dynamic v) => v is List ? v : const [];
String str(dynamic v) => v?.toString() ?? '';
int? asInt(dynamic v) => v is num ? v.toInt() : int.tryParse(str(v));
double? asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(str(v));

/// The domain state of a scene-document lesson at one step: the merged step state, the previous step's state (so
/// layouts can emphasise what just changed), and, for message-sequence scenes, every message revealed so far.
class DocState {
  final Map<String, dynamic> state;
  final Map<String, dynamic>? prev;
  final List<Map<String, dynamic>> messages;
  final int index;
  const DocState({required this.state, this.prev, this.messages = const [], this.index = 0});
}
