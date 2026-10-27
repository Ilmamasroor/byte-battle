import 'dart:ui';
import 'dart:math' as math;
import '../../../../../app/theme/app_colors.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';
import 'doc_state.dart';

/// Lays out `sequence` scenes (protocols, caches, queues, transactions): the actors stand as pillars along the
/// back, time runs toward the viewer along dashed lifelines, and each message is an arrow at its own depth, so
/// the whole conversation is an inspectable timeline on the floor.
SceneSpec layoutSequence(DocState d) {
  final actors = asList(d.state['actors']).map(str).toList();
  if (actors.isEmpty) return SceneSpec.empty;
  final states = asMap(d.state['actorState']);
  final msgs = d.messages;
  final nodes = <SceneNode>[];
  final links = <SceneLink>[];
  const sp = 5.4;
  double ax(int i) => SceneKit.rowX(i, actors.length, sp);
  const z0 = -3.0, dz = 1.5;
  final lastZ = z0 + 1.2 + math.max(msgs.length, 4) * dz;

  final cur = msgs.isEmpty ? null : msgs.last;
  final curFrom = cur == null ? -1 : (asInt(cur['from']) ?? 0).clamp(0, actors.length - 1);
  final curTo = cur == null ? -1 : (asInt(cur['to']) ?? 0).clamp(0, actors.length - 1);

  nodes.add(SceneNode(
      id: 'floor-plate',
      backdrop: true,
      shape: SceneShape.box,
      position: Vec3(0, -0.12, (z0 + lastZ) / 2),
      size: Vec3(actors.length * sp + 1.5, 0.24, lastZ - z0 + 2.4),
      color: VizPalette.board));

  for (var i = 0; i < actors.length; i++) {
    final active = i == curFrom || i == curTo;
    final st = str(states['$i']);
    nodes.add(SceneNode(
      id: 'actor:$i',
      shape: SceneShape.cylinder,
      position: Vec3(ax(i), 1.1, z0),
      size: const Vec3(1.7, 2.2, 1.7),
      color: Color.lerp(VizPalette.plate, AppColors.primary, active ? 0.75 : 0.35)!,
      glow: active ? 0.85 : 0.2,
      label: SceneKit.short(actors[i], 12),
      labelSize: 0.3,
      caption: st.isEmpty ? null : SceneKit.short(st, 14),
      selectable: true,
      inspect: {
        'What': 'A participant',
        'Name': actors[i],
        'State': st.isEmpty ? '(none)' : st,
        if (active) 'Now': i == curFrom && i != curTo ? 'sending' : (i == curTo && i != curFrom ? 'receiving' : 'acting')
      },
      related: [
        for (var m = 0; m < msgs.length; m++)
          if ((asInt(msgs[m]['from']) ?? -1) == i || (asInt(msgs[m]['to']) ?? -1) == i) _msgNodeId(msgs[m], m)
      ],
    ));
    links.add(SceneLink(id: 'life:$i', from: Vec3(ax(i), 0.03, z0 + 0.9), to: Vec3(ax(i), 0.03, lastZ), color: AppColors.borderLight, dashed: true, width: 1.6, opacity: 0.8));
  }

  for (var m = 0; m < msgs.length; m++) {
    final msg = msgs[m];
    final from = (asInt(msg['from']) ?? 0).clamp(0, actors.length - 1);
    final to = (asInt(msg['to']) ?? 0).clamp(0, actors.length - 1);
    final kind = str(msg['kind']);
    final color = kind == 'error' ? AppColors.error : (kind == 'res' ? AppColors.success : (kind == 'note' ? AppColors.xp : AppColors.accentCyan));
    final latest = m == msgs.length - 1;
    final z = z0 + 1.2 + m * dz;
    if (from == to || kind == 'note') {
      nodes.add(SceneNode(
        id: 'msg:$m',
        shape: SceneShape.box,
        position: Vec3(ax(from), 0.2, z),
        size: const Vec3(3.6, 0.36, 0.8),
        color: Color.lerp(VizPalette.plate, color, 0.55)!,
        glow: latest ? 0.8 : 0.1,
        label: SceneKit.short(str(msg['label']), 26),
        labelSize: 0.24,
        selectable: true,
        inspect: {'What': 'A note', 'Text': str(msg['label']), 'By': actors[from]},
      ));
    } else {
      final a = Vec3(ax(from), 0.55, z), b = Vec3(ax(to), 0.55, z);
      links.add(SceneLink(
          id: 'msg:$m',
          from: a,
          to: b,
          color: color,
          glow: latest ? 0.9 : 0.15,
          width: latest ? 3.4 : 2.4,
          directed: true,
          label: SceneKit.short(str(msg['label']), 30),
          opacity: latest ? 1 : 0.75));
      nodes.add(SceneNode(
        id: 'msgmark:$m',
        shape: SceneShape.sphere,
        position: b,
        size: const Vec3(0.5, 0.5, 0.5),
        color: color,
        glow: latest ? 1 : 0.2,
        opacity: latest ? 1 : 0.5,
        selectable: true,
        inspect: {
          'What': 'A message',
          'Text': str(msg['label']),
          'From': actors[from],
          'To': actors[to],
          'Kind': kind.isEmpty ? 'req' : kind,
          'Order': '${m + 1} of ${msgs.length}'
        },
        related: ['actor:$from', 'actor:$to'],
      ));
    }
  }
  return SceneSpec(nodes: nodes, links: links, camera: const CameraHint(yaw: -0.4, pitch: 0.62));
}

/// The id of the selectable node that stands for message [m]: a note box, or the marker at an arrow's head.
String _msgNodeId(Map<String, dynamic> msg, int m) => (asInt(msg['from']) ?? 0) == (asInt(msg['to']) ?? 0) || str(msg['kind']) == 'note' ? 'msg:$m' : 'msgmark:$m';
