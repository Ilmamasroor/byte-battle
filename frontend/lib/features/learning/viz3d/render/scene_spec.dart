import 'dart:math' as math;
import 'dart:ui';

/// A point or size in scene space. Scene space is right-handed with +y up; one unit is roughly one array cell.
class Vec3 {
  final double x;
  final double y;
  final double z;
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : Vec3(x / l, y / l, z / l);
  }

  static Vec3 lerp(Vec3 a, Vec3 b, double t) => Vec3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);

  @override
  bool operator ==(Object other) => other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// The few solid shapes every scene is built from. Anything richer is a composition of these.
enum SceneShape { box, cylinder, sphere, label }

/// One object in a scene. The renderer knows nothing about what it means; a topic module decides that a box is a
/// memory cell, a tree node, a packet or a server.
///
/// [id] must be stable across frames: it is how the renderer animates the same object from one step to the next.
class SceneNode {
  final String id;
  final SceneShape shape;
  final Vec3 position; // centre of the shape
  final Vec3 size; // full extents (x, y, z). Cylinders and spheres use x as the diameter and y as the height.
  final Color color;
  final double glow; // 0..1 emissive strength
  final double opacity;
  final String? label;
  final String? caption; // smaller second line under the label
  final Color? labelColor;
  final double labelSize; // world units tall for [SceneShape.label]; for solids the label is drawn on the top face
  final bool selectable;
  final Map<String, String> inspect; // what the inspector card shows when this node is selected
  final List<String> related; // ids highlighted together with this node when it is selected
  final bool wire; // draw edges only (an "empty" slot)

  /// A support plate (board, platform). Drawn like any solid but ignored when fitting the camera to the scene.
  final bool backdrop;

  const SceneNode({
    required this.id,
    required this.shape,
    required this.position,
    required this.size,
    required this.color,
    this.glow = 0,
    this.opacity = 1,
    this.label,
    this.caption,
    this.labelColor,
    this.labelSize = 0.34,
    this.selectable = false,
    this.inspect = const {},
    this.related = const [],
    this.wire = false,
    this.backdrop = false,
  });

  const SceneNode.label({
    required this.id,
    required this.position,
    required String text,
    this.color = const Color(0xFFF7F3EE),
    this.labelSize = 0.34,
    this.opacity = 1,
  })  : shape = SceneShape.label,
        size = Vec3.zero,
        glow = 0,
        label = text,
        caption = null,
        labelColor = null,
        selectable = false,
        inspect = const {},
        related = const [],
        wire = false,
        backdrop = false;

  SceneNode copyWith({Vec3? position, Vec3? size, Color? color, double? glow, double? opacity, bool? wire}) => SceneNode(
        id: id,
        shape: shape,
        position: position ?? this.position,
        size: size ?? this.size,
        color: color ?? this.color,
        glow: glow ?? this.glow,
        opacity: opacity ?? this.opacity,
        label: label,
        caption: caption,
        labelColor: labelColor,
        labelSize: labelSize,
        selectable: selectable,
        inspect: inspect,
        related: related,
        wire: wire ?? this.wire,
        backdrop: backdrop,
      );
}

/// A line between two scene points (or two nodes). Used for pointers, edges, wires and message paths.
class SceneLink {
  final String id;
  final Vec3 from;
  final Vec3 to;
  final Color color;
  final double glow;
  final double width; // screen pixels at distance 10
  final bool directed;
  final bool dashed;
  final String? label;
  final double opacity;

  const SceneLink({
    required this.id,
    required this.from,
    required this.to,
    required this.color,
    this.glow = 0,
    this.width = 2,
    this.directed = false,
    this.dashed = false,
    this.label,
    this.opacity = 1,
  });
}

/// Where the camera should rest when the learner has not moved it. [yaw] and [pitch] are the preferred viewing
/// angle (radians). The viewer fits the camera target and distance to the lesson's overall [SceneBounds], so
/// modules only choose an angle.
class CameraHint {
  final double yaw;
  final double pitch;
  const CameraHint({this.yaw = -0.45, this.pitch = 0.55});
}

/// An axis-aligned box around everything a scene (or a whole timeline) draws.
class SceneBounds {
  final Vec3 min;
  final Vec3 max;
  const SceneBounds(this.min, this.max);

  Vec3 get centre => Vec3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2);

  /// Radius of the sphere that encloses the box.
  double get radius => Vec3(max.x - min.x, max.y - min.y, max.z - min.z).length / 2;

  SceneBounds union(SceneBounds o) => SceneBounds(
      Vec3(math.min(min.x, o.min.x), math.min(min.y, o.min.y), math.min(min.z, o.min.z)), Vec3(math.max(max.x, o.max.x), math.max(max.y, o.max.y), math.max(max.z, o.max.z)));

  static const unit = SceneBounds(Vec3(-3, 0, -3), Vec3(3, 2, 3));
}

/// The renderer-facing description of one frame. It is plain data: no Flutter widgets, no lesson types, which is
/// what keeps the renderer independent of any topic.
class SceneSpec {
  final List<SceneNode> nodes;
  final List<SceneLink> links;
  final CameraHint camera;
  final bool floor; // draw the ground grid
  final Color floorColor;

  const SceneSpec({
    this.nodes = const [],
    this.links = const [],
    this.camera = const CameraHint(),
    this.floor = true,
    this.floorColor = const Color(0xFF2E2B3C),
  });

  static const empty = SceneSpec();

  /// The box around all nodes and links; [SceneBounds.unit] for an empty scene.
  SceneBounds get bounds {
    if (nodes.isEmpty && links.isEmpty) return SceneBounds.unit;
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;
    void add(Vec3 p, Vec3 half) {
      minX = math.min(minX, p.x - half.x);
      maxX = math.max(maxX, p.x + half.x);
      minY = math.min(minY, p.y - half.y);
      maxY = math.max(maxY, p.y + half.y);
      minZ = math.min(minZ, p.z - half.z);
      maxZ = math.max(maxZ, p.z + half.z);
    }

    final solids = nodes.where((n) => !n.backdrop);
    for (final n in solids.isEmpty ? nodes : solids) {
      add(n.position, n.shape == SceneShape.label ? Vec3(n.label == null ? 0 : n.label!.length * n.labelSize * 0.3, n.labelSize / 2, 0) : n.size * 0.5);
    }
    for (final l in links) {
      add(l.from, Vec3.zero);
      add(l.to, Vec3.zero);
    }
    return SceneBounds(Vec3(minX, math.min(minY, 0), minZ), Vec3(maxX, maxY, maxZ));
  }

  SceneNode? node(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Throws [StateError] when the spec cannot be drawn (duplicate ids, non-finite numbers). Called before a frame
  /// is accepted so a bad module degrades to the fallback instead of painting garbage.
  void validate() {
    final seen = <String>{};
    for (final n in nodes) {
      if (!seen.add(n.id)) throw StateError('duplicate scene node id "${n.id}"');
      final p = n.position;
      final s = n.size;
      for (final v in [p.x, p.y, p.z, s.x, s.y, s.z, n.glow, n.opacity]) {
        if (!v.isFinite) throw StateError('scene node "${n.id}" has a non-finite value');
      }
    }
    for (final l in links) {
      for (final v in [l.from.x, l.from.y, l.from.z, l.to.x, l.to.y, l.to.z]) {
        if (!v.isFinite) throw StateError('scene link "${l.id}" has a non-finite value');
      }
    }
  }
}
