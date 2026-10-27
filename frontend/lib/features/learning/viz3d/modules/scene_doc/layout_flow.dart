import 'dart:math' as math;
import '../../../../../app/theme/app_colors.dart';
import '../../render/scene_spec.dart';
import '../scene_kit.dart';
import '../viz_palette.dart';
import 'doc_state.dart';

/// Lays out `flow` scenes (interview strategy, frameworks, checklists). These are sequences of ideas rather than
/// physical things, so the cards are stepping stones: the active one rises and glows, finished ones turn green.
SceneSpec layoutFlow(DocState d) {
  final cards = asList(d.state['cards']).map(asMap).toList();
  final nodes = <SceneNode>[];
  final links = <SceneLink>[];
  final n = cards.length;
  const sp = 3.1;
  for (var i = 0; i < n; i++) {
    final s = str(cards[i]['s']);
    final active = s == 'active', done = s == 'done';
    final h = active ? 0.8 : (done ? 0.45 : 0.3);
    final x = SceneKit.rowX(i, n, sp);
    nodes.add(SceneNode(
      id: 'card:$i',
      shape: SceneShape.box,
      position: Vec3(x, h / 2, 0),
      size: Vec3(2.6, h, 2.0),
      color: active ? AppColors.primary : (done ? AppColors.success : VizPalette.plate),
      glow: active ? 0.9 : (done ? 0.2 : 0),
      opacity: done ? 0.85 : 1,
      label: SceneKit.short(str(cards[i]['title']), 12),
      labelSize: 0.34,
      labelColor: active || done ? AppColors.onAccent : AppColors.textPrimary,
      selectable: true,
      inspect: {'What': 'Step ${i + 1} of $n', 'Title': str(cards[i]['title']), 'Detail': str(cards[i]['text']), 'Status': active ? 'in progress' : (done ? 'done' : 'coming up')},
    ));
    nodes.add(SceneNode.label(id: 'num:$i', position: Vec3(x, 0.02, 1.35), text: '${i + 1}', color: active ? AppColors.primary : AppColors.textHint, labelSize: 0.4));
    if (i < n - 1) {
      links.add(SceneLink(
          id: 'next:$i',
          from: Vec3(x + 1.4, 0.3, 0),
          to: Vec3(SceneKit.rowX(i + 1, n, sp) - 1.4, 0.3, 0),
          color: done ? AppColors.success : AppColors.borderLight,
          directed: true,
          width: 2.2));
    }
  }
  // The active card's text stands in front of it, so the idea reads next to the step.
  for (var i = 0; i < n; i++) {
    if (str(cards[i]['s']) == 'active' && str(cards[i]['text']).isNotEmpty) {
      nodes.add(SceneNode.label(
          id: 'detail:$i', position: Vec3(SceneKit.rowX(i, n, sp), 0.02, 3.0), text: SceneKit.short(str(cards[i]['text']), 80), color: AppColors.textPrimary, labelSize: 0.3));
    }
  }
  return SceneSpec(nodes: nodes, links: links, camera: CameraHint(yaw: -0.2, pitch: math.min(0.7, 0.55)));
}
