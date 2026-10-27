import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/router/route_names.dart';

/// Remembers (on this device) which concepts the learner has already done the readiness check for, so it shows
/// once per concept, and sends the learner through it before their first lesson.
class ReadinessStore {
  ReadinessStore._();

  static String _key(String conceptId) => 'readiness_done_$conceptId';

  static Future<bool> isDone(String conceptId) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key(conceptId)) ?? false;
    } catch (_) {
      return true; // never block learning because storage failed
    }
  }

  static Future<void> markDone(String conceptId) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key(conceptId), true);
    } catch (_) {}
  }

  /// Opens [nextRoute] for [conceptId], going through the readiness check first when it has not been done yet.
  static Future<void> open(BuildContext context, String conceptId, String nextRoute) async {
    final done = await isDone(conceptId);
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(
      done ? nextRoute : RouteNames.readiness,
      arguments: {'conceptId': conceptId, 'next': nextRoute},
    );
  }
}
