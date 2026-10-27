import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'orbit_camera.dart';
import 'scene_spec.dart';

/// A small software 3D renderer built on [Canvas]: perspective projection, back-face culling, a depth-sorted
/// painter's algorithm, one directional light plus ambient, and an emissive term for glow.
///
/// It was chosen over a GPU plugin because it runs unchanged on every platform the app targets (including web and
/// integrated graphics), needs no assets or native code, and the scenes are small (tens of solids, not millions
/// of triangles). Geometry tables below are shared by every node; no per-node meshes are allocated.
class ScenePainter extends CustomPainter {
  final SceneSpec scene;
  final OrbitCamera camera;
  final Set<String> highlighted;
  final String? selectedId;

  /// Called (after the frame) when drawing threw, so the viewport can swap in its fallback.
  final void Function(Object error)? onError;

  const ScenePainter({required this.scene, required this.camera, this.highlighted = const {}, this.selectedId, this.onError});

  static const _light = Vec3(-0.35, 0.85, 0.4);

  // Unit-cube corners and the six faces (corner indexes, outward normal).
  static const _corners = [
    Vec3(-1, -1, -1), Vec3(1, -1, -1), Vec3(1, 1, -1), Vec3(-1, 1, -1), //
    Vec3(-1, -1, 1), Vec3(1, -1, 1), Vec3(1, 1, 1), Vec3(-1, 1, 1),
  ];
  static const _faces = [
    [4, 5, 6, 7], // +z
    [1, 0, 3, 2], // -z
    [5, 1, 2, 6], // +x
    [0, 4, 7, 3], // -x
    [7, 6, 2, 3], // +y (top)
    [0, 1, 5, 4], // -y
  ];
  static const _normals = [Vec3(0, 0, 1), Vec3(0, 0, -1), Vec3(1, 0, 0), Vec3(-1, 0, 0), Vec3(0, 1, 0), Vec3(0, -1, 0)];
  static const _sides = 14;

  /// Added to the depth of support plates so they always draw first (behind everything standing on them).
  static const _backdropBias = 1000.0;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      _paint(canvas, size);
    } catch (e) {
      onError?.call(e);
    }
  }

  void _paint(Canvas canvas, Size size) {
    final proj = camera.projection(size);
    final dimOthers = highlighted.isNotEmpty;
    final draws = <_Draw>[];

    if (scene.floor) _floor(canvas, proj);

    for (final n in scene.nodes) {
      if (n.opacity <= 0.01) continue;
      final dim = dimOthers && !highlighted.contains(n.id) ? 0.42 : 1.0;
      final sel = highlighted.contains(n.id);
      switch (n.shape) {
        case SceneShape.box:
          _box(draws, proj, n, dim, sel);
        case SceneShape.cylinder:
          _cylinder(draws, proj, n, dim, sel);
        case SceneShape.sphere:
          _sphere(draws, proj, n, dim, sel);
        case SceneShape.label:
          _label(draws, proj, n);
      }
    }
    for (final l in scene.links) {
      if (l.opacity <= 0.01) continue;
      _link(draws, proj, l);
    }

    draws.sort((a, b) => b.depth.compareTo(a.depth));
    for (final d in draws) {
      d.draw(canvas);
    }
  }

  // --------------------------------------------------------------- floor

  void _floor(Canvas canvas, Projection proj) {
    if (scene.nodes.isEmpty) return;
    var minX = double.infinity, maxX = -double.infinity, minZ = double.infinity, maxZ = -double.infinity;
    for (final n in scene.nodes) {
      final hx = n.size.x / 2, hz = n.size.z / 2;
      minX = math.min(minX, n.position.x - hx);
      maxX = math.max(maxX, n.position.x + hx);
      minZ = math.min(minZ, n.position.z - hz);
      maxZ = math.max(maxZ, n.position.z + hz);
    }
    final x0 = (minX - 2).floorToDouble(), x1 = (maxX + 2).ceilToDouble();
    final z0 = (minZ - 2).floorToDouble(), z1 = (maxZ + 2).ceilToDouble();
    final stepX = math.max(1, ((x1 - x0) / 30).ceil()).toDouble();
    final stepZ = math.max(1, ((z1 - z0) / 30).ceil()).toDouble();
    final paint = Paint()
      ..color = scene.floorColor.withOpacity(0.55)
      ..strokeWidth = 1;
    for (var x = x0; x <= x1; x += stepX) {
      final a = proj.project(Vec3(x, 0, z0)), b = proj.project(Vec3(x, 0, z1));
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
    for (var z = z0; z <= z1; z += stepZ) {
      final a = proj.project(Vec3(x0, 0, z)), b = proj.project(Vec3(x1, 0, z));
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  // --------------------------------------------------------------- solids

  Color _lit(Color base, Vec3 normal, double glow, double dim, double opacity) {
    final k = 0.42 + 0.58 * math.max(0.0, normal.normalized().dot(_light.normalized()));
    var r = base.red * k, g = base.green * k, b = base.blue * k;
    if (glow > 0) {
      // Emissive: pull toward a brighter version of the base colour, independent of the light direction.
      final e = glow.clamp(0.0, 1.0) * 0.55;
      r = r + (math.min(255.0, base.red * 1.25 + 30) - r) * e;
      g = g + (math.min(255.0, base.green * 1.25 + 30) - g) * e;
      b = b + (math.min(255.0, base.blue * 1.25 + 30) - b) * e;
    }
    return Color.fromRGBO(r.round().clamp(0, 255), g.round().clamp(0, 255), b.round().clamp(0, 255), (opacity * dim).clamp(0.0, 1.0));
  }

  void _box(List<_Draw> out, Projection proj, SceneNode n, double dim, bool selected) {
    final h = n.size * 0.5;
    final world = [for (final c in _corners) n.position + Vec3(c.x * h.x, c.y * h.y, c.z * h.z)];
    final screen = [for (final w in world) proj.project(w)];
    if (screen.any((s) => s == null)) return;
    final opacity = n.opacity;
    for (var f = 0; f < 6; f++) {
      final idx = _faces[f];
      final normal = _normals[f];
      final centre = n.position + Vec3(normal.x * h.x, normal.y * h.y, normal.z * h.z);
      if ((centre - proj.eye).dot(normal) >= 0) continue; // faces away from the camera
      final path = Path()..moveTo(screen[idx[0]]!.dx, screen[idx[0]]!.dy);
      for (var i = 1; i < 4; i++) {
        path.lineTo(screen[idx[i]]!.dx, screen[idx[i]]!.dy);
      }
      path.close();
      final fill = _lit(n.color, normal, n.glow, dim, opacity);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 0.9
        ..color = selected ? Colors.white.withOpacity(0.95 * opacity) : Color.lerp(fill, Colors.white, 0.28)!.withOpacity(0.7 * opacity * dim);
      final glowing = n.glow > 0.05;
      final glowPaint = glowing
          ? (Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4 + 6 * n.glow
            ..color = n.color.withOpacity(0.16 * n.glow * opacity * dim))
          : null;
      final wire = n.wire;
      out.add(_Draw(proj.depth(centre) + (n.backdrop ? _backdropBias : 0), (c) {
        if (!wire) c.drawPath(path, Paint()..color = fill);
        if (glowPaint != null && f == 4) c.drawPath(path, glowPaint);
        c.drawPath(path, edge);
      }));
    }
    _solidLabels(out, proj, n, h.y, dim);
  }

  void _cylinder(List<_Draw> out, Projection proj, SceneNode n, double dim, bool selected) {
    final r = n.size.x / 2, hy = n.size.y / 2;
    final top = <Vec3>[], bottom = <Vec3>[];
    for (var i = 0; i < _sides; i++) {
      final a = i / _sides * math.pi * 2;
      final dx = math.cos(a) * r, dz = math.sin(a) * r;
      top.add(n.position + Vec3(dx, hy, dz));
      bottom.add(n.position + Vec3(dx, -hy, dz));
    }
    final st = [for (final p in top) proj.project(p)], sb = [for (final p in bottom) proj.project(p)];
    if (st.any((s) => s == null) || sb.any((s) => s == null)) return;
    for (var i = 0; i < _sides; i++) {
      final j = (i + 1) % _sides;
      final a = (i + 0.5) / _sides * math.pi * 2;
      final normal = Vec3(math.cos(a), 0, math.sin(a));
      final centre = n.position + Vec3(normal.x * r, 0, normal.z * r);
      if ((centre - proj.eye).dot(normal) >= 0) continue;
      final path = Path()
        ..moveTo(st[i]!.dx, st[i]!.dy)
        ..lineTo(st[j]!.dx, st[j]!.dy)
        ..lineTo(sb[j]!.dx, sb[j]!.dy)
        ..lineTo(sb[i]!.dx, sb[i]!.dy)
        ..close();
      final fill = _lit(n.color, normal, n.glow, dim, n.opacity);
      out.add(_Draw(proj.depth(centre) + (n.backdrop ? _backdropBias : 0), (c) => c.drawPath(path, Paint()..color = fill)));
    }
    final cap = Path()..moveTo(st[0]!.dx, st[0]!.dy);
    for (var i = 1; i < _sides; i++) {
      cap.lineTo(st[i]!.dx, st[i]!.dy);
    }
    cap.close();
    final capFill = _lit(n.color, const Vec3(0, 1, 0), n.glow, dim, n.opacity);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.2 : 1
      ..color = selected ? Colors.white : Color.lerp(capFill, Colors.white, 0.3)!.withOpacity(0.8 * n.opacity * dim);
    final capCentre = n.position + Vec3(0, hy, 0);
    out.add(_Draw(proj.depth(capCentre) + (n.backdrop ? _backdropBias : 0), (c) {
      c.drawPath(cap, Paint()..color = capFill);
      if (n.glow > 0.05) {
        c.drawPath(
            cap,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4 + 6 * n.glow
              ..color = n.color.withOpacity(0.18 * n.glow * n.opacity * dim));
      }
      c.drawPath(cap, rim);
    }));
    _solidLabels(out, proj, n, hy, dim);
  }

  void _sphere(List<_Draw> out, Projection proj, SceneNode n, double dim, bool selected) {
    final centre = proj.project(n.position);
    if (centre == null) return;
    final r = n.size.x / 2 * proj.scaleAt(n.position);
    if (r < 0.5) return;
    final base = n.color;
    final hi = Color.lerp(base, Colors.white, 0.55)!;
    final lo = Color.lerp(base, Colors.black, 0.55)!;
    final a = (n.opacity * dim).clamp(0.0, 1.0);
    final d = proj.depth(n.position);
    out.add(_Draw(d, (c) {
      if (n.glow > 0.05) {
        c.drawCircle(centre, r * (1.5 + n.glow * 0.8), Paint()..color = base.withOpacity(0.16 * n.glow * a));
      }
      final shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 1.0,
        colors: [hi.withOpacity(a), base.withOpacity(a), lo.withOpacity(a)],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: centre, radius: r));
      c.drawCircle(centre, r, Paint()..shader = shader);
      if (selected) {
        c.drawCircle(
            centre,
            r + 1.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = Colors.white);
      }
    }));
    if (n.label != null) {
      final px = n.labelSize * proj.scaleAt(n.position);
      out.add(_Draw(d - 0.05, (c) => _text(c, n.label!, centre, math.max(r * 1.1, px), n.labelColor ?? Colors.white, a, bold: true)));
    }
  }

  void _solidLabels(List<_Draw> out, Projection proj, SceneNode n, double halfHeight, double dim) {
    final a = (n.opacity * dim).clamp(0.0, 1.0);
    if (n.label != null) {
      final anchor = n.position + Vec3(0, halfHeight + 0.01, 0);
      final p = proj.project(anchor);
      if (p != null) {
        final px = n.labelSize * proj.scaleAt(anchor);
        out.add(_Draw(proj.depth(anchor) - 0.02, (c) => _text(c, n.label!, p, px, n.labelColor ?? Colors.white, a, bold: true)));
      }
    }
    if (n.caption != null) {
      final anchor = n.position + Vec3(0, -halfHeight, n.size.z / 2 + 0.35);
      final p = proj.project(anchor);
      if (p != null) {
        final px = n.labelSize * 0.8 * proj.scaleAt(anchor);
        out.add(_Draw(proj.depth(anchor) - 0.02, (c) => _text(c, n.caption!, p, px, n.labelColor ?? const Color(0xFFBAB4C8), a)));
      }
    }
  }

  void _label(List<_Draw> out, Projection proj, SceneNode n) {
    final p = proj.project(n.position);
    if (p == null || n.label == null) return;
    final px = n.labelSize * proj.scaleAt(n.position);
    final dim = highlighted.isNotEmpty ? 0.7 : 1.0;
    out.add(_Draw(proj.depth(n.position) - 0.03, (c) => _text(c, n.label!, p, px, n.color, n.opacity * dim)));
  }

  // --------------------------------------------------------------- links

  void _link(List<_Draw> out, Projection proj, SceneLink l) {
    final a = proj.project(l.from), b = proj.project(l.to);
    if (a == null || b == null) return;
    final mid = Vec3.lerp(l.from, l.to, 0.5);
    final w = l.width * (proj.scaleAt(mid) / 40).clamp(0.6, 2.0);
    final color = l.color.withOpacity(l.opacity);
    out.add(_Draw(proj.depth(mid) - 0.01, (c) {
      if (l.glow > 0.05) {
        c.drawLine(
            a,
            b,
            Paint()
              ..strokeWidth = w + 5 + 5 * l.glow
              ..strokeCap = StrokeCap.round
              ..color = l.color.withOpacity(0.15 * l.glow * l.opacity));
      }
      final paint = Paint()
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = color;
      if (l.dashed) {
        final len = (b - a).distance;
        final dir = len == 0 ? Offset.zero : (b - a) / len;
        for (var d = 0.0; d < len; d += 12) {
          c.drawLine(a + dir * d, a + dir * math.min(d + 6, len), paint);
        }
      } else {
        c.drawLine(a, b, paint);
      }
      if (l.directed) {
        final len = (b - a).distance;
        if (len > 8) {
          final dir = (b - a) / len;
          final perp = Offset(-dir.dy, dir.dx);
          final s = 5 + w * 1.5;
          final tip = b;
          final path = Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - dir.dx * s * 1.6 + perp.dx * s, tip.dy - dir.dy * s * 1.6 + perp.dy * s)
            ..lineTo(tip.dx - dir.dx * s * 1.6 - perp.dx * s, tip.dy - dir.dy * s * 1.6 - perp.dy * s)
            ..close();
          c.drawPath(path, Paint()..color = color);
        }
      }
      if (l.label != null) _text(c, l.label!, (a + b) / 2 + const Offset(0, -9), 11, l.color, l.opacity);
    }));
  }

  // --------------------------------------------------------------- text

  static final Map<String, TextPainter> _textCache = {};

  /// Draws [text] centred on [at], [px] pixels tall, shrinking to fit a sensible number of characters. Text that
  /// would be unreadably small is skipped instead of drawn as a smudge.
  static void _text(Canvas canvas, String text, Offset at, double px, Color color, double opacity, {bool bold = false}) {
    // Below ~5.5px a label is a smudge, so skip it; between that and 9px draw it at 9px so it stays legible.
    if (px < 5.5 || opacity <= 0.02) return;
    final size = px.clamp(9.0, 40.0);
    final key = '$text|${size.round()}|${color.value}|$bold';
    var tp = _textCache[key];
    if (tp == null) {
      if (_textCache.length > 400) _textCache.clear();
      tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontFamily: 'JetBrainsMono', height: 1.1)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
      )..layout(maxWidth: size * 26);
      _textCache[key] = tp;
    }
    if (opacity < 0.99) {
      final rect = Rect.fromCenter(center: at, width: tp.width + 4, height: tp.height + 4);
      canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0)));
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      canvas.restore();
    } else {
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
  }

  // --------------------------------------------------------------- picking

  /// The selectable node under [point], nearest to the camera, or null. A pure function of the scene and camera
  /// so it can be tested without painting.
  static String? pick(SceneSpec scene, OrbitCamera camera, Size size, Offset point) {
    final proj = camera.projection(size);
    String? best;
    var bestDepth = double.infinity;
    for (final n in scene.nodes) {
      if (!n.selectable || n.opacity <= 0.3 || n.shape == SceneShape.label) continue;
      final h = n.shape == SceneShape.sphere ? Vec3(n.size.x / 2, n.size.x / 2, n.size.x / 2) : n.size * 0.5;
      Rect? bounds;
      for (final c in _corners) {
        final s = proj.project(n.position + Vec3(c.x * h.x, c.y * h.y, c.z * h.z));
        if (s == null) {
          bounds = null;
          break;
        }
        bounds = bounds == null ? Rect.fromLTWH(s.dx, s.dy, 0, 0) : bounds.expandToInclude(Rect.fromLTWH(s.dx, s.dy, 0, 0));
      }
      if (bounds == null || !bounds.inflate(4).contains(point)) continue;
      final d = proj.depth(n.position);
      if (d < bestDepth) {
        bestDepth = d;
        best = n.id;
      }
    }
    return best;
  }

  @override
  bool shouldRepaint(ScenePainter old) =>
      !identical(old.scene, scene) ||
      old.camera.yaw != camera.yaw ||
      old.camera.pitch != camera.pitch ||
      old.camera.distance != camera.distance ||
      old.camera.target != camera.target ||
      old.selectedId != selectedId ||
      old.highlighted != highlighted;
}

class _Draw {
  final double depth;
  final void Function(Canvas) draw;
  const _Draw(this.depth, this.draw);
}
