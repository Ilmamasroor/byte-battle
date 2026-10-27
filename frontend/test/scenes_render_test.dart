import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:byte_battle/app/theme/app_theme.dart';
import 'package:byte_battle/features/learning/scenes/scene_models.dart';
import 'package:byte_battle/features/learning/scenes/scene_view.dart';

/// Every bundled scene must parse and play end to end at phone width without a layout overflow or exception.
void main() {
  final dir = Directory('assets/scenes');
  final files = dir.existsSync() ? (dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()..sort((a, b) => a.path.compareTo(b.path))) : <File>[];

  test('scene assets exist', () => expect(files, isNotEmpty));

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    testWidgets('scene plays cleanly: $name', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final doc = SceneDoc.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      expect(name, '${doc.conceptId}.json');
      await tester.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: SceneView(doc: doc)))));
      await tester.pump(const Duration(milliseconds: 100));
      // answer the prediction, if any
      if (doc.predict != null) {
        await tester.ensureVisible(find.textContaining('Skip, just show me'));
        await tester.tap(find.textContaining('Skip, just show me'));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull, reason: 'first frame');
      expect(find.text('1'), findsWidgets); // step counter visible: the player is on screen
      for (var i = 1; i < doc.steps.length; i++) {
        await tester.ensureVisible(find.byIcon(Icons.skip_next_rounded));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.skip_next_rounded));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: 'step ${i + 1}');
      }
    });
  }
}
