import 'package:flutter/foundation.dart';

/// Helpers — utility helpers.
class Helpers {
  Helpers._();

  /// Call this from a screen's `initState` (or the top of `build` for a
  /// `StatelessWidget`) whenever that screen has no real repository/API
  /// call behind it yet and is only rendering static/hardcoded data.
  ///
  /// Prints a single, consistent line to the debug console the moment the
  /// person navigates to that screen, e.g.:
  /// `⚠️ [DashboardScreen] NO API YET — showing static/hardcoded data.`
  ///
  /// Safe to leave in place permanently — `debugPrint` is a no-op in
  /// release builds, so this never ships to real users.
  static void noApiYet(String screenName, {String? note}) {
    debugPrint(
      '⚠️ [$screenName] NO API YET — showing static/hardcoded data.'
      '${note != null ? ' ($note)' : ''}',
    );
  }
}
