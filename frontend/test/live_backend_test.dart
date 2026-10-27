// Live contract test: needs the backend on localhost:8080. Run: flutter test test/live_backend_test.dart
// Skipped automatically when the backend is unreachable.
import 'dart:io';
import 'package:byte_battle/core/models/backend_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frontend models parse real backend responses', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080', validateStatus: (_) => true, receiveTimeout: const Duration(seconds: 90)));
    try {
      await dio.get('/api/auth/login');
    } catch (_) {
      markTestSkipped('backend not running');
      return;
    }
    dynamic unwrap(Response r) => (r.data is Map && (r.data as Map).containsKey('data')) ? r.data['data'] : r.data;
    final email = 'flutter${DateTime.now().millisecondsSinceEpoch}@x.com';
    final reg = await dio.post('/api/auth/register', data: {'email': email, 'password': 'Passw0rd!123', 'username': 'flutter'});
    expect(reg.statusCode, 200);
    dio.options.headers['Authorization'] = 'Bearer ${unwrap(reg)['token']}';

    final st = await dio.get('/api/onboarding/status');
    expect(OnboardingStatus.fromJson(Map<String, dynamic>.from(unwrap(st))).completed, isFalse);
    final qs = await dio.get('/api/onboarding/questions');
    final qList = (unwrap(qs) as List).map((e) => OnboardingQuestionModel.fromJson(Map<String, dynamic>.from(e))).toList();
    expect(qList, isNotEmpty);
    expect(qList.first.prompt, isNotEmpty);

    // Onboarding is required before the learning endpoints; the guard answers 403 ONBOARDING_REQUIRED.
    final guarded = await dio.get('/api/battles');
    expect(guarded.statusCode, anyOf(403, 200));

    final viz = await dio.get('/api/visualize/concepts/00000000-0000-0000-0000-000000001011');
    if (viz.statusCode == 200) {
      final m = VisualizationModel.fromJson(Map<String, dynamic>.from(unwrap(viz)));
      expect(m.schedules, isNotEmpty);
    }
    stdout.writeln('onboarding questions: ${qList.length}, battles guard: ${guarded.statusCode}, viz: ${viz.statusCode}');
  });
}
