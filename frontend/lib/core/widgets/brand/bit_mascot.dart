import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

enum BitMood { happy, cheer, curious, sleepy }

/// Bit: the floating aqua bit from the logo, brought to life. A small, friendly companion that reacts to how the
/// learner is doing (cheering a streak, curious about a new concept, sleepy at night). Bobs and blinks on its own.
class BitMascot extends StatefulWidget {
  final double size;
  final BitMood mood;
  const BitMascot({super.key, this.size = 72, this.mood = BitMood.happy});

  @override
  State<BitMascot> createState() => _BitMascotState();
}

class _BitMascotState extends State<BitMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.1,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _BitPainter(_c.value, widget.mood)),
      ),
    );
  }
}

class _BitPainter extends CustomPainter {
  final double t; // 0..1 loop
  final BitMood mood;
  _BitPainter(this.t, this.mood);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bob = math.sin(t * math.pi * 2) * s * 0.035 * (mood == BitMood.cheer ? 2.2 : 1);
    final top = s * 0.18 + bob;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.1, top, s * 0.8, s * 0.7),
      Radius.circular(s * 0.24),
    );

    // ground shadow (shrinks as Bit rises)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s / 2, s * 1.04), width: s * (0.5 - bob / s), height: s * 0.07),
      Paint()..color = Colors.black.withOpacity(0.28),
    );

    // antenna
    final aTop = Offset(s / 2 + math.sin(t * math.pi * 4) * s * 0.02, top - s * 0.15);
    canvas.drawLine(Offset(s / 2, top + s * 0.02), aTop, Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(aTop, s * 0.06, Paint()..color = AppColors.xp);

    // body
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8BE3F7), AppColors.accentCyan, Color(0xFF3FA9E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(body.outerRect),
    );
    // belly screen
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.2, top + s * 0.1, s * 0.6, s * 0.46),
      Radius.circular(s * 0.16),
    );
    canvas.drawRRect(face, Paint()..color = AppColors.background);

    // eyes (blink near t ~ 0.9)
    final blink = t > 0.9 && t < 0.95;
    final eyeY = top + s * 0.27;
    final ink = Paint()..color = AppColors.accentCyan;
    void eye(double cx) {
      if (blink || mood == BitMood.sleepy) {
        canvas.drawLine(Offset(cx - s * 0.05, eyeY), Offset(cx + s * 0.05, eyeY), ink
          ..strokeWidth = s * 0.035
          ..strokeCap = StrokeCap.round);
      } else if (mood == BitMood.cheer) {
        final p = Path()
          ..moveTo(cx - s * 0.055, eyeY + s * 0.025)
          ..quadraticBezierTo(cx, eyeY - s * 0.07, cx + s * 0.055, eyeY + s * 0.025);
        canvas.drawPath(p, Paint()
          ..color = AppColors.accentCyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04
          ..strokeCap = StrokeCap.round);
      } else {
        final r = mood == BitMood.curious ? s * 0.062 : s * 0.05;
        canvas.drawCircle(Offset(cx, eyeY), r, ink);
        canvas.drawCircle(Offset(cx + r * 0.3, eyeY - r * 0.3), r * 0.3, Paint()..color = Colors.white);
      }
    }

    eye(s * 0.38);
    eye(s * 0.62);

    // mouth
    final my = top + s * 0.42;
    final mouth = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round;
    if (mood == BitMood.cheer) {
      canvas.drawArc(Rect.fromCenter(center: Offset(s / 2, my - s * 0.02), width: s * 0.2, height: s * 0.16), 0, math.pi,
          true, Paint()..color = AppColors.primary);
    } else if (mood == BitMood.curious) {
      canvas.drawCircle(Offset(s / 2, my), s * 0.03, mouth);
    } else if (mood == BitMood.sleepy) {
      canvas.drawLine(Offset(s * 0.45, my), Offset(s * 0.55, my), mouth);
    } else {
      canvas.drawArc(Rect.fromCenter(center: Offset(s / 2, my - s * 0.03), width: s * 0.17, height: s * 0.12), 0.2,
          math.pi - 0.4, false, mouth);
    }

    // feet
    final foot = Paint()..color = const Color(0xFF3FA9E8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.28, top + s * 0.68, s * 0.14, s * 0.1), Radius.circular(s * 0.04)), foot);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.58, top + s * 0.68, s * 0.14, s * 0.1), Radius.circular(s * 0.04)), foot);
  }

  @override
  bool shouldRepaint(_BitPainter old) => old.t != t || old.mood != mood;
}
