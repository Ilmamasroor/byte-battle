import 'package:flutter/material.dart';
import '../../../../app/constants/app_constants.dart';
import '../../../../app/router/route_names.dart';
import '../../../auth/presentation/state/auth_controller.dart';

/// Splash screen — shows nothing but the [AppConstants.splashArtwork]
/// image, full-bleed, with a simple fade-in. No icon mark, no separate
/// wordmark/tagline text: the artwork already contains all of that.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  static const Duration _minDisplayDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrapAndNavigate();
  }

  /// Checks for a locally-cached session (see [AuthController.bootstrap])
  /// and, once the splash animation has had time to show, sends the user
  /// straight to the dashboard if they're already logged in, or to
  /// onboarding otherwise.
  Future<void> _bootstrapAndNavigate() async {
    // Both run concurrently: the auth check reads local secure storage
    // only (no network call), so it resolves almost instantly, but we
    // still wait out the full splash duration for a consistent animation.
    final bootstrapFuture = AuthController.instance.bootstrap();
    final minDelayFuture = Future<void>.delayed(_minDisplayDuration);

    final status = await bootstrapFuture;
    await minDelayFuture;

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      status == AuthStatus.authenticated ? RouteNames.dashboard : RouteNames.onboarding,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            AppConstants.splashArtwork,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
