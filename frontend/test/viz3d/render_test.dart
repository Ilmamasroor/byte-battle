import 'dart:math' as math;
import 'dart:ui';
import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:byte_battle/features/learning/viz3d/render/orbit_camera.dart';
import 'package:byte_battle/features/learning/viz3d/render/scene_painter.dart';
import 'package:byte_battle/features/learning/viz3d/render/scene_spec.dart';
import 'package:byte_battle/features/learning/viz3d/render/scene_tween.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

SceneNode _box(String id, double x, {double z = 0, double opacity = 1, bool selectable = true, Color color = Colors.orange}) =>
    SceneNode(id: id, shape: SceneShape.box, position: Vec3(x, 0.5, z), size: const Vec3(1, 1, 1), color: color, opacity: opacity, selectable: selectable);

class _ThrowingScene extends SceneSpec {
  @override
  List<SceneNode> get nodes => throw StateError('gpu lost');
}

void main() {
  group('OrbitCamera', () {
    test('the target projects to the middle of the viewport', () {
      final cam = OrbitCamera(target: const Vec3(2, 1, -3), distance: 10);
      final p = cam.projection(const Size(400, 300)).project(const Vec3(2, 1, -3))!;
      expect(p.dx, closeTo(200, 0.01));
      expect(p.dy, closeTo(150, 0.01));
    });

    test('orbit changes the angle but clamps pitch above the floor and below straight-down', () {
      final cam = OrbitCamera();
      cam.orbit(1.0, 10);
      expect(cam.pitch, lessThan(math.pi / 2));
      cam.orbit(0, -20);
      expect(cam.pitch, greaterThan(0));
      final yaw = cam.yaw;
      cam.orbit(0.5, 0);
      expect(cam.yaw, closeTo(yaw + 0.5, 1e-9));
    });

    test('zoom is clamped to a sensible range', () {
      final cam = OrbitCamera(distance: 10);
      for (var i = 0; i < 100; i++) {
        cam.zoom(0.5);
      }
      expect(cam.distance, OrbitCamera.minDistance);
      for (var i = 0; i < 100; i++) {
        cam.zoom(2);
      }
      expect(cam.distance, OrbitCamera.maxDistance);
    });

    test('points behind the camera do not project', () {
      final cam = OrbitCamera(distance: 5, yaw: 0, pitch: 0.3);
      expect(cam.projection(const Size(100, 100)).project(cam.position * 2), isNull);
    });

    test('lerp and setFrom move every component', () {
      final a = OrbitCamera(distance: 10, yaw: 0, pitch: 0.2), b = OrbitCamera(distance: 20, yaw: 2, pitch: 0.8);
      final m = OrbitCamera.lerp(a, b, 0.5);
      expect(m.distance, 15.0);
      expect(m.yaw, 1.0);
      expect(m.pitch, closeTo(0.5, 1e-9));
      a.setFrom(b);
      expect(a.distance, 20);
    });

    test('the home camera keeps every frame of every kind of lesson inside the viewport', () {
      final docs = loadSceneDocs();
      final registry = VizRegistry.standard();
      final ids = [
        raceId,
        binarySearchId,
        sortingId,
        schedulingId,
        '00000000-0000-0000-0000-000000001022',
        '00000000-0000-0000-0000-000000001027',
        '00000000-0000-0000-0000-000000001042',
        '00000000-0000-0000-0000-000000001055',
        '00000000-0000-0000-0000-000000001036'
      ];
      for (final id in ids) {
        for (final lesson in registry.resolve(VizSource(conceptId: id, scene: docs[id])).lessons) {
          final tl = lesson.build();
          for (final aspect in [0.85, 1.6]) {
            final size = Size(400 * aspect, 400);
            final cam = OrbitCamera.fitting(tl.bounds, hint: tl.cameraHint, aspect: aspect);
            final proj = cam.projection(size);
            for (var p = 0; p < tl.length; p++) {
              for (final n in tl.frameAt(p).scene.nodes.where((n) => !n.backdrop && n.shape != SceneShape.label)) {
                final s = proj.project(n.position);
                expect(s, isNotNull, reason: '${lesson.id} @$p ${n.id}');
                expect(s!.dx, inInclusiveRange(-4, size.width + 4), reason: '${lesson.id} aspect $aspect @$p ${n.id} x=${s.dx}');
                expect(s.dy, inInclusiveRange(-4, size.height + 4), reason: '${lesson.id} aspect $aspect @$p ${n.id} y=${s.dy}');
              }
            }
          }
        }
      }
    });
  });

  group('SceneSpec', () {
    test('rejects duplicate ids and non-finite numbers, accepts a sane scene', () {
      SceneSpec(nodes: [_box('a', 0), _box('b', 1)]).validate();
      expect(() => SceneSpec(nodes: [_box('a', 0), _box('a', 1)]).validate(), throwsStateError);
      expect(() => SceneSpec(nodes: [_box('a', double.nan)]).validate(), throwsStateError);
      expect(() => SceneSpec(links: const [SceneLink(id: 'l', from: Vec3.zero, to: Vec3(double.infinity, 0, 0), color: Colors.white)]).validate(), throwsStateError);
    });

    test('bounds ignore backdrop plates but include everything else', () {
      final s = SceneSpec(nodes: [
        _box('a', 0),
        _box('b', 4),
        const SceneNode(id: 'board', shape: SceneShape.box, position: Vec3(0, -0.1, 0), size: Vec3(100, 0.2, 100), color: Colors.grey, backdrop: true),
      ]);
      expect(s.bounds.max.x, closeTo(4.5, 1e-9));
      expect(s.bounds.min.x, closeTo(-0.5, 1e-9));
    });

    test('an empty scene still has usable bounds', () {
      expect(SceneSpec.empty.bounds.radius, greaterThan(0));
    });
  });

  group('SceneTween', () {
    test('returns the end points exactly and glides matched objects in between', () {
      final a = SceneSpec(nodes: [_box('a', 0)]), b = SceneSpec(nodes: [_box('a', 10)]);
      expect(identical(SceneTween.lerp(a, b, 0), a), isTrue);
      expect(identical(SceneTween.lerp(a, b, 1), b), isTrue);
      expect(SceneTween.lerp(a, b, 0.5).nodes.single.position.x, closeTo(5, 1e-9));
    });

    test('fades objects in and out when they only exist on one side', () {
      final a = SceneSpec(nodes: [_box('gone', 0)]), b = SceneSpec(nodes: [_box('new', 1)]);
      final m = SceneTween.lerp(a, b, 0.25);
      expect(m.node('new')!.opacity, closeTo(0.25, 1e-9));
      expect(m.node('gone')!.opacity, closeTo(0.75, 1e-9));
    });

    test('blends colours and links', () {
      final a = SceneSpec(nodes: [_box('a', 0, color: const Color(0xFF000000))], links: const [SceneLink(id: 'l', from: Vec3.zero, to: Vec3(2, 0, 0), color: Colors.white)]);
      final b = SceneSpec(nodes: [_box('a', 0, color: const Color(0xFFFFFFFF))], links: const [SceneLink(id: 'l', from: Vec3.zero, to: Vec3(4, 0, 0), color: Colors.white)]);
      final m = SceneTween.lerp(a, b, 0.5);
      expect(m.nodes.single.color.red, closeTo(128, 1));
      expect(m.links.single.to.x, closeTo(3, 1e-9));
    });
  });

  group('picking', () {
    final cam = OrbitCamera(target: const Vec3(0, 0.5, 0), distance: 12, yaw: 0, pitch: 0.4);
    const size = Size(400, 300);

    test('selects the selectable node under the pointer and nothing in empty space', () {
      final scene = SceneSpec(nodes: [_box('a', 0)]);
      final centre = cam.projection(size).project(const Vec3(0, 0.5, 0))!;
      expect(ScenePainter.pick(scene, cam, size, centre), 'a');
      expect(ScenePainter.pick(scene, cam, size, const Offset(5, 5)), isNull);
    });

    test('prefers the node nearer the camera when two overlap', () {
      final scene = SceneSpec(nodes: [_box('far', 0, z: -2), _box('near', 0, z: 2)]);
      final p = cam.projection(size).project(const Vec3(0, 0.5, 2))!;
      expect(ScenePainter.pick(scene, cam, size, p), 'near');
    });

    test('skips nodes that are not selectable or are faded out', () {
      final scene = SceneSpec(nodes: [_box('plain', 0, selectable: false), _box('ghost', 0, opacity: 0.1)]);
      final p = cam.projection(size).project(const Vec3(0, 0.5, 0))!;
      expect(ScenePainter.pick(scene, cam, size, p), isNull);
    });
  });

  group('painter', () {
    Future<void> paintOnce(SceneSpec scene, {void Function(Object)? onError}) async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      ScenePainter(scene: scene, camera: OrbitCamera.fitting(SceneBounds.unit, hint: const CameraHint(), aspect: 1.4), onError: onError).paint(canvas, const Size(500, 360));
      recorder.endRecording().dispose();
    }

    test('draws every kind of shape, link and label without error', () async {
      final scene = SceneSpec(nodes: [
        _box('box', 0),
        const SceneNode(id: 'wire', shape: SceneShape.box, position: Vec3(2, 0.5, 0), size: Vec3(1, 1, 1), color: Colors.cyan, wire: true, glow: 0.6),
        const SceneNode(id: 'cyl', shape: SceneShape.cylinder, position: Vec3(-2, 0.5, 0), size: Vec3(1, 1, 1), color: Colors.green, glow: 0.8, label: 'x', caption: 'cap'),
        const SceneNode(id: 'ball', shape: SceneShape.sphere, position: Vec3(0, 0.5, 2), size: Vec3(1, 1, 1), color: Colors.purple, glow: 1, label: 'o'),
        const SceneNode.label(id: 'text', position: Vec3(0, 2, 0), text: 'hello'),
      ], links: const [
        SceneLink(id: 'l1', from: Vec3(-2, 1, 0), to: Vec3(2, 1, 0), color: Colors.white, directed: true, label: 'link', glow: 0.5),
        SceneLink(id: 'l2', from: Vec3(-2, 0.1, 2), to: Vec3(2, 0.1, 2), color: Colors.white, dashed: true),
      ]);
      final errors = <Object>[];
      await paintOnce(scene, onError: errors.add);
      expect(errors, isEmpty);
    });

    test('draws every frame of representative lessons without error', () async {
      final docs = loadSceneDocs();
      final registry = VizRegistry.standard();
      final errors = <Object>[];
      for (final id in [raceId, binarySearchId, schedulingId, '00000000-0000-0000-0000-000000001010', '00000000-0000-0000-0000-000000001036']) {
        for (final lesson in registry.resolve(VizSource(conceptId: id, scene: docs[id])).lessons) {
          final tl = lesson.build();
          for (var p = 0; p < tl.length; p++) {
            await paintOnce(tl.frameAt(p).scene, onError: errors.add);
          }
        }
      }
      expect(errors, isEmpty);
    });

    test('reports a drawing failure through onError instead of throwing into the framework', () async {
      final errors = <Object>[];
      await paintOnce(_ThrowingScene(), onError: errors.add);
      expect(errors.single, isA<StateError>());
    });
  });
}
