import 'dart:ui';
import 'dart:math' as math;
import '../../../../../app/theme/app_colors.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';
import 'doc_state.dart';

/// Lays out `table` scenes (SQL and relational ideas): each table is a grid of slabs, the query floats above, and
/// the result table rises on a platform in front, filling in as the query runs.
SceneSpec layoutTable(DocState d) {
  final nodes = <SceneNode>[];
  final tables = asList(d.state['tables']).map(asMap).toList();
  final result = d.state['result'] is Map ? asMap(d.state['result']) : null;
  final query = d.state['query'] is Map ? asMap(d.state['query']) : null;

  const cellW = 1.9, cellD = 0.78, gap = 1.6;
  double widthOf(Map<String, dynamic> t) => asList(t['cols']).length * cellW;
  final totalW = tables.fold<double>(0, (a, t) => a + widthOf(t)) + math.max(0, tables.length - 1) * gap;
  var x0 = -totalW / 2;
  var maxRows = 0;
  for (var ti = 0; ti < tables.length; ti++) {
    final t = tables[ti];
    maxRows = math.max(maxRows, asList(t['rows']).length);
    final w = widthOf(t);
    _grid(nodes, 't$ti', t, x0, w, 0.0, cellW, cellD, 0.0, AppColors.accentCyan);
    x0 += w + gap;
  }
  final tablesDepth = (maxRows + 1) * cellD;

  if (result != null) {
    final rw = asList(result['cols']).length * cellW;
    final rz = tablesDepth + 2.4;
    _grid(nodes, 'result', result, -rw / 2, rw, rz, cellW, cellD, 0.55, AppColors.success);
    nodes.add(SceneNode(
      id: 'result-plate',
      backdrop: true,
      shape: SceneShape.box,
      position: Vec3(0, 0.25, rz + (asList(result['rows']).length * cellD) / 2),
      size: Vec3(rw + 0.8, 0.3, (asList(result['rows']).length + 1) * cellD + 0.8),
      color: VizPalette.board,
    ));
  }

  if (query != null && str(query['text']).isNotEmpty) {
    nodes.add(SceneNode.label(id: 'query', position: Vec3(0, 0.6, -1.6), text: str(query['text']), color: AppColors.textPrimary, labelSize: 0.3));
    if (str(query['focus']).isNotEmpty) {
      nodes.add(SceneNode.label(id: 'focus', position: Vec3(0, 0.6, -0.95), text: '> ${str(query['focus'])}', color: AppColors.primary, labelSize: 0.34));
    }
  }
  return SceneSpec(nodes: nodes, camera: const CameraHint(yaw: -0.15, pitch: 0.7));
}

/// One table: a header row of raised slabs and a slab per cell. Row and column highlights glow.
void _grid(List<SceneNode> out, String id, Map<String, dynamic> t, double x0, double w, double z0, double cellW, double cellD, double lift, Color accent) {
  final cols = asList(t['cols']).map(str).toList();
  final rows = asList(t['rows']);
  final hl = {for (final r in asList(t['hl'])) asInt(r)!};
  final dim = {for (final r in asList(t['dim'])) asInt(r)!};
  final hlCols = {for (final c in asList(t['hlCols'])) asInt(c)!};
  final name = str(t['name']);
  if (name.isNotEmpty) {
    out.add(SceneNode.label(id: '$id:name', position: Vec3(x0 + w / 2, lift + 0.55, z0 - 0.75), text: name, color: AppColors.textSecondary, labelSize: 0.34));
  }
  for (var c = 0; c < cols.length; c++) {
    out.add(SceneNode(
      id: '$id:h$c',
      shape: SceneShape.box,
      position: Vec3(x0 + (c + 0.5) * cellW, lift + 0.2, z0),
      size: const Vec3(1.8, 0.28, 0.7),
      color: hlCols.contains(c) ? AppColors.orchid : const Color(0xFF4A4664),
      glow: hlCols.contains(c) ? 0.5 : 0,
      label: SceneKit.short(cols[c], 9),
      labelSize: 0.28,
      labelColor: AppColors.textPrimary,
    ));
  }
  for (var r = 0; r < rows.length; r++) {
    final cells = asList(rows[r]);
    final isHl = hl.contains(r), isDim = dim.contains(r);
    for (var c = 0; c < cols.length; c++) {
      final value = c < cells.length ? str(cells[c]) : '';
      final inCol = hlCols.contains(c);
      out.add(SceneNode(
        id: '$id:r$r:c$c',
        shape: SceneShape.box,
        position: Vec3(x0 + (c + 0.5) * cellW, lift + 0.1, z0 + (r + 1) * cellD),
        size: const Vec3(1.8, 0.2, 0.7),
        color: isHl ? accent : (inCol ? Color.lerp(VizPalette.plate, AppColors.orchid, 0.4)! : VizPalette.plate),
        glow: isHl ? 0.75 : 0,
        opacity: isDim ? 0.35 : 1,
        label: SceneKit.short(value, 9),
        labelSize: 0.28,
        labelColor: isHl ? AppColors.onAccent : AppColors.textPrimary,
        selectable: true,
        inspect: {
          'What': 'A table cell',
          if (name.isNotEmpty) 'Table': name,
          'Column': cols[c],
          'Row': '${r + 1}',
          'Value': value,
          if (isHl) 'State': 'matched / highlighted',
          if (isDim) 'State': 'filtered out',
        },
        related: [for (var k = 0; k < cols.length; k++) '$id:r$r:c$k'],
      ));
    }
  }
}
