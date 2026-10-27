import 'dart:math' as math;
import '../../../../../app/theme/app_colors.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';
import 'doc_state.dart';

/// Lays out `structure` scenes: arrays, lists, stacks, queues, hash tables, trees, graphs, Gantt charts and cost
/// bars. Blocks are stacked back to front in the order the document lists them; every block is a real 3D
/// structure whose elements keep stable ids, so a changed cell animates in place.
SceneSpec layoutStructure(DocState d) {
  final blocks = asList(d.state['structures']).map(asMap).toList();
  final nodes = <SceneNode>[];
  final links = <SceneLink>[];
  final counts = <String, int>{};
  var z = 0.0;
  final placed = <_Placed>[];
  for (final b in blocks) {
    final kind = str(b['kind']);
    final name = str(b['name']);
    final n = counts.update('$kind:$name', (v) => v + 1, ifAbsent: () => 0);
    final key = '$kind:$name${n == 0 ? '' : '#$n'}';
    final depth = _depth(kind, b);
    placed.add(_Placed(b, key, z, depth));
    z += depth + 1.6;
  }
  final total = z - 1.6;
  for (final p in placed) {
    final centre = p.z + p.depth / 2 - total / 2; // centred on z = 0
    _block(p.block, p.key, centre, p.depth, nodes, links);
  }
  return SceneSpec(nodes: nodes, links: links, camera: const CameraHint(yaw: -0.25, pitch: 0.58));
}

class _Placed {
  final Map<String, dynamic> block;
  final String key;
  final double z;
  final double depth;
  const _Placed(this.block, this.key, this.z, this.depth);
}

double _depth(String kind, Map<String, dynamic> b) {
  switch (kind) {
    case 'array':
      return asMap(b['pointers']).isEmpty ? 1.4 : 2.6;
    case 'list':
      return 1.8;
    case 'stack':
      return 1.8;
    case 'queue':
      return 1.8;
    case 'hash':
      return math.max(2.0, asList(b['buckets']).length * 1.3);
    case 'tree':
      return 2.2;
    case 'graph':
      return 5.4;
    case 'gantt':
      return math.max(2.0, asList(b['lanes']).length * 1.4 + 1);
    case 'bars':
      return 1.8;
    default:
      return 1.6;
  }
}

void _title(List<SceneNode> out, String key, String name, String? caption, double z, double depth) {
  final text = [if (name.isNotEmpty) name, if (caption != null && caption.isNotEmpty) caption].join('  -  ');
  if (text.isEmpty) return;
  out.add(SceneNode.label(id: 'title:$key', position: Vec3(0, 0.02, z - depth / 2 - 0.55), text: text, color: AppColors.textSecondary, labelSize: 0.3));
}

void _block(Map<String, dynamic> b, String key, double z, double depth, List<SceneNode> nodes, List<SceneLink> links) {
  final kind = str(b['kind']);
  final name = str(b['name']);
  _title(nodes, key, name, str(b['caption']), z, depth);
  switch (kind) {
    case 'array':
      return _array(b, key, name, z, nodes);
    case 'list':
      return _list(b, key, name, z, nodes, links);
    case 'stack':
      return _stack(b, key, name, z, nodes);
    case 'queue':
      return _queue(b, key, name, z, nodes);
    case 'hash':
      return _hash(b, key, name, z, nodes, links);
    case 'tree':
      return _tree(b, key, name, z, nodes, links);
    case 'graph':
      return _graph(b, key, name, z, nodes, links);
    case 'gantt':
      return _gantt(b, key, name, z, nodes);
    case 'bars':
      return _bars(b, key, name, z, nodes);
  }
}

String _val(dynamic item) => item is Map ? str(item['v']) : str(item);
String _st(dynamic item) => item is Map ? str(item['s']) : '';

Map<String, String> _inspect(String what, String name, Map<String, String> more) => {'What': what, if (name.isNotEmpty) 'Part of': name, ...more};

// ------------------------------------------------------------------ array

const _pointerColors = {
  'lo': AppColors.accentCyan,
  'hi': AppColors.orchid,
  'mid': AppColors.primary,
  'i': AppColors.primary,
  'j': AppColors.accentCyan,
  'left': AppColors.accentCyan,
  'right': AppColors.orchid,
  'slow': AppColors.accentCyan,
  'fast': AppColors.primary
};

void _array(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes) {
  final cells = asList(b['cells']);
  final n = cells.length;
  if (n == 0) return;
  final values = [for (final c in cells) double.tryParse(_val(c))];
  final numeric = n >= 3 && values.every((v) => v != null && v >= 0);
  final maxV = numeric ? values.map((v) => v!).reduce(math.max) : 1.0;
  final sp = n > 9 ? 1.05 : 1.2;
  for (var i = 0; i < n; i++) {
    final s = _st(cells[i]);
    final h = numeric ? SceneKit.barHeight(values[i]!, maxV, min: 0.45, max: 2.6) : 0.6;
    nodes.add(SceneNode(
      id: '$key:c$i',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(i, n, sp), h / 2, z),
      size: Vec3(sp * 0.78, h, 0.95),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      opacity: s == 'dim' ? 0.55 : 1,
      label: SceneKit.short(_val(cells[i]), 6),
      labelSize: n > 9 ? 0.26 : 0.32,
      selectable: true,
      inspect: _inspect('Array cell', name, {'Index': '$i', 'Value': _val(cells[i]), if (s.isNotEmpty && s != 'idle') 'State': s}),
    ));
  }
  final ptrs = asMap(b['pointers']);
  final stack = <int, int>{};
  for (final e in ptrs.entries) {
    final idx = asInt(e.value);
    if (idx == null || idx < 0 || idx >= n) continue;
    final level = stack.update(idx, (v) => v + 1, ifAbsent: () => 0);
    nodes.add(SceneNode(
      id: '$key:ptr:${e.key}',
      shape: SceneShape.sphere,
      position: Vec3(SceneKit.rowX(idx, n, sp) + level * 0.0, 0.32 + level * 0.62, z + 1.25),
      size: const Vec3(0.58, 0.58, 0.58),
      color: _pointerColors[e.key] ?? AppColors.xp,
      glow: 0.7,
      label: e.key,
      labelSize: 0.22,
      labelColor: AppColors.onAccent,
    ));
  }
}

// ------------------------------------------------------------------ list

void _list(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes, List<SceneLink> links) {
  final items = asList(b['nodes']);
  final n = items.length;
  const sp = 1.9;
  for (var i = 0; i < n; i++) {
    final s = _st(items[i]);
    nodes.add(SceneNode(
      id: '$key:n$i',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(i, n, sp), 0.35, z),
      size: const Vec3(1.15, 0.7, 1.0),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      opacity: s == 'dim' ? 0.55 : 1,
      label: SceneKit.short(_val(items[i]), 6),
      labelSize: 0.34,
      selectable: true,
      inspect:
          _inspect('Linked-list node', name, {'Value': _val(items[i]), 'Position': '$i', 'next': i < n - 1 ? 'node ${i + 1}' : (b['cycle'] == true ? 'node 0 (cycle)' : 'null')}),
    ));
    if (i < n - 1) {
      final a = Vec3(SceneKit.rowX(i, n, sp) + 0.6, 0.35, z), c = Vec3(SceneKit.rowX(i + 1, n, sp) - 0.6, 0.35, z);
      links.add(SceneLink(id: '$key:l$i', from: a, to: c, color: AppColors.textSecondary, directed: true, width: 2.4));
      if (b['doubly'] == true) {
        links.add(SceneLink(id: '$key:r$i', from: c + const Vec3(0, 0.0, 0.3), to: a + const Vec3(0, 0.0, 0.3), color: AppColors.textHint, directed: true, width: 1.8));
      }
    }
  }
  if (n > 0) {
    final first = SceneKit.rowX(0, n, sp), last = SceneKit.rowX(n - 1, n, sp);
    if (b['cycle'] == true) {
      links.add(SceneLink(id: '$key:c1', from: Vec3(last, 0.7, z), to: Vec3(last, 1.7, z), color: AppColors.orchid, width: 2.4));
      links.add(SceneLink(id: '$key:c2', from: Vec3(last, 1.7, z), to: Vec3(first, 1.7, z), color: AppColors.orchid, width: 2.4));
      links.add(SceneLink(id: '$key:c3', from: Vec3(first, 1.7, z), to: Vec3(first, 0.72, z), color: AppColors.orchid, width: 2.4, directed: true));
    } else {
      nodes.add(SceneNode.label(id: '$key:null', position: Vec3(last + 1.4, 0.35, z), text: 'null', color: AppColors.textHint, labelSize: 0.28));
    }
    if (str(b['head']).isNotEmpty) {
      nodes.add(SceneNode.label(id: '$key:head', position: Vec3(first, 1.15, z), text: str(b['head']), color: AppColors.primary, labelSize: 0.3));
    }
  }
}

// ------------------------------------------------------------------ stack / queue

void _stack(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes) {
  final items = asList(b['items']);
  for (var i = 0; i < items.length; i++) {
    final s = _st(items[i]);
    nodes.add(SceneNode(
      id: '$key:i$i',
      shape: SceneShape.box,
      position: Vec3(0, 0.3 + i * 0.66, z),
      size: const Vec3(2.2, 0.58, 1.3),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      label: SceneKit.short(_val(items[i]), 10),
      labelSize: 0.3,
      selectable: true,
      inspect: _inspect('Stack item', name, {'Value': _val(items[i]), 'Depth from top': '${items.length - 1 - i}', if (i == items.length - 1) 'Role': 'top (next to pop)'}),
    ));
  }
  nodes.add(SceneNode.label(
      id: '$key:top', position: Vec3(-2.0, 0.3 + math.max(0, items.length - 1) * 0.66, z), text: items.isEmpty ? 'empty' : 'top >', color: AppColors.primary, labelSize: 0.3));
}

void _queue(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes) {
  final items = asList(b['items']);
  final n = items.length;
  const sp = 1.55;
  final seen = <String, int>{};
  for (var i = 0; i < n; i++) {
    final s = _st(items[i]);
    final occ = seen.update(_val(items[i]), (v) => v + 1, ifAbsent: () => 0);
    nodes.add(SceneNode(
      id: '$key:i${_val(items[i])}#$occ',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(i, n, sp), 0.3, z),
      size: const Vec3(1.3, 0.6, 1.1),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      label: SceneKit.short(_val(items[i]), 8),
      labelSize: 0.3,
      selectable: true,
      inspect: _inspect(
          'Queue item', name, {'Value': _val(items[i]), 'Place in line': '${i + 1} of $n', if (i == 0) 'Role': 'front (next out)', if (i == n - 1) 'Role ': 'back (last in)'}),
    ));
  }
  if (n == 0) {
    nodes.add(SceneNode.label(id: '$key:empty', position: Vec3(0, 0.3, z), text: 'empty', color: AppColors.textHint, labelSize: 0.3));
  } else {
    nodes.add(SceneNode.label(id: '$key:front', position: Vec3(SceneKit.rowX(0, n, sp), 0.0, z + 0.95), text: 'front', color: AppColors.primary, labelSize: 0.26));
    if (n > 1)
      nodes.add(SceneNode.label(id: '$key:back', position: Vec3(SceneKit.rowX(n - 1, n, sp), 0.0, z + 0.95), text: 'back', color: AppColors.textSecondary, labelSize: 0.26));
  }
}

// ------------------------------------------------------------------ hash

void _hash(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes, List<SceneLink> links) {
  final buckets = asList(b['buckets']).map(asMap).toList();
  final n = buckets.length;
  const rowGap = 1.3;
  for (var r = 0; r < n; r++) {
    final bz = z + (r - (n - 1) / 2) * rowGap;
    final idx = asInt(buckets[r]['i']) ?? r;
    final chain = asList(buckets[r]['items']);
    nodes.add(SceneNode(
      id: '$key:b$idx',
      shape: SceneShape.box,
      position: Vec3(-4.5, 0.2, bz),
      size: const Vec3(1.0, 0.4, 1.0),
      color: chain.isEmpty ? VizPalette.dim : VizPalette.plate,
      label: '$idx',
      labelSize: 0.3,
      selectable: true,
      inspect: _inspect('Hash bucket', name, {'Bucket index': '$idx', 'Chain length': '${chain.length}'}),
    ));
    var px = -4.5;
    for (var k = 0; k < chain.length; k++) {
      final s = _st(chain[k]);
      final x = -2.9 + k * 2.1;
      nodes.add(SceneNode(
        id: '$key:b$idx:i$k',
        shape: SceneShape.box,
        position: Vec3(x, 0.3, bz),
        size: const Vec3(1.7, 0.6, 0.95),
        color: VizPalette.state(s),
        glow: VizPalette.glow(s),
        label: SceneKit.short(_val(chain[k]), 9),
        labelSize: 0.27,
        selectable: true,
        inspect: _inspect('Entry in bucket $idx', name, {'Entry': _val(chain[k]), 'Position in chain': '${k + 1}'}),
      ));
      links.add(SceneLink(id: '$key:b$idx:l$k', from: Vec3(px + 0.55, 0.3, bz), to: Vec3(x - 0.9, 0.3, bz), color: AppColors.textSecondary, directed: true, width: 2));
      px = x + 0.4;
    }
  }
}

// ------------------------------------------------------------------ tree

void _tree(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes, List<SceneLink> links) {
  final defs = {for (final n in asList(b['nodes'])) str(asMap(n)['id']): asMap(n)};
  if (defs.isEmpty) return;
  final root = str(asMap(asList(b['nodes']).first)['id']);
  final xs = <String, double>{};
  final depths = <String, int>{};
  var cursor = 0;
  void walk(String id, int depth) {
    final def = defs[id];
    if (def == null || xs.containsKey(id)) return;
    depths[id] = depth;
    final l = str(def['l']), r = str(def['r']);
    if (l.isNotEmpty) walk(l, depth + 1);
    xs[id] = (cursor++).toDouble();
    if (r.isNotEmpty) walk(r, depth + 1);
  }

  walk(root, 0);
  for (final id in defs.keys) {
    if (!xs.containsKey(id)) {
      xs[id] = (cursor++).toDouble();
      depths[id] = 0;
    }
  }
  final maxDepth = depths.values.fold(0, math.max);
  final width = math.max(1, cursor - 1);
  final sp = math.min(1.7, 11.0 / width);
  Vec3 at(String id) => Vec3((xs[id]! - width / 2) * sp, (maxDepth - depths[id]!) * 1.55 + 0.6, z);
  for (final e in defs.entries) {
    final id = e.key;
    final s = str(e.value['s']);
    for (final c in [str(e.value['l']), str(e.value['r'])]) {
      if (c.isNotEmpty && defs.containsKey(c)) {
        final cs = str(defs[c]!['s']);
        links.add(SceneLink(
            id: '$key:e:$id>$c',
            from: at(id),
            to: at(c),
            color: cs == 'dim' ? VizPalette.dim : AppColors.borderLight,
            glow: cs == 'cur' ? 0.6 : 0,
            width: 2.4,
            opacity: cs == 'dim' ? 0.5 : 1));
      }
    }
    nodes.add(SceneNode(
      id: '$key:n:$id',
      shape: SceneShape.sphere,
      position: at(id),
      size: const Vec3(1.1, 1.1, 1.1),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      opacity: s == 'dim' ? 0.6 : 1,
      label: SceneKit.short(str(e.value['v']), 5),
      labelSize: 0.34,
      selectable: true,
      inspect: _inspect('Tree node', name, {
        'Value': str(e.value['v']),
        'Left child': str(e.value['l']).isEmpty ? 'none' : str(defs[str(e.value['l'])]?['v']),
        'Right child': str(e.value['r']).isEmpty ? 'none' : str(defs[str(e.value['r'])]?['v']),
        'Depth': '${depths[id]}',
      }),
      related: [
        for (final c in [str(e.value['l']), str(e.value['r'])])
          if (c.isNotEmpty) '$key:n:$c'
      ],
    ));
  }
}

// ------------------------------------------------------------------ graph

void _graph(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes, List<SceneLink> links) {
  final ns = asList(b['nodes']).map(asMap).toList();
  final pos = <String, Vec3>{};
  for (final n in ns) {
    pos[str(n['id'])] = Vec3(((asDouble(n['x']) ?? 0.5) - 0.5) * 10, 0.55, z + ((asDouble(n['y']) ?? 0.5) - 0.5) * 4.4);
  }
  for (final e in asList(b['edges']).map(asMap)) {
    final a = pos[str(e['a'])], c = pos[str(e['b'])];
    if (a == null || c == null) continue;
    final s = str(e['s']);
    final dir = (c - a).normalized();
    links.add(SceneLink(
      id: '$key:e:${str(e['a'])}-${str(e['b'])}',
      from: a + dir * 0.55,
      to: c - dir * 0.55,
      color: s == 'idle' || s.isEmpty ? AppColors.borderLight : VizPalette.state(s),
      glow: VizPalette.glow(s),
      width: 2.6,
      directed: b['directed'] == true,
      label: str(e['w']).isEmpty ? null : str(e['w']),
      opacity: s == 'dim' ? 0.45 : 1,
    ));
  }
  for (final n in ns) {
    final id = str(n['id']);
    final s = str(n['s']);
    nodes.add(SceneNode(
      id: '$key:n:$id',
      shape: SceneShape.sphere,
      position: pos[id]!,
      size: const Vec3(1.05, 1.05, 1.05),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      opacity: s == 'dim' ? 0.6 : 1,
      label: id,
      labelSize: 0.36,
      caption: null,
      selectable: true,
      inspect: _inspect('Graph node', name, {
        'Node': id,
        if (str(n['note']).isNotEmpty) 'Note': str(n['note']),
        'Neighbours': [
          for (final e in asList(b['edges']).map(asMap))
            if (str(e['a']) == id) str(e['b']) else if (str(e['b']) == id && b['directed'] != true) str(e['a'])
        ].join(', '),
      }),
      related: [
        for (final e in asList(b['edges']).map(asMap))
          if (str(e['a']) == id) '$key:n:${str(e['b'])}' else if (str(e['b']) == id && b['directed'] != true) '$key:n:${str(e['a'])}'
      ],
    ));
    if (str(n['note']).isNotEmpty) {
      nodes.add(SceneNode.label(id: '$key:note:$id', position: pos[id]! + const Vec3(0, 0.95, 0), text: str(n['note']), color: AppColors.xp, labelSize: 0.26));
    }
  }
}

// ------------------------------------------------------------------ gantt / bars

void _gantt(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes) {
  final lanes = asList(b['lanes']).map(asMap).toList();
  final max = (asInt(b['max']) ?? 10).clamp(1, 60);
  final scale = 10.0 / max;
  double gx(num t) => -5.0 + t * scale;
  for (var li = 0; li < lanes.length; li++) {
    final lz = z + (li - (lanes.length - 1) / 2) * 1.4;
    nodes.add(SceneNode(id: '$key:lane$li', shape: SceneShape.box, position: Vec3(0, 0.02, lz), size: Vec3(10.4, 0.06, 1.15), color: VizPalette.plate));
    nodes.add(SceneNode.label(id: '$key:lanename$li', position: Vec3(-5.9, 0.1, lz), text: str(lanes[li]['name']), color: AppColors.textSecondary, labelSize: 0.28));
    var k = 0;
    for (final blk in asList(lanes[li]['blocks']).map(asMap)) {
      final start = asDouble(blk['start']) ?? 0, len = asDouble(blk['len']) ?? 1;
      final s = str(blk['s']);
      nodes.add(SceneNode(
        id: '$key:lane$li:b$k',
        shape: SceneShape.box,
        position: Vec3(gx(start + len / 2), 0.28, lz),
        size: Vec3(len * scale - 0.06, 0.5, 0.95),
        color: VizPalette.state(s),
        glow: VizPalette.glow(s),
        label: str(blk['label']),
        labelSize: 0.3,
        labelColor: AppColors.onAccent,
        selectable: true,
        inspect: _inspect('Time block', name, {'Label': str(blk['label']), 'From': '${start.toStringAsFixed(0)}', 'Length': '${len.toStringAsFixed(0)}'}),
      ));
      k++;
    }
  }
  final time = asDouble(b['time']);
  if (time != null) {
    nodes.add(SceneNode(
        id: '$key:time', shape: SceneShape.box, position: Vec3(gx(time), 0.6, z), size: Vec3(0.1, 1.1, math.max(1.6, lanes.length * 1.4)), color: AppColors.xp, glow: 0.9));
    nodes.add(SceneNode.label(id: '$key:timelabel', position: Vec3(gx(time), 1.45, z), text: 't = ${time.toStringAsFixed(0)}', color: AppColors.xp, labelSize: 0.3));
  }
}

void _bars(Map<String, dynamic> b, String key, String name, double z, List<SceneNode> nodes) {
  final bars = asList(b['bars']).map(asMap).toList();
  final n = bars.length;
  for (var i = 0; i < n; i++) {
    final v = (asDouble(bars[i]['value']) ?? 0).clamp(0.0, 1.0);
    final h = 0.25 + v * 2.6;
    final s = str(bars[i]['s']);
    nodes.add(SceneNode(
      id: '$key:bar$i',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(i, n, 2.0), h / 2, z),
      size: Vec3(1.5, h, 1.1),
      color: VizPalette.state(s),
      glow: VizPalette.glow(s),
      label: SceneKit.short(str(bars[i]['label']), 9),
      labelSize: 0.28,
      caption: str(bars[i]['text']).isEmpty ? null : SceneKit.short(str(bars[i]['text']), 12),
      selectable: true,
      inspect: _inspect('Cost bar', name, {'Label': str(bars[i]['label']), if (str(bars[i]['text']).isNotEmpty) 'Detail': str(bars[i]['text'])}),
    ));
  }
}

/// Exposed for tests: how many of the document's structure blocks this layout recognises.
const kStructureKinds = {'array', 'list', 'stack', 'queue', 'hash', 'tree', 'graph', 'gantt', 'bars'};
