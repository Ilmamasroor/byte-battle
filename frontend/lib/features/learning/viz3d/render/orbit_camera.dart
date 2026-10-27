import 'dart:math' as math;
import 'dart:ui';
import 'scene_spec.dart';

/// A camera that orbits a target point. It holds no educational state: moving it never changes what a lesson
/// shows, and resetting it never resets playback.
class OrbitCamera {
  Vec3 target;
  double distance;
  double yaw;
  double pitch;
  final double fovY;

  OrbitCamera({this.target = Vec3.zero, this.distance = 12, this.yaw = -0.45, this.pitch = 0.5, this.fovY = 0.8});

  static const minDistance = 3.0;
  static const maxDistance = 60.0;

  /// The resting ("home") camera for a lesson: aimed at the middle of [bounds], far enough back that the whole
  /// scene fits a viewport of the given [aspect] (width / height) from any angle the learner orbits to.
  factory OrbitCamera.fitting(SceneBounds bounds, {required CameraHint hint, double aspect = 1.4, double fovY = 0.8}) {
    final fovX = 2 * math.atan(math.tan(fovY / 2) * aspect);
    final fov = math.min(fovY, fovX);
    final d = (bounds.radius / math.sin(fov / 2) * 1.0).clamp(minDistance, maxDistance);
    return OrbitCamera(target: bounds.centre, distance: d, yaw: hint.yaw, pitch: hint.pitch, fovY: fovY);
  }

  OrbitCamera copy() => OrbitCamera(target: target, distance: distance, yaw: yaw, pitch: pitch, fovY: fovY);

  void orbit(double dYaw, double dPitch) {
    yaw += dYaw;
    pitch = (pitch + dPitch).clamp(0.05, math.pi / 2 - 0.05);
  }

  void zoom(double factor) {
    distance = (distance * factor).clamp(minDistance, maxDistance);
  }

  void setFrom(OrbitCamera o) {
    target = o.target;
    distance = o.distance;
    yaw = o.yaw;
    pitch = o.pitch;
  }

  static OrbitCamera lerp(OrbitCamera a, OrbitCamera b, double t) => OrbitCamera(
        target: Vec3.lerp(a.target, b.target, t),
        distance: a.distance + (b.distance - a.distance) * t,
        yaw: a.yaw + (b.yaw - a.yaw) * t,
        pitch: a.pitch + (b.pitch - a.pitch) * t,
        fovY: a.fovY,
      );

  Vec3 get position => target + Vec3(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch)) * distance;

  /// Builds the projection for a viewport of [size].
  Projection projection(Size size) => Projection._(this, size);
}

/// World-to-screen mapping for one camera and viewport.
class Projection {
  final OrbitCamera camera;
  final Size size;
  late final Vec3 eye = camera.position;
  late final Vec3 _fwd = (camera.target - eye).normalized();
  late final Vec3 _right = _fwd.cross(const Vec3(0, 1, 0)).normalized();
  late final Vec3 _up = _right.cross(_fwd);
  late final double _focal = (size.height / 2) / math.tan(camera.fovY / 2);

  Projection._(this.camera, this.size);

  /// View-space depth (distance along the view direction). Larger = farther away.
  double depth(Vec3 p) => (p - eye).dot(_fwd);

  /// Screen position of [p], or null when it is behind the camera.
  Offset? project(Vec3 p) {
    final v = p - eye;
    final d = v.dot(_fwd);
    if (d < 0.1) return null;
    final x = v.dot(_right);
    final y = v.dot(_up);
    return Offset(size.width / 2 + x / d * _focal, size.height / 2 - y / d * _focal);
  }

  /// How many pixels one world unit spans at the depth of [p].
  double scaleAt(Vec3 p) {
    final d = depth(p);
    return d < 0.1 ? 0 : _focal / d;
  }
}
