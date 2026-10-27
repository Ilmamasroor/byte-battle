import 'package:flutter/material.dart';
import '../../../onboarding/data/onboarding_gate.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/brand/byte_mark.dart';
import '../../../auth/presentation/state/auth_controller.dart';

/// Splash: the mark pops in, the wordmark rises, then the four verbs of the product light up one by one
/// (Learn, See, Battle, Code), which is the whole story of the app in two seconds.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Duration _minDisplayDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
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
    final next = status == AuthStatus.authenticated
        ? await OnboardingGate.nextRoute()
        : RouteNames.onboarding;
    if (!mounted) return;
    // Clear the stack (including the web '/' placeholder) so back never returns to the splash.
    Navigator.of(context).pushNamedAndRemoveUntil(next, (route) => false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
            final pop = Curves.elasticOut.transform(seg(0.0, 0.5));
            final word = Curves.easeOutCubic.transform(seg(0.3, 0.6));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: Opacity(opacity: seg(0.0, 0.2), child: const ByteMark(size: 112)),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: word,
                  child: Transform.translate(offset: Offset(0, 14 * (1 - word)), child: const Wordmark(fontSize: 34)),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _verbs.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      _Verb(label: _verbs[i], lit: seg(0.55 + i * 0.1, 0.65 + i * 0.1)),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const _verbs = ['Learn', 'See', 'Battle', 'Code'];
}

class _Verb extends StatelessWidget {
  final String label;
  final double lit;
  const _Verb({required this.label, required this.lit});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25 + 0.75 * lit,
      child: Text(
        label,
        style: AppTextStyles.eyebrow.copyWith(
          fontSize: 12,
          color: Color.lerp(AppColors.textHint, AppColors.primaryLight, lit),
        ),
      ),
    );
  }
}
