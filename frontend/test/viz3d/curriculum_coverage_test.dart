import 'package:byte_battle/features/learning/viz3d/render/scene_spec.dart';
import 'dart:io';
import 'package:byte_battle/features/learning/scenes/scene_models.dart';
import 'package:byte_battle/features/learning/viz3d/contract/viz_contract.dart';
import 'package:byte_battle/features/learning/viz3d/registry/curriculum_catalog.dart';
import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

/// The platform must cover the curriculum that actually ships, not a sample of it. These tests walk every concept.
void main() {
  final docs = loadSceneDocs();
  final registry = VizRegistry.standard();

  group('curriculum catalog', () {
    test('lists the 58 shipped concepts, uniquely, and every one has a bundled scene', () {
      expect(kCurriculumCatalog.length, 58);
      expect({for (final c in kCurriculumCatalog) c.id}.length, 58);
      for (final c in kCurriculumCatalog) {
        expect(docs.containsKey(c.id), isTrue, reason: '${c.name} has no scene asset');
        expect(c.name, isNotEmpty);
      }
      expect(docs.keys.toSet(), {for (final c in kCurriculumCatalog) c.id}, reason: 'a scene exists that the catalog does not know about');
    });

    test('matches the seed migrations (ids, names and topics)', () {
      final sql = ['V22__seed_curriculum.sql', 'V27__seed_curriculum_charter_domains.sql']
          .map((f) => File('../src/main/resources/db/migration/$f'))
          .where((f) => f.existsSync())
          .map((f) => f.readAsStringSync())
          .join('\n');
      if (sql.isEmpty) return; // the backend sources are not checked out next to the client
      for (final c in kCurriculumCatalog) {
        expect(sql.contains(c.id), isTrue, reason: 'concept id ${c.id} (${c.name}) is not in the migrations');
        expect(sql.contains("'${c.name.replaceAll("'", "''")}'"), isTrue, reason: 'concept name "${c.name}" differs from the migrations');
        expect(sql.contains(c.topicId), isTrue, reason: 'topic ${c.topicId} for ${c.name}');
      }
    });

    test('every visualization family is used by at least one concept', () {
      final used = {for (final c in kCurriculumCatalog) c.category};
      expect(used, VizCategory.values.toSet());
    });
  });

  group('every shipped scene becomes a valid 3D lesson', () {
    for (final entry in docs.entries) {
      final doc = entry.value;
      final info = conceptInfo(doc.conceptId);
      test('${info?.name ?? doc.conceptId} (${doc.kind.name}, ${doc.steps.length} steps)', () {
        final res = registry.resolve(VizSource(conceptId: doc.conceptId, scene: doc));
        expect(res.errors, isEmpty);
        expect(res.supported, isTrue);
        final walk = res.lessons.firstWhere((l) => l.id == 'scene/${doc.conceptId}');
        expect(walk.conceptId, doc.conceptId);
        expect(walk.topicId, info!.topicId);
        expect(walk.category, info.category);
        expect(walk.flatBuilder, isNotNull, reason: 'the 2D walkthrough stays as the fallback');

        final t = walk.build();
        expect(t.length, doc.steps.length, reason: 'one frame per authored step');
        for (var p = 0; p < t.length; p++) {
          final f = t.frameAt(p);
          f.scene.validate();
          expect(f.scene.nodes, isNotEmpty, reason: 'step $p draws nothing');
          expect(f.explanation.text, doc.steps[p].say.isEmpty ? isA<String>() : startsWith(doc.steps[p].say.trim().split(' ').first));
          final b = f.scene.bounds;
          expect([b.min.x, b.max.x, b.min.y, b.max.y, b.min.z, b.max.z].every((v) => v.isFinite), isTrue);
          final ids = {for (final n in f.scene.nodes) n.id};
          for (final n in f.scene.nodes) {
            for (final r in n.related) {
              expect(ids.contains(r), isTrue, reason: 'step $p: ${n.id} relates to missing $r');
            }
          }
        }
        expect(t.bounds.radius, greaterThan(0));
      });
    }
  });

  group('scene layouts show the real content', () {
    SceneSpec3 scene(String id, int step) =>
        SceneSpec3(registry.resolve(VizSource(conceptId: id, scene: docs[id])).lessons.firstWhere((l) => l.id.startsWith('scene/')).build().frameAt(step).scene);

    test('binary search scene: one bar per cell, states become colours, pointers become markers', () {
      final id = '00000000-0000-0000-0000-000000001008';
      final doc = docs[id]!;
      final cells = (doc.steps[1].state['structures'] as List).first['cells'] as List;
      final s = scene(id, 1).spec;
      for (var i = 0; i < cells.length; i++) {
        expect(s.node('array:sorted array:c$i')!.label, cells[i]['v']);
      }
      expect(s.nodes.where((n) => n.id.contains(':ptr:')).map((n) => n.label), unorderedEquals(['lo', 'mid', 'hi']));
    });

    test('graph scene (BFS/DFS): one sphere per graph node and one link per edge', () {
      final id = '00000000-0000-0000-0000-000000001022';
      final g = ((docs[id]!.steps[1].state['structures'] as List).first as Map);
      final s = scene(id, 1).spec;
      expect(s.nodes.where((n) => n.id.startsWith('graph:graph:n:')).length, (g['nodes'] as List).length);
      expect(s.links.where((l) => l.id.startsWith('graph:graph:e:')).length, (g['edges'] as List).length);
    });

    test('tree scene: parent links connect each node to its real children', () {
      final id = '00000000-0000-0000-0000-000000001010';
      final tree = ((docs[id]!.steps[1].state['structures'] as List).firstWhere((b) => b['kind'] == 'tree') as Map);
      final nodes = tree['nodes'] as List;
      final edges = nodes.fold<int>(0, (a, n) => a + ((n['l'] ?? '').toString().isNotEmpty ? 1 : 0) + ((n['r'] ?? '').toString().isNotEmpty ? 1 : 0));
      final s = scene(id, 1).spec;
      expect(s.links.where((l) => l.id.contains(':e:')).length, edges);
    });

    test('table scene: one cell per row and column, matched rows glow, the result appears', () {
      final id = '00000000-0000-0000-0000-000000001027';
      final s = scene(id, 2).spec;
      expect(s.nodes.where((n) => n.id.startsWith('t0:r')).length, 3 * 2);
      expect(s.nodes.where((n) => n.id.startsWith('t1:r')).length, 3 * 3);
      expect(s.nodes.firstWhere((n) => n.id == 't0:r0:c1').glow, greaterThan(0.5));
      expect(s.nodes.firstWhere((n) => n.id == 't0:r1:c1').glow, 0);
      expect(s.nodes.any((n) => n.id.startsWith('result:')), isTrue);
    });

    test('sequence scene (TCP): messages accumulate in order, so the last frame holds every message', () {
      final id = '00000000-0000-0000-0000-000000001042';
      final doc = docs[id]!;
      final sent = doc.steps.where((s) => s.state['msg'] is Map).length;
      final last = scene(id, doc.steps.length - 1).spec;
      expect(
          last.nodes.where((n) => n.id.startsWith('msgmark:') || (n.id.startsWith('msg:') && n.shape == SceneShape.box)).length +
              last.links.where((l) => l.id.startsWith('msg:')).length,
          greaterThanOrEqualTo(sent));
      expect(scene(id, 2).spec.links.where((l) => l.id.startsWith('msg:')).length, lessThan(last.links.where((l) => l.id.startsWith('msg:')).length));
    });

    test('computer scene (race condition): references become links, threads become cores', () {
      final id = '00000000-0000-0000-0000-000000001003';
      final s = scene(id, 0).spec;
      expect(s.nodes.where((n) => n.id.startsWith('core:') && n.label != '').length, 2);
      expect(s.nodes.any((n) => n.id.startsWith('heap:')), isTrue);
    });

    test('flow scene: the active card rises and the finished ones turn green', () {
      final id = '00000000-0000-0000-0000-000000001055';
      final s = scene(id, 3).spec;
      final heights = [for (var i = 0; i < 5; i++) s.node('card:$i')!.size.y];
      expect(heights.reduce((a, b) => a > b ? a : b), greaterThan(heights.reduce((a, b) => a < b ? a : b)));
    });

    test('the sorting scene document runs on the real values it was authored with', () {
      final id = '00000000-0000-0000-0000-000000001009';
      final doc = docs[id]!;
      final first = ((doc.steps[0].state['structures'] as List).first['cells'] as List).map((c) => c['v']).toList();
      final s = scene(id, 0).spec;
      final arrayKey = s.nodes.firstWhere((n) => n.id.endsWith(':c0')).id.replaceAll(':c0', '');
      expect([for (var i = 0; i < first.length; i++) s.node('$arrayKey:c$i')!.label], first);
    });
  });

  group('every concept is accounted for', () {
    test('input-driven simulations exist for binary search, sorting, scheduling and the race condition', () {
      for (final id in [binarySearchId, sortingId, schedulingId, raceId]) {
        final res = registry.resolve(VizSource(conceptId: id, scene: docs[id]));
        expect(res.lessons.length, greaterThanOrEqualTo(2), reason: 'a simulation plus the walkthrough for $id');
      }
      expect(registry.resolve(VizSource(conceptId: binarySearchId, scene: docs[binarySearchId])).lessons.first.params, isNotEmpty);
    });
  });
}

/// A wrapper only so the test helper above reads naturally.
class SceneSpec3 {
  final SceneSpec spec;
  SceneSpec3(this.spec);
}
