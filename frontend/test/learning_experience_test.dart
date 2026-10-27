import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:byte_battle/core/widgets/ai/analogy_scene.dart';
import 'package:byte_battle/core/widgets/ai/story_deck.dart';
import 'package:byte_battle/features/learning/visualization/widgets/scheduler_game.dart';
import 'package:byte_battle/features/readiness/data/readiness_bank.dart';
import 'package:byte_battle/core/personalization/lens.dart';
import 'package:byte_battle/core/widgets/ai/lens_picker.dart';
import 'package:byte_battle/core/widgets/ai/memory_poster.dart';

Map<String, dynamic> _step(int i, String t, int op, String kind, String text, {int? value, int? local}) => {
      'index': i,
      'thread': t,
      'opIndex': op,
      'kind': kind,
      'target': kind == 'SLEEP' ? '1 ms' : 'count',
      'line': 7,
      'text': text,
      'hazard': false,
      if (value != null) 'value': value,
      if (local != null) 'local': local,
    };

VizSchedule _race() => VizSchedule.fromJson({
      'kind': 'RACE',
      'threads': ['Thread-1-1', 'Thread-2-2'],
      'expected': {'count': 2},
      'finalValues': {'count': 1},
      'steps': [
        _step(0, 'Thread-1-1', 0, 'READ', 'read count', value: 0, local: 0),
        _step(1, 'Thread-2-2', 0, 'READ', 'read count', value: 0, local: 0),
        _step(2, 'Thread-1-1', 1, 'SLEEP', 'Thread.sleep(1)'),
        _step(3, 'Thread-1-1', 2, 'WRITE', 'count = current + 1', value: 1),
        _step(4, 'Thread-2-2', 1, 'SLEEP', 'Thread.sleep(1)'),
        _step(5, 'Thread-2-2', 2, 'WRITE', 'count = current + 1', value: 1),
      ],
    });

Future<void> _pump(WidgetTester t, Widget w) async {
  await t.binding.setSurfaceSize(const Size(430, 2200));
  await t.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: Scaffold(body: SingleChildScrollView(child: w))));
  await t.pump(const Duration(milliseconds: 100));
}

Future<void> _run(WidgetTester t, String thread) async {
  await t.tap(find.textContaining('Run next line of $thread').first);
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  test('scheduler game supports a read-sleep-write schedule', () {
    expect(SchedulerGame.supports(_race()), isTrue);
  });

  testWidgets('interleaving both reads before the writes loses an update', (t) async {
    await _pump(t, SchedulerGame(schedule: _race()));
    for (final th in ['Thread 1', 'Thread 2', 'Thread 1', 'Thread 1', 'Thread 2', 'Thread 2']) {
      await _run(t, th);
    }
    expect(find.textContaining('Race found'), findsOneWidget);
    expect(find.textContaining('Races caused: 1'), findsOneWidget);
  });

  testWidgets('running one thread to completion at a time stays correct', (t) async {
    await _pump(t, SchedulerGame(schedule: _race()));
    for (final th in ['Thread 1', 'Thread 1', 'Thread 1', 'Thread 2', 'Thread 2', 'Thread 2']) {
      await _run(t, th);
    }
    expect(find.textContaining('No race this time'), findsOneWidget);
    expect(find.textContaining('Races caused: 0'), findsOneWidget);
  });

  test('every readiness bank has answerable questions and primers', () {
    for (final name in ['Race Conditions', 'Polymorphism', 'Java Fundamentals', null, 'Joins', 'CPU Scheduling', 'TCP vs UDP', 'Caching', 'BFS and DFS', 'Two Pointers', 'STAR Method', 'Sorting Algorithms']) {
      final items = ReadinessBank.forConcept(name);
      expect(items.length, greaterThanOrEqualTo(3));
      for (final p in items) {
        expect(p.answer, inInclusiveRange(0, p.options.length - 1), reason: p.id);
        expect(p.primer, isNotEmpty);
        expect(p.example, isNotEmpty);
      }
    }
    expect(ReadinessBank.forConcept('Deadlocks').any((p) => p.id == 'thread'), isTrue);
    expect(ReadinessBank.forConcept('Polymorphism').any((p) => p.id == 'inherit'), isTrue);
    expect(ReadinessBank.forConcept('Joins').any((p) => p.id == 'tables'), isTrue);
    expect(ReadinessBank.forConcept('Processes vs Threads').any((p) => p.id == 'process'), isTrue);
    expect(ReadinessBank.forConcept('Classic Synchronization Problems').any((p) => p.id == 'memory'), isTrue);
    expect(ReadinessBank.forConcept('Deadlocks').any((p) => p.id == 'thread'), isTrue);
    expect(ReadinessBank.forConcept('Load Balancing').any((p) => p.id == 'database'), isTrue);
    expect(ReadinessBank.forConcept('BFS and DFS').any((p) => p.id == 'recursion'), isTrue);
  });

  test('story deck splits a paragraph into labelled cards', () {
    final cards = StoryDeck.fromText('One idea. Two reasons! Is it three? Yes, four. Five.');
    expect(cards.length, inInclusiveRange(2, 4));
    expect(cards.first.eyebrow, 'THE BIG IDEA');
    expect(StoryDeck.fromText('   '), isEmpty);
  });

  test('analogy connection becomes real-world to code pairs', () {
    final pairs = AnalogyScene.parseMapping(
        'The scoreboard is the shared resource; the unsynchronized writes are the data race; the umpire is the lock.');
    expect(pairs.length, 3);
    expect(pairs.first.$1.toLowerCase(), 'scoreboard');
    expect(pairs.first.$2, 'shared resource');
  });

  testWidgets('every lens renders the analogy scene without overflow', (t) async {
    const analogy = 'In a cricket match, two scorers update one scoreboard at the same time. Each adds runs without checking the other. So one entry overwrites the other and the total is wrong.';
    const connection = 'The scoreboard is the shared resource; the scorers are the threads; the umpire is the lock.';
    for (final lens in [null, ...Lens.all]) {
      await _pump(t, AnalogyScene(analogy: analogy, connection: connection, memoryTip: 'Only one pen at a time.', lens: lens));
      expect(t.takeException(), isNull, reason: 'lens ${lens?.id}');
      if (lens != null) expect(find.text(lens.mapTitle), findsOneWidget);
    }
    await _pump(t, AnalogyScene(analogy: analogy, connection: connection, memoryTip: 'tip', lens: Lens.byId('movies')));
    expect(find.textContaining('SCENE 1'), findsOneWidget);
  });

  testWidgets('lens picker reports the chosen lens', (t) async {
    String? picked = 'unset';
    await _pump(t, LensPicker(onChanged: (id) => picked = id));
    await t.ensureVisible(find.text('Gaming'));
    await t.pump();
    await t.tap(find.text('Gaming'));
    await t.pump();
    expect(picked, 'gaming');
  });

  testWidgets('memory poster takes its title from the lens', (t) async {
    await _pump(t, MemoryPoster(mnemonic: 'Locks keep threads in line', memoryTip: 'tip', lens: Lens.byId('music')));
    expect(find.text('THE HOOK'), findsOneWidget);
  });
}
