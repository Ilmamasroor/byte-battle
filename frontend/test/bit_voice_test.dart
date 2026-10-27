import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/core/voice/bit_voice.dart';
import 'package:byte_battle/features/learning/scenes/scene_models.dart';
import 'package:byte_battle/features/learning/scenes/scene_view.dart';

class FakeEngine implements SpeechEngine {
  final spoken = <String>[];
  var stops = 0;
  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async => spoken.add(text);
  @override
  Future<void> stop() async => stops++;
  @override
  Future<List<String>> voices() async => ['Alex', 'Samantha'];
}

SceneDoc _doc() => SceneDoc.fromJson(jsonDecode(jsonEncode({
      'conceptId': '00000000-0000-0000-0000-000000001001',
      'title': 't',
      'kind': 'flow',
      'intro': 'Intro line.',
      'takeaway': 'Remember this.',
      'steps': [
        for (var i = 1; i <= 7; i++)
          {
            'say': 'Step $i says hello.',
            'cards': [
              {'icon': 'star', 'title': 'A', 's': 'active'},
              {'icon': 'star', 'title': 'B', 's': 'todo'},
              {'icon': 'star', 'title': 'C', 's': 'todo'},
            ],
          },
      ],
    })) as Map<String, dynamic>);

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.binding.setSurfaceSize(const Size(430, 2200));
  await t.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: Scaffold(body: SingleChildScrollView(child: w))));
  await t.pump(const Duration(milliseconds: 100));
}

void main() {
  late FakeEngine fake;
  setUp(() {
    fake = FakeEngine();
    BitVoice.instance
      ..engine = fake
      ..enabled = true
      ..available = true
      ..speed = 1.0;
  });

  test('on-screen symbols are turned into speakable words', () {
    expect(BitVoice.speakable('Cost is O(n^2) and name -> s1'), 'Cost is O of n squared and name points to s1');
    expect(BitVoice.speakable('count++ then x != y'), 'count plus plus then x is not equal to y');
    expect(BitVoice.speakable('use `volatile` here'), 'use volatile here');
  });

  testWidgets('Bit speaks the first step, then each step you move to', (t) async {
    await _pump(t, SceneView(doc: _doc()));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.spoken, ['Step 1 says hello.']);
    await t.tap(find.byIcon(Icons.skip_next_rounded));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.spoken.last, 'Step 2 says hello.');
    await t.tap(find.byIcon(Icons.skip_previous_rounded));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.spoken.last, 'Step 1 says hello.');
  });

  testWidgets('the last step also speaks the takeaway', (t) async {
    await _pump(t, SceneView(doc: _doc()));
    for (var i = 0; i < 6; i++) {
      await t.tap(find.byIcon(Icons.skip_next_rounded));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(fake.spoken.last, 'Step 7 says hello. Remember this.');
  });

  testWidgets('a muted Bit says nothing', (t) async {
    BitVoice.instance.enabled = false;
    await _pump(t, SceneView(doc: _doc()));
    await t.tap(find.byIcon(Icons.skip_next_rounded));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.spoken, isEmpty);
  });

  testWidgets('the speaker button mutes and unmutes', (t) async {
    await _pump(t, SceneView(doc: _doc()));
    await t.tap(find.byIcon(Icons.volume_up_rounded));
    await t.pump();
    expect(BitVoice.instance.enabled, isFalse);
    await t.tap(find.byIcon(Icons.volume_off_rounded));
    await t.pump();
    expect(BitVoice.instance.enabled, isTrue);
  });

  testWidgets('autoplay waits for the narration, then advances', (t) async {
    await t.runAsync(() async {});
    await _pump(t, SceneView(doc: _doc()));
    await t.tap(find.byIcon(Icons.play_arrow_rounded));
    // let a couple of read-time delays pass
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(fake.spoken.length, greaterThanOrEqualTo(2));
    expect(fake.spoken.first, 'Step 1 says hello.');
    expect(fake.spoken, contains('Step 2 says hello.'));
    expect(fake.spoken.indexOf('Step 2 says hello.'), greaterThan(0));
    await t.tap(find.byIcon(Icons.pause_rounded));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(seconds: 1)); // let the cancelled loop's pending delay expire
    }
  });

  testWidgets('an engine that throws marks the voice unavailable instead of crashing', (t) async {
    BitVoice.instance.engine = _Broken();
    await _pump(t, SceneView(doc: _doc()));
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
    expect(BitVoice.instance.available, isFalse);
  });
}

class _Broken implements SpeechEngine {
  @override
  Future<void> speak(String text, {required double rate, required double pitch, String? voice}) async => throw Exception('no tts');
  @override
  Future<void> stop() async {}
  @override
  Future<List<String>> voices() async => throw Exception('no tts');
}
