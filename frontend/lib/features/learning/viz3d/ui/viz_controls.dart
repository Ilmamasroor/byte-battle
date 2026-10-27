import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../engine/playback_controller.dart';

/// Play, pause, restart, previous, next, speed and the scrubber. One widget for every visualization, driven by the
/// shared [VizPlaybackController], so the controls look and behave the same in every lesson.
class VizControls extends StatelessWidget {
  final VizPlaybackController controller;

  /// Positions the scrubber marks (where the bug happens, where the answer is found).
  final Set<int> markers;

  /// Shown instead of the raw position, e.g. "step 3 of 7". When null the position and length are shown.
  final String Function(int position, int length)? counter;

  const VizControls({super.key, required this.controller, this.markers = const {}, this.counter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final c = controller;
        final last = c.length - 1;
        final sp = c.speed;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.border)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: c.reset, icon: const Icon(Icons.restart_alt_rounded), tooltip: 'Restart'),
                  IconButton(onPressed: c.atStart ? null : c.previous, icon: const Icon(Icons.skip_previous_rounded, size: 28), tooltip: 'Step back'),
                  Semantics(
                    button: true,
                    label: c.playing ? 'Pause' : 'Play',
                    child: GestureDetector(
                      onTap: last < 1 ? null : c.toggle,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                        child: Icon(c.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.onAccent, size: 34),
                      ),
                    ),
                  ),
                  IconButton(onPressed: c.atEnd ? null : c.next, icon: const Icon(Icons.skip_next_rounded, size: 28), tooltip: 'Step forward'),
                  TextButton(onPressed: c.cycleSpeed, child: Text('${sp == sp.roundToDouble() ? sp.toInt() : sp}x', style: AppTextStyles.bodyBold)),
                ],
              ),
              Row(
                children: [
                  Text('${c.position}', style: AppTextStyles.caption),
                  Expanded(
                    child: Stack(alignment: Alignment.center, children: [
                      if (markers.isNotEmpty && last > 0)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: LayoutBuilder(
                                builder: (context, box) => Stack(children: [
                                      for (final m in markers)
                                        Positioned(
                                            left: box.maxWidth * (m / last) - 3,
                                            top: 2,
                                            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle))),
                                    ])),
                          ),
                        ),
                      Slider(
                        value: c.position.toDouble().clamp(0, last.toDouble()),
                        min: 0,
                        max: last < 1 ? 1 : last.toDouble(),
                        divisions: last < 1 ? null : last,
                        label: counter?.call(c.position, c.length),
                        onChanged: last < 1 ? null : (v) => c.seek(v.round()),
                      ),
                    ]),
                  ),
                  Text('$last', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
