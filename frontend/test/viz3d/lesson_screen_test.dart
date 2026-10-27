import 'dart:io';
import 'dart:convert';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/core/network/api_client.dart';
import 'package:byte_battle/core/network/backend_api.dart';
import 'package:byte_battle/core/storage/secure_storage_service.dart';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/features/learning/viz3d/render/viz_viewport.dart';
import 'package:byte_battle/features/learning/visualization/screens/visualization_screen.dart';
import 'package:byte_battle/features/learning/viz3d/modules/concurrency/thread_lanes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => null;
}

class _Silent implements SpeechEngine {
  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<List<String>> voices() async => const [];
}

/// Answers the visualization endpoint with [bodies] (by concept id) and 404 for everything else.
class _Backend implements HttpClientAdapter {
  final Map<String, Map<String, dynamic>> bodies;
  _Backend(this.bodies);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final m = RegExp(r'/api/visualize/concepts/([\w-]+)').firstMatch(options.path);
    final body = m == null ? null : bodies[m.group(1)];
    final json = body == null ? {'success': false, 'message': 'not found'} : {'success': true, 'data': body};
    return ResponseBody.fromString(jsonEncode(json), body == null ? 404 : 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// What `/api/visualize/concepts/{id}` returns for the race concept: the real simulator trace for the counter program.
Map<String, dynamic> _race() {
  final f = jsonDecode(File('test/fixtures/lost_update_trace.json').readAsStringSync()) as Map<String, dynamic>;
  return {
    'conceptId': '00000000-0000-0000-0000-000000001003',
    'title': 'Counter race',
    'code': f['code'],
    'visualization': {
      'schedules': f['schedules'],
      'hazards': f['hazards'],
      'fixSuggestion': f['fixSuggestion'],
      'support': f['support'],
      'provenance': f['provenance'],
    },
  };
}

Future<void> _open(WidgetTester t, String conceptId, {Map<String, Map<String, dynamic>> backend = const {}}) async {
  SharedPreferences.setMockInitialValues({});
  BitVoice.instance
    ..engine = _Silent()
    ..enabled = true
    ..available = true;
  BackendApi.useClient(ApiClient(secureStorage: _NoStorage(), dio: Dio(BaseOptions(baseUrl: 'http://test', validateStatus: (_) => true))..httpClientAdapter = _Backend(backend)));
  t.view.physicalSize = const Size(430 * 2, 2400 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: VisualizationScreen(conceptId: conceptId)));
  await t.pump(const Duration(milliseconds: 300));
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 900));
}

const raceId = '00000000-0000-0000-0000-000000001003';
const synchronizationId = '00000000-0000-0000-0000-000000001013';
const searchId = '00000000-0000-0000-0000-000000001008';
const tcpId = '00000000-0000-0000-0000-000000001042';

void main() {
  Future<void> next(WidgetTester t, int times) async {
    for (var i = 0; i < times; i++) {
      await t.ensureVisible(find.byIcon(Icons.skip_next_rounded)); // the synchronized lanes are tall
      await t.pump();
      await t.tap(find.byIcon(Icons.skip_next_rounded));
      await _settle(t);
    }
    await t.pump(const Duration(seconds: 2));
  }

  testWidgets('the lost-update lesson: predict, watch each event in the thread lanes, see the lost update, then the synchronized fix', (t) async {
    await _open(t, raceId, backend: {raceId: _race()});
    expect(find.text('See it happen'), findsOneWidget);
    expect(find.text('Thread simulator'), findsOneWidget);
    expect(find.text('3D lab'), findsOneWidget);
    expect(find.text('Inside the computer'), findsOneWidget);

    // guess first, exactly as before
    expect(find.textContaining('What do you think the counter ends at?'), findsOneWidget);
    await t.tap(find.text('2').first);
    await _settle(t);

    // the lanes are the default; 3D is optional; the source of the events is stated
    expect(find.byType(ThreadLanes), findsOneWidget);
    expect(find.byType(VizViewport), findsNothing);
    expect(find.byKey(const Key('provenance')), findsOneWidget);
    expect(find.text('TEACHING SIMULATION'), findsOneWidget);
    expect(find.textContaining('not a recording of a JVM run'), findsOneWidget);
    expect(find.text('The bug'), findsOneWidget);
    expect(find.text('Another order'), findsOneWidget);
    expect(find.text('With synchronized'), findsOneWidget);
    expect(find.text('You are the scheduler'), findsOneWidget);
    expect(find.text('EXECUTION TIMELINE'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('int tmp = count;'), findsNWidgets(2), reason: 'the learner\'s own statement, once per thread');

    await next(t, 6);
    expect(find.text('EVENT 6 OF 6'), findsOneWidget);
    expect(find.text('Lost update'), findsWidgets);
    expect(find.textContaining('increment is lost'), findsWidgets);
    expect(find.textContaining('should be 2'), findsWidgets);
    expect(find.byKey(const Key('prediction-result')), findsOneWidget);
    expect(find.text('You predicted 2. It ended at 1.'), findsOneWidget);
    expect(find.text('HOW TO FIX IT'), findsOneWidget);
    expect(t.takeException(), isNull);

    // the synchronized version, in the same layout, ends at 2
    await t.ensureVisible(find.text('Watch it with synchronized'));
    await t.pump();
    await t.tap(find.text('Watch it with synchronized'));
    await _settle(t);
    expect(find.byType(ThreadLanes), findsOneWidget);
    await next(t, 11);
    expect(find.text('EVENT 11 OF 11'), findsOneWidget);
    expect(find.textContaining('Every update survived'), findsWidgets);
    expect(find.textContaining('does not make every concurrent program safe'), findsNothing, reason: 'the fix card belongs to the buggy runs');
    expect(t.takeException(), isNull);
  });

  testWidgets('the 3D chamber is one tap away and follows the same position as the thread lanes', (t) async {
    await _open(t, raceId, backend: {raceId: _race()});
    await t.tap(find.text('2').first);
    await _settle(t);
    await next(t, 2);
    expect(find.textContaining('Thread B also reads count and sees 0'), findsWidgets);
    expect(find.text('my copy: 0'), findsNWidgets(2), reason: 'both threads hold the old 0');
    await t.tap(find.text('3D view'));
    await _settle(t);
    expect(find.byType(VizViewport), findsOneWidget);
    expect(find.byType(ThreadLanes), findsNothing);
    expect(find.text('EVENT 2 OF 6'), findsOneWidget, reason: 'switching the picture does not move the learner');
    await t.tap(find.text('Thread lanes'));
    await _settle(t);
    expect(find.byType(ThreadLanes), findsOneWidget);
    expect(find.text('EVENT 2 OF 6'), findsOneWidget);
  });

  testWidgets('with the backend unreachable the lesson runs on its authored example and says so', (t) async {
    await _open(t, raceId);
    expect(find.text('Thread simulator'), findsOneWidget);
    await t.tap(find.text('2').first);
    await _settle(t);
    expect(find.byType(ThreadLanes), findsOneWidget);
    expect(find.text('AUTHORED EXAMPLE'), findsOneWidget);
    expect(find.textContaining('not generated from your code'), findsOneWidget);
    expect(find.text('TEACHING SIMULATION'), findsNothing);
    await next(t, 6);
    expect(find.textContaining('increment is lost'), findsWidgets);
    expect(find.text('You predicted 2. It ended at 1.'), findsOneWidget);
  });

  testWidgets('a program the simulator cannot model is explained plainly, not drawn and not blamed on the learner', (t) async {
    await _open(t, synchronizationId, backend: {
      synchronizationId: {
        'conceptId': synchronizationId,
        'title': 'Unsupported',
        'code': 'class X {}',
        'visualization': {
          'schedules': [
            {'kind': 'RACE', 'threads': ['a', 'b'], 'steps': [], 'expected': {'count': 2}, 'finalValues': {'count': 1}}
          ],
          'hazards': [],
          'support': {
            'status': 'unsupported',
            'reasons': ['line 6: could not evaluate the calculation on \'tmp\' exactly; assumed +1']
          },
        },
      }
    });
    expect(find.byKey(const Key('unsupported')), findsOneWidget);
    expect(find.text('This program cannot be simulated accurately'), findsOneWidget);
    expect(find.textContaining('could not evaluate the calculation'), findsOneWidget);
    expect(find.textContaining('not a mistake in your answer'), findsOneWidget);
    expect(find.byType(ThreadLanes), findsNothing);
    expect(find.text('Thread simulator'), findsNothing);
  });

  testWidgets('audio is optional: muting keeps the captions, and the narration switch works', (t) async {
    await _open(t, raceId, backend: {raceId: _race()});
    await t.tap(find.text('2').first);
    await _settle(t);
    expect(find.byKey(const Key('narration-toggle')), findsOneWidget);
    await t.tap(find.byKey(const Key('narration-toggle')));
    await _settle(t);
    expect(BitVoice.instance.enabled, isFalse);
    await next(t, 1);
    expect(find.byKey(const Key('caption')), findsOneWidget);
    expect(find.textContaining('Thread A reads count from shared memory and sees 0'), findsWidgets);
    expect(find.byKey(const Key('hear-step')), findsNothing, reason: 'nothing to hear while muted');
    await t.tap(find.byKey(const Key('transcript-toggle')));
    await _settle(t);
    expect(find.byKey(const Key('transcript')), findsOneWidget);
  });

  testWidgets('a concept with only an authored scene opens in the 3D lab, with its simulation and walkthrough', (t) async {
    await _open(t, searchId);
    expect(find.text('3D lab'), findsOneWidget);
    expect(find.text('Animated walkthrough'), findsOneWidget);
    expect(find.text('Thread simulator'), findsNothing);
    expect(find.byType(VizViewport), findsOneWidget);
    expect(find.text('Try it yourself'), findsOneWidget);
    expect(find.text('Walkthrough'), findsOneWidget);
    expect(find.text('TARGET'), findsOneWidget);

    // change the input: the run is rebuilt from the start
    await t.tap(find.text('88'));
    await _settle(t);
    expect(find.textContaining('looking for 88'), findsNothing, reason: 'labels live inside the 3D canvas, not as widgets');
    await t.tap(find.byIcon(Icons.skip_next_rounded));
    await _settle(t);
    expect(find.textContaining('index 7'), findsWidgets, reason: 'the first probe of a 15-item list is its middle');

    // the original voice-driven 2D walkthrough is one tap away and unchanged
    await t.tap(find.text('Animated walkthrough'));
    await _settle(t);
    expect(find.byType(VizViewport), findsNothing);
    expect(find.text('Binary search: halve the problem each time'), findsOneWidget);
  });

  testWidgets('a protocol lesson shows as a 3D sequence with the guess-first question', (t) async {
    await _open(t, tcpId);
    expect(find.textContaining('How many messages must be exchanged'), findsOneWidget);
    await t.tap(find.text('Skip, just show me'));
    await _settle(t);
    expect(find.byType(VizViewport), findsOneWidget);
    await t.tap(find.byIcon(Icons.skip_next_rounded));
    await _settle(t);
    expect(find.textContaining('SYN'), findsWidgets);
  });

  testWidgets('a concept with nothing to show says so instead of an empty scene', (t) async {
    await _open(t, 'no-such-concept');
    expect(find.byType(VizViewport), findsNothing);
    expect(find.textContaining('no visualization'), findsOneWidget);
  });

  testWidgets('leaving the page mid-playback leaves no timers or listeners behind', (t) async {
    await _open(t, searchId);
    await t.tap(find.byIcon(Icons.play_arrow_rounded));
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 5));
    expect(t.takeException(), isNull);
  });
}
