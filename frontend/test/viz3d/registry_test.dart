import 'package:byte_battle/features/learning/viz3d/registry/viz_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support.dart';

void main() {
  test('an empty registry reports an unsupported concept with a reason, not an empty scene', () {
    final r = VizRegistry().resolve(const VizSource(conceptId: 'anything'));
    expect(r.supported, isFalse);
    expect(r.lessons, isEmpty);
    expect(r.unsupportedReason, contains('no 3D visualization'));
  });

  test('a concept with no scene, simulation or native lesson is unsupported in the standard registry', () {
    final r = VizRegistry.standard().resolve(const VizSource(conceptId: 'not-a-concept'));
    expect(r.supported, isFalse);
    expect(r.unsupportedReason, isNotNull);
  });

  test('a new lesson is added by registering an adapter, with no change to the page or the renderer', () {
    final r = VizRegistry.standard();
    r.register('counter', (s) => s.conceptId == 'my-concept' ? [counterLesson(id: 'mine')] : const []);
    final res = r.resolve(const VizSource(conceptId: 'my-concept'));
    expect(res.supported, isTrue);
    expect(res.lessons.single.id, 'mine');
    expect(r.resolve(const VizSource(conceptId: 'other')).supported, isFalse);
  });

  test('adapters run in registration order, and re-registering a name replaces it in place', () {
    final r = VizRegistry()
      ..register('a', (s) => [counterLesson(id: 'first')])
      ..register('b', (s) => [counterLesson(id: 'second')]);
    expect(r.resolve(const VizSource(conceptId: 'x')).lessons.map((l) => l.id), ['first', 'second']);
    r.register('a', (s) => [counterLesson(id: 'replaced')]);
    expect(r.resolve(const VizSource(conceptId: 'x')).lessons.map((l) => l.id), ['replaced', 'second']);
    expect(r.adapterNames, ['a', 'b']);
    r.unregister('a');
    expect(r.resolve(const VizSource(conceptId: 'x')).lessons.map((l) => l.id), ['second']);
  });

  test('a faulty adapter is skipped and reported, and the others still resolve', () {
    final r = VizRegistry()
      ..register('broken', (s) => throw StateError('adapter exploded'))
      ..register('fine', (s) => [counterLesson()]);
    final res = r.resolve(const VizSource(conceptId: 'x'));
    expect(res.supported, isTrue);
    expect(res.errors.single, contains('adapter exploded'));
  });

  test('the standard registry names every built-in module', () {
    expect(VizRegistry.standard().adapterNames, ['thread-schedule', 'binary-search', 'insertion-sort', 'round-robin', 'scene-doc']);
  });
}
