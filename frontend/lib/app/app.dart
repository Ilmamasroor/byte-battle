import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import '../core/widgets/brand/ambient_background.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';
import 'theme/app_theme.dart';

/// App-wide navigator key. Lets code outside the widget tree (namely the
/// global crash-safety net in `main.dart`) navigate — e.g. dropping the
/// learner back on the dashboard — even when it has no [BuildContext] of
/// its own, such as from `FlutterError.onError` or a zone error handler.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Screens where the ambient canvas glows at full strength: the brand and the "big moments". Everything else
/// (learning, code, results, dashboard) gets a quieter canvas so text and code stay easy to read.
const Set<String> _immersiveRoutes = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
  RouteNames.otpVerification,
  RouteNames.forgotPassword,
  RouteNames.bossBattleIntro,
  RouteNames.bossBattleResult,
};

/// The name of the route currently on top, so the app-wide background can follow it.
final ValueNotifier<String?> _currentRoute = ValueNotifier<String?>(RouteNames.splash);

class _RouteTracker extends NavigatorObserver {
  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    // Observers can fire mid-frame; defer so listeners never rebuild during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _currentRoute.value = name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _set(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(previousRoute);
}

class BytlBattleApp extends StatelessWidget {
  const BytlBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [_RouteTracker()],
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
      // One canvas behind every route (all Scaffolds are transparent). Immersive routes glow more;
      // the rest stay quiet. See [_immersiveRoutes].
      builder: (context, child) {
        return ValueListenableBuilder<String?>(
          valueListenable: _currentRoute,
          builder: (context, route, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: AmbientBackground(intensity: _immersiveRoutes.contains(route) ? 1.0 : 0.55),
                ),
                if (child != null) child,
              ],
            );
          },
        );
      },
    );
  }
}
