import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/router/route_names.dart';

void main() {
  runZonedGuarded(() {
    // A widget that fails to build would otherwise show Flutter's
    // default error screen. Replace that with a small, friendly fallback
    // that auto-recovers instead.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('🛑 [ErrorWidget] widget build error: ${details.exception}');
      return const _CrashSafeFallback();
    };

    // Framework-level errors (layout/paint/gesture/animation callbacks) —
    // log them instead of letting them crash the app.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('🛑 [FlutterError] ${details.exceptionAsString()}');
    };

    // Errors surfaced outside the Flutter framework (e.g. the platform
    // dispatcher) — same treatment: log, don't crash.
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🛑 [PlatformDispatcher] $error');
      return true; // handled — don't let it propagate as fatal.
    };

    runApp(const BytlBattleApp());
  }, (error, stack) {
    // Last line of defense: anything thrown in a Future/async gap that
    // nothing else caught. Never let this take the whole app down.
    debugPrint('🛑 [Uncaught] $error');
  });
}

/// Shown in place of Flutter's default error screen whenever a widget
/// fails to build. Never leaves the learner stuck looking at it — after
/// 10 seconds it automatically navigates back to the dashboard, the same
/// safe fallback destination used everywhere else in the app (see
/// `AppRouter`'s unmatched-route case and the registration failure path).
class _CrashSafeFallback extends StatefulWidget {
  const _CrashSafeFallback();

  @override
  State<_CrashSafeFallback> createState() => _CrashSafeFallbackState();
}

class _CrashSafeFallbackState extends State<_CrashSafeFallback> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 10), () {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteNames.dashboard,
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'Something went wrong. Taking you back to the dashboard...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
