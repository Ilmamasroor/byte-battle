import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// App-wide canvas: ink gradient, a faint dot grid (graph paper, for the "build it" feeling) and two soft glows,
/// Flame top-left and Aqua bottom-right. `intensity` lets hero screens (splash, auth, boss battle) glow more
/// than reading/coding screens, where the canvas must stay quiet.
class AmbientBackground extends StatelessWidget {
  final double intensity;
  const AmbientBackground({super.key, this.intensity = 0.6});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: intensity),
        duration: const Duration(milliseconds: 400),
        builder: (context, v, _) => CustomPaint(
          painter: _AmbientPainter(v),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double intensity;
  _AmbientPainter(this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundSecondary, AppColors.background],
        ).createShader(rect),
    );

    void glow(Offset c, double r, Color color, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withOpacity(a), color.withOpacity(0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    final longest = size.longestSide;
    glow(Offset(size.width * 0.05, size.height * 0.02), longest * 0.55, AppColors.primary, 0.20 * intensity);
    glow(Offset(size.width * 0.98, size.height * 0.95), longest * 0.5, AppColors.accentCyan, 0.13 * intensity);
    glow(Offset(size.width * 0.95, size.height * 0.30), longest * 0.3, AppColors.orchid, 0.08 * intensity);

    // dot grid
    const step = 26.0;
    final pts = <Offset>[];
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        pts.add(Offset(x, y));
      }
    }
    canvas.drawPoints(
      PointMode.points,
      pts,
      Paint()
        ..color = Colors.white.withOpacity(0.05 + 0.03 * intensity)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.intensity != intensity;
}
