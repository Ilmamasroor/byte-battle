import 'dart:math' as math;
import 'dart:ui';
import '../../../../../app/theme/app_colors.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';
import 'doc_state.dart';

/// Lays out `computer` scenes as a processor chamber: the CPU die and its cores in the middle, the call stack as
/// a tower on the left, the heap on the right, the console in front, and tables, frames, disk and network on the
/// back and sides. A reference value such as `-> obj1` becomes a real link from the frame to that heap object.
SceneSpec layoutComputer(DocState d) {
  final s = d.state;
  final prev = d.prev;
  final nodes = <SceneNode>[];
  final links = <SceneLink>[];
  final lit = {for (final h in asList(s['highlight'])) str(h)};
  double glowOf(String part, [double base = 0.18]) => lit.contains(part) ? 0.85 : base;

  nodes.add(const SceneNode(id: 'board', backdrop: true, shape: SceneShape.box, position: Vec3(0, -0.15, 0), size: Vec3(24, 0.3, 15), color: VizPalette.board));

  // ---- CPU die, cores, registers
  final cpu = asMap(s['cpu']);
  nodes.add(SceneNode(
    id: 'cpu',
    shape: SceneShape.box,
    position: const Vec3(0, 0.3, 0),
    size: const Vec3(5.0, 0.6, 4.2),
    color: Color.lerp(VizPalette.plate, AppColors.primary, lit.contains('cpu') ? 0.6 : 0.25)!,
    glow: glowOf('cpu', 0.25),
    caption: 'CPU',
    selectable: true,
    inspect: {
      'What': 'The processor',
      if (str(cpu['doing']).isNotEmpty) 'Doing now': str(cpu['doing']),
      for (final e in asMap(cpu['regs']).entries) 'Register ${e.key}': str(e.value),
    },
  ));
  if (str(cpu['doing']).isNotEmpty) {
    nodes.add(SceneNode.label(id: 'doing', position: const Vec3(0, 1.55, 0), text: SceneKit.short(str(cpu['doing']), 34), color: AppColors.textPrimary, labelSize: 0.3));
  }
  final cores = asList(cpu['cores']);
  for (var i = 0; i < cores.length; i++) {
    final name = cores[i] == null ? '' : str(cores[i]);
    final col = i % 4, row = i ~/ 4;
    nodes.add(SceneNode(
      id: 'core:$i',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(col, math.min(4, cores.length), 1.15), 0.78, -0.55 + row * 1.15),
      size: const Vec3(0.95, 0.36, 0.95),
      color: name.isEmpty ? VizPalette.dim : _threadColor(name),
      glow: name.isEmpty ? 0 : 0.8,
      label: name.isEmpty ? '' : SceneKit.short(name, 6),
      labelSize: 0.22,
      labelColor: AppColors.onAccent,
      selectable: true,
      inspect: {'What': 'CPU core ${i + 1}', 'Running': name.isEmpty ? 'idle' : name},
    ));
  }
  final regs = asMap(cpu['regs']).entries.toList();
  final prevRegs = asMap(asMap(prev?['cpu'])['regs']);
  for (var i = 0; i < regs.length; i++) {
    final changed = prev != null && prevRegs[regs[i].key]?.toString() != regs[i].value?.toString();
    nodes.add(SceneNode(
      id: 'reg:${regs[i].key}',
      shape: SceneShape.box,
      position: Vec3(SceneKit.rowX(i, regs.length, 2.0), 0.18, 3.1),
      size: const Vec3(1.8, 0.36, 0.8),
      color: changed ? AppColors.primary : VizPalette.plate,
      glow: changed ? 0.8 : 0.1,
      label: SceneKit.short('${regs[i].key}: ${str(regs[i].value)}', 16),
      labelSize: 0.22,
      labelColor: changed ? AppColors.onAccent : AppColors.textPrimary,
      selectable: true,
      inspect: {'What': 'A register', 'Name': regs[i].key, 'Value': str(regs[i].value)},
    ));
  }

  // ---- heap (right)
  final heap = asList(s['heap']).map(asMap).toList();
  final prevHeap = {for (final h in asList(prev?['heap']).map(asMap)) str(h['id']): h};
  final heapPos = <String, Vec3>{};
  nodes.add(SceneNode.label(id: 'heap-title', position: const Vec3(8.4, 0.02, -5.6), text: heap.isEmpty ? '' : 'HEAP', color: AppColors.textSecondary, labelSize: 0.3));
  for (var i = 0; i < heap.length; i++) {
    final h = heap[i];
    final id = str(h['id']);
    final state = str(h['state']);
    final p = Vec3(8.3 + (i ~/ 4) * 3.5, 0.5, -4.3 + (i % 4) * 2.7);
    heapPos[id] = p;
    final fields = asMap(h['fields']);
    final pf = asMap(prevHeap[id]?['fields']);
    final changed = prevHeap.containsKey(id) && pf.toString() != fields.toString();
    final fresh = !prevHeap.containsKey(id) && prev != null;
    final garbage = state == 'garbage';
    nodes.add(SceneNode(
      id: 'heap:$id',
      shape: SceneShape.box,
      position: p,
      size: const Vec3(3.1, 1.0, 1.9),
      color: garbage ? AppColors.error : (fresh || state == 'new' ? AppColors.success : Color.lerp(VizPalette.plate, AppColors.accentCyan, 0.45)!),
      glow: garbage ? 0.1 : (fresh || changed || lit.contains('heap') ? 0.75 : 0.25),
      opacity: garbage ? 0.45 : 1,
      label: SceneKit.short('${str(h['type'])} $id', 16),
      labelSize: 0.27,
      caption: SceneKit.short(fields.entries.map((e) => '${e.key}=${str(e.value)}').join('  '), 24),
      selectable: true,
      inspect: {
        'What': 'An object on the heap',
        'Type': str(h['type']),
        'Id': id,
        'State': garbage ? 'garbage (nothing refers to it)' : (state.isEmpty ? 'live' : state),
        for (final e in fields.entries) 'Field ${e.key}': str(e.value)
      },
    ));
  }

  // ---- stack (left)
  final stack = asList(s['stack']).map(asMap).toList();
  final prevStack = asList(prev?['stack']).map(asMap).toList();
  nodes.add(
      SceneNode.label(id: 'stack-title', position: const Vec3(-8.2, 0.02, 3.4), text: stack.isEmpty ? '' : 'STACK (grows up)', color: AppColors.textSecondary, labelSize: 0.3));
  if (stack.isNotEmpty) {
    nodes.add(SceneNode(id: 'stack-base', backdrop: true, shape: SceneShape.box, position: const Vec3(-8.2, 0.08, 0), size: const Vec3(3.9, 0.16, 2.8), color: VizPalette.plate));
  }
  for (var i = 0; i < stack.length; i++) {
    final f = stack[i];
    final vars = asMap(f['vars']);
    final changed = i < prevStack.length ? asMap(prevStack[i]['vars']).toString() != vars.toString() : prev != null;
    final p = Vec3(-8.2, 0.55 + i * 0.85, 0);
    nodes.add(SceneNode(
      id: 'frame:$i:${str(f['frame'])}',
      shape: SceneShape.box,
      position: p,
      size: const Vec3(3.4, 0.7, 2.3),
      color: Color.lerp(VizPalette.plate, AppColors.accentCyan, i == stack.length - 1 ? 0.45 : 0.2)!,
      glow: changed || lit.contains('stack') ? 0.7 : 0.15,
      label: SceneKit.short(str(f['frame']), 18),
      labelSize: 0.27,
      selectable: true,
      inspect: {
        'What': 'A stack frame',
        'Method': str(f['frame']),
        'Position': i == stack.length - 1 ? 'top (running)' : 'waiting below',
        for (final e in vars.entries) 'Local ${e.key}': str(e.value)
      },
    ));
    if (vars.isNotEmpty) {
      nodes.add(SceneNode.label(
        id: 'vars:$i:${str(f['frame'])}',
        position: Vec3(-8.2, p.y, 1.45),
        text: SceneKit.short(vars.entries.map((e) => '${e.key}=${str(e.value)}').join('  '), 30),
        color: changed ? AppColors.primary : AppColors.textSecondary,
        labelSize: 0.22,
      ));
    }
    for (final e in vars.entries) {
      final m = RegExp(r'^->\s*(\w+)').firstMatch(str(e.value));
      final target = m == null ? null : heapPos[m.group(1)];
      if (target != null) {
        links.add(SceneLink(
            id: 'ref:$i:${e.key}', from: p + const Vec3(1.7, 0, 0), to: target + const Vec3(-1.55, 0, 0), color: AppColors.primary, glow: 0.4, width: 2.4, directed: true));
      }
    }
  }

  // ---- console (front)
  final console = asList(s['console']).map(str).toList();
  if (console.isNotEmpty) {
    final shown = console.length > 3 ? console.sublist(console.length - 3) : console;
    nodes.add(SceneNode(
      id: 'console',
      shape: SceneShape.box,
      position: const Vec3(0, 0.45, 6.2),
      size: const Vec3(7.2, 0.9, 1.2),
      color: const Color(0xFF0F2A22),
      glow: glowOf('console', 0.25),
      label: SceneKit.short(shown.join('   '), 44),
      labelSize: 0.3,
      labelColor: AppColors.success,
      caption: 'console',
      selectable: true,
      inspect: {'What': 'Program output', for (var i = 0; i < console.length; i++) 'Line ${i + 1}': console[i]},
    ));
  }

  // ---- back row: panels (page tables, queues...) and the memory-frame grid
  final panels = asList(s['panels']).map(asMap).toList();
  final grid = s['grid'] is Map ? asMap(s['grid']) : null;
  final backItems = <_Back>[
    for (var i = 0; i < panels.length; i++)
      _Back('panel:$i', math.max(2.6, (asList(asList(panels[i]['rows']).isEmpty ? const [] : asList(panels[i]['rows'])[0]).length) * 1.35 + 0.3)),
    if (grid != null) const _Back('grid', 5.4),
  ];
  final backW = backItems.fold<double>(0, (a, b) => a + b.w) + math.max(0, backItems.length - 1) * 1.0;
  var bx = -backW / 2;
  for (final item in backItems) {
    final cx = bx + item.w / 2;
    if (item.id == 'grid') {
      _gridBlock(nodes, grid!, cx, -5.6, lit.contains('ram'));
    } else {
      final idx = int.parse(item.id.split(':')[1]);
      _panel(nodes, idx, panels[idx], cx, -5.6, lit.contains('panel:$idx'));
    }
    bx += item.w + 1.0;
  }

  // ---- disk and network (sides)
  final disk = asList(s['disk']).map(str).toList();
  if (disk.isNotEmpty) {
    nodes.add(SceneNode(
        id: 'disk',
        shape: SceneShape.cylinder,
        position: const Vec3(-3.4, 0.45, 5.6),
        size: const Vec3(2.2, 0.9, 2.2),
        color: Color.lerp(VizPalette.plate, AppColors.orchid, 0.4)!,
        glow: glowOf('disk'),
        label: 'disk',
        labelSize: 0.28,
        caption: SceneKit.short(disk.join(', '), 24),
        selectable: true,
        inspect: {'What': 'Disk', 'Files': disk.join(', ')}));
  }
  final net = s['net'] is Map ? asMap(s['net']) : null;
  if (net != null) {
    nodes.add(SceneNode(
        id: 'net',
        shape: SceneShape.box,
        position: const Vec3(4.4, 0.4, 5.6),
        size: const Vec3(2.6, 0.8, 1.6),
        color: Color.lerp(VizPalette.plate, AppColors.accentCyan, 0.4)!,
        glow: glowOf('net'),
        label: SceneKit.short(str(net['label']).isEmpty ? 'network' : str(net['label']), 14),
        labelSize: 0.26,
        selectable: true,
        inspect: {'What': 'Network card', 'Packets': asList(net['packets']).map(str).join(', ')}));
    final pk = asList(net['packets']).map(str).toList();
    for (var i = 0; i < pk.length; i++) {
      nodes.add(SceneNode(
          id: 'pkt:$i',
          shape: SceneShape.sphere,
          position: Vec3(6.3 + i * 0.9, 0.5, 5.6),
          size: const Vec3(0.7, 0.7, 0.7),
          color: AppColors.accentCyan,
          glow: 0.8,
          label: SceneKit.short(pk[i], 5),
          labelSize: 0.2,
          labelColor: AppColors.onAccent));
    }
  }

  // ---- data moving between two parts (cpu <-> ram)
  Vec3? where(String part) {
    switch (part) {
      case 'cpu':
        return const Vec3(0, 1.0, 0);
      case 'ram':
        return heap.isNotEmpty ? const Vec3(8.3, 1.0, -1.5) : (stack.isNotEmpty ? const Vec3(-8.2, 1.0, 0) : null);
      default:
        return null;
    }
  }

  var f = 0;
  for (final pair in asList(s['flow'])) {
    final p = asList(pair).map(str).toList();
    if (p.length < 2) continue;
    final a = where(p[0]), b = where(p[1]);
    if (a == null || b == null) continue;
    links.add(SceneLink(id: 'flow:$f', from: a, to: b, color: AppColors.xp, glow: 0.9, width: 3, directed: true));
    nodes.add(SceneNode(id: 'flowpkt:$f', shape: SceneShape.sphere, position: Vec3.lerp(a, b, 0.62), size: const Vec3(0.6, 0.6, 0.6), color: AppColors.xp, glow: 1));
    f++;
  }

  return SceneSpec(nodes: nodes, links: links, camera: const CameraHint(yaw: -0.2, pitch: 0.62));
}

class _Back {
  final String id;
  final double w;
  const _Back(this.id, this.w);
}

Color _threadColor(String name) {
  final m = RegExp(r'(\d+)').firstMatch(name);
  final i = m == null ? name.codeUnits.fold(0, (a, b) => a + b) : (int.parse(m.group(1)!) - 1);
  return VizPalette.thread(i.abs());
}

void _panel(List<SceneNode> out, int idx, Map<String, dynamic> p, double cx, double z, bool lit) {
  final rows = asList(p['rows']).map((r) => asList(r).map(str).toList()).toList();
  final hl = {for (final r in asList(p['hl'])) asInt(r)!};
  final title = str(p['title']);
  out.add(SceneNode.label(id: 'panel:$idx:title', position: Vec3(cx, 0.55, z - 0.9), text: title, color: lit ? AppColors.textPrimary : AppColors.textSecondary, labelSize: 0.28));
  final cols = rows.isEmpty ? 1 : rows.first.length;
  const cw = 1.3;
  final w = cols * cw;
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < cols; c++) {
      final header = r == 0;
      final isHl = hl.contains(r - 1) && !header;
      out.add(SceneNode(
        id: 'panel:$idx:r$r:c$c',
        shape: SceneShape.box,
        position: Vec3(cx - w / 2 + (c + 0.5) * cw, header ? 0.14 : 0.1, z + r * 0.62),
        size: Vec3(cw - 0.1, header ? 0.26 : 0.2, 0.55),
        color: header ? const Color(0xFF4A4664) : (isHl ? AppColors.primary : VizPalette.plate),
        glow: isHl ? 0.8 : 0,
        label: SceneKit.short(c < rows[r].length ? rows[r][c] : '', 7),
        labelSize: 0.22,
        labelColor: isHl ? AppColors.onAccent : AppColors.textPrimary,
        selectable: !header,
        inspect: header ? const {} : {'What': 'A row of "$title"', for (var k = 0; k < rows[0].length && k < rows[r].length; k++) rows[0][k]: rows[r][k]},
        related: [for (var k = 0; k < cols; k++) 'panel:$idx:r$r:c$k'],
      ));
    }
  }
}

void _gridBlock(List<SceneNode> out, Map<String, dynamic> g, double cx, double z, bool lit) {
  final cells = asList(g['cells']).map(asMap).toList();
  out.add(
      SceneNode.label(id: 'grid:title', position: Vec3(cx, 0.55, z - 0.9), text: str(g['title']), color: lit ? AppColors.textPrimary : AppColors.textSecondary, labelSize: 0.28));
  const perRow = 4;
  for (var i = 0; i < cells.length; i++) {
    final s = str(cells[i]['s']);
    final color = {'used': AppColors.accentCyan, 'free': VizPalette.dim, 'hot': AppColors.primary, 'bad': AppColors.error}[s] ?? VizPalette.idle;
    out.add(SceneNode(
      id: 'grid:$i',
      shape: SceneShape.box,
      position: Vec3(cx + (i % perRow - (perRow - 1) / 2) * 1.35, 0.15, z + (i ~/ perRow) * 1.0),
      size: const Vec3(1.2, 0.3, 0.85),
      color: color,
      glow: s == 'hot' ? 0.85 : (s == 'used' ? 0.3 : 0),
      label: SceneKit.short(str(cells[i]['label']), 7),
      labelSize: 0.22,
      labelColor: s == 'free' ? AppColors.textHint : AppColors.onAccent,
      selectable: true,
      inspect: {'What': 'A memory frame', 'Content': str(cells[i]['label']), 'State': s.isEmpty ? 'used' : s},
    ));
  }
}
