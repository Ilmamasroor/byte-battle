import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../data/models/onboarding_model.dart';

/// The illustrated scene for each story page. They are small live mock-ups of the real features, so the
/// onboarding shows the product instead of describing it.
class OnboardingSceneView extends StatefulWidget {
  final OnboardingScene scene;
  const OnboardingSceneView({super.key, required this.scene});

  @override
  State<OnboardingSceneView> createState() => _OnboardingSceneViewState();
}

class _OnboardingSceneViewState extends State<OnboardingSceneView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 4),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => switch (widget.scene) {
            OnboardingScene.learn => _LearnScene(t: _c.value),
            OnboardingScene.see => _SeeScene(t: _c.value),
            OnboardingScene.battle => _BattleScene(t: _c.value),
            OnboardingScene.own => _OwnScene(t: _c.value),
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _Chip(this.text, this.color, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
        Text(text, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ── 01 Learn: three study cards fanned out, Bit curious on top ──────────────
class _LearnScene extends StatelessWidget {
  final double t;
  const _LearnScene({required this.t});

  @override
  Widget build(BuildContext context) {
    Widget card(String title, String body, Color c, IconData icon, double angle, Offset off) {
      return Transform.translate(
        offset: off + Offset(0, math.sin((t + angle) * math.pi * 2) * 3),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: c),
                  const SizedBox(width: 6),
                  Text(title, style: AppTextStyles.bodyBold.copyWith(color: c, fontSize: 13)),
                ]),
                const SizedBox(height: 6),
                Text(body, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        card('Mnemonic', 'Lock before you touch.', AppColors.orchid, Icons.lightbulb_rounded, 0.1, const Offset(22, 112)),
        card('Analogy', 'Two cooks, one salt shaker.', AppColors.accentCyan, Icons.coffee_rounded, -0.07, const Offset(-20, 36)),
        card('In plain English', 'A race condition is a timing bug.', AppColors.primary, Icons.menu_book_rounded, 0.02,
            const Offset(6, -42)),
        const Positioned(top: 14, right: 22, child: BitMascot(size: 58, mood: BitMood.curious)),
      ],
    );
  }
}

// ── 02 See: two threads racing for one counter, with a playhead ─────────────
class _SeeScene extends StatelessWidget {
  final double t;
  const _SeeScene({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _Chip('Visualizer', AppColors.accentCyan, icon: Icons.play_circle_rounded),
            const Spacer(),
            Text('counter = ${t > 0.62 ? 1 : 0}', style: AppTextStyles.code.copyWith(color: AppColors.xp, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth;
                final playhead = t * w;
                Widget lane(String name, Color color, List<(double, double, String)> blocks) {
                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.eyebrow),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Stack(children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.inputFill,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            for (final b in blocks)
                              Positioned(
                                left: b.$1 * w,
                                width: b.$2 * w,
                                top: 4,
                                bottom: 4,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(playhead > b.$1 * w ? 0.95 : 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(b.$3,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.onAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ),
                          ]),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(children: [
                  Column(children: [
                    lane('THREAD A', AppColors.primary, const [(0.04, 0.2, 'read'), (0.3, 0.2, 'add'), (0.62, 0.22, 'write')]),
                    const SizedBox(height: 10),
                    lane('THREAD B', AppColors.accentCyan, const [(0.12, 0.2, 'read'), (0.38, 0.2, 'add'), (0.66, 0.22, 'write')]),
                  ]),
                  Positioned(
                    left: playhead,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.textPrimary.withOpacity(0.85)),
                  ),
                  if (t > 0.66)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _Chip('lost update!', AppColors.warning, icon: Icons.warning_amber_rounded),
                    ),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 03 Battle: boss HP drops as the right answer is picked ─────────────────
class _BattleScene extends StatelessWidget {
  final double t;
  const _BattleScene({required this.t});

  @override
  Widget build(BuildContext context) {
    final hp = (1 - Curves.easeInOut.transform(((t - 0.45) / 0.3).clamp(0.0, 1.0)) * 0.55);
    final picked = t > 0.4;
    Widget option(String s, bool good) {
      final c = picked ? (good ? AppColors.success : AppColors.border) : AppColors.border;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: picked && good ? AppColors.success.withOpacity(0.12) : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c, width: picked && good ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(picked && good ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16, color: picked && good ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(child: Text(s, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontSize: 12))),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orchid.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pest_control_rounded, color: AppColors.orchid, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('The Deadlock Dragon', style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: hp,
                    minHeight: 7,
                    backgroundColor: AppColors.inputFill,
                    valueColor: const AlwaysStoppedAnimation(AppColors.orchid),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            const Row(children: [
              Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
              Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
              Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.textHint),
            ]),
          ]),
          const SizedBox(height: 14),
          Text('Which keyword prevents two threads\nentering a block at once?',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, height: 1.35)),
          option('volatile', false),
          option('synchronized', true),
          option('transient', false),
        ],
      ),
    );
  }
}

// ── 04 Own: Byte DNA bars filling in, level title and streak ───────────────
class _OwnScene extends StatelessWidget {
  final double t;
  const _OwnScene({required this.t});

  @override
  Widget build(BuildContext context) {
    final grow = Curves.easeOutCubic.transform((t * 2).clamp(0.0, 1.0));
    Widget bar(String name, double v, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(children: [
            SizedBox(width: 104, child: Text(name, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: v * grow,
                  minHeight: 9,
                  backgroundColor: AppColors.inputFill,
                  valueColor: AlwaysStoppedAnimation(c),
                ),
              ),
            ),
          ]),
        );

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const BitMascot(size: 46, mood: BitMood.cheer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Thread Tamer', style: AppTextStyles.display.copyWith(fontSize: 20)),
                Text('Level 4 · 12-day streak', style: AppTextStyles.caption),
              ]),
            ),
            const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 26),
          ]),
          const SizedBox(height: 16),
          Text('YOUR BYTE DNA', style: AppTextStyles.eyebrow),
          const SizedBox(height: 10),
          bar('Understanding', 0.82, AppColors.accentCyan),
          bar('Application', 0.64, AppColors.primary),
          bar('Debugging', 0.45, AppColors.orchid),
          bar('Communication', 0.7, AppColors.xp),
        ],
      ),
    );
  }
}
