import 'dart:ui';
import 'scene_spec.dart';

/// Blends two [SceneSpec]s so objects glide from where they were to where they are now.
///
/// Objects are matched by id. Objects only in [to] fade in; objects only in [from] fade out. This is purely
/// presentation: the educational state of a frame is already complete in each spec, so the renderer never has to
/// replay earlier animations to show a later step.
class SceneTween {
  const SceneTween._();

  static SceneSpec lerp(SceneSpec a, SceneSpec b, double t) {
    if (t >= 1) return b;
    if (t <= 0) return a;
    final fromById = {for (final n in a.nodes) n.id: n};
    final toIds = {for (final n in b.nodes) n.id};
    final nodes = <SceneNode>[];
    for (final n in b.nodes) {
      final p = fromById[n.id];
      if (p == null || p.shape != n.shape) {
        nodes.add(n.copyWith(opacity: n.opacity * t));
      } else {
        nodes.add(n.copyWith(
          position: Vec3.lerp(p.position, n.position, t),
          size: Vec3.lerp(p.size, n.size, t),
          color: Color.lerp(p.color, n.color, t),
          glow: p.glow + (n.glow - p.glow) * t,
          opacity: p.opacity + (n.opacity - p.opacity) * t,
        ));
      }
    }
    for (final n in a.nodes) {
      if (!toIds.contains(n.id)) nodes.add(n.copyWith(opacity: n.opacity * (1 - t)));
    }

    final linkFrom = {for (final l in a.links) l.id: l};
    final linkTo = {for (final l in b.links) l.id};
    final links = <SceneLink>[];
    for (final l in b.links) {
      final p = linkFrom[l.id];
      if (p == null) {
        links.add(_link(l, l.from, l.to, l.color, l.glow, l.opacity * t));
      } else {
        links.add(_link(
            l, Vec3.lerp(p.from, l.from, t), Vec3.lerp(p.to, l.to, t), Color.lerp(p.color, l.color, t)!, p.glow + (l.glow - p.glow) * t, p.opacity + (l.opacity - p.opacity) * t));
      }
    }
    for (final l in a.links) {
      if (!linkTo.contains(l.id)) links.add(_link(l, l.from, l.to, l.color, l.glow, l.opacity * (1 - t)));
    }
    return SceneSpec(nodes: nodes, links: links, camera: b.camera, floor: b.floor, floorColor: b.floorColor);
  }

  static SceneLink _link(SceneLink o, Vec3 from, Vec3 to, Color color, double glow, double opacity) => SceneLink(
        id: o.id,
        from: from,
        to: to,
        color: color,
        glow: glow,
        width: o.width,
        directed: o.directed,
        dashed: o.dashed,
        label: o.label,
        opacity: opacity.clamp(0.0, 1.0),
      );
}
