import 'package:flutter/material.dart';
import 'constants/app_constants.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';
import 'theme/app_theme.dart';

/// App-wide navigator key. Lets code outside the widget tree (namely the
/// global crash-safety net in `main.dart`) navigate — e.g. dropping the
/// learner back on the dashboard — even when it has no [BuildContext] of
/// its own, such as from `FlutterError.onError` or a zone error handler.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BytlBattleApp extends StatelessWidget {
  const BytlBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
      // Paints AppConstants.appBackground once, full-bleed, behind every
      // single route in the app. Every Scaffold is transparent
      // (see AppTheme.darkTheme + each screen's Scaffold/AppBar), so this
      // one image is the background everywhere instead of a flat color.
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                AppConstants.appBackground,
                fit: BoxFit.cover,
              ),
            ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}
