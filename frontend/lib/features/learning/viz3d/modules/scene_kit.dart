import 'dart:math' as math;
import 'dart:ui';
import '../render/scene_spec.dart';

/// Small layout helpers shared by topic modules. Nothing here knows about any topic.
class SceneKit {
  SceneKit._();

  /// X position of item [i] in a row of [n] items [spacing] apart, centred on x = 0.
  static double rowX(int i, int n, double spacing) => (i - (n - 1) / 2) * spacing;

  static String short(String s, int max) => s.length <= max ? s : '${s.substring(0, math.max(0, max - 1))}…';

  /// Height of a bar for [value] given the largest value in the set.
  static double barHeight(num value, num maxValue, {double min = 0.5, double max = 3.2}) {
    if (maxValue <= 0) return min;
    return min + (max - min) * (value / maxValue).clamp(0.0, 1.0);
  }

  /// A thin wire box that outlines the span of items [from]..[to] in a row, used to show "the part still in play".
  static SceneNode span(
      {required String id,
      required int from,
      required int to,
      required int n,
      required double spacing,
      required double height,
      required Vec3 centre,
      required Color color,
      double depth = 1.5}) {
    final x0 = rowX(from, n, spacing) - spacing / 2;
    final x1 = rowX(to, n, spacing) + spacing / 2;
    return SceneNode(
      id: id,
      shape: SceneShape.box,
      position: Vec3(centre.x + (x0 + x1) / 2, centre.y + height / 2, centre.z),
      size: Vec3(x1 - x0, height, depth),
      color: color,
      glow: 0.6,
      wire: true,
    );
  }
}
