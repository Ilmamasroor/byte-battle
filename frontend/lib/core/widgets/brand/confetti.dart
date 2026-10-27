import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// One-shot confetti burst. Drop it in a Stack over the content and change [trigger] (e.g. increment an int) to
/// fire it. Ignores pointer events, so it never blocks taps.
class ConfettiBurst extends StatefulWidget {
  final int trigger;
  const ConfettiBurst({super.key, required this.trigger});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late List<_P> _ps = _make();

  static const _colors = [AppColors.primary, AppColors.accentCyan, AppColors.orchid, AppColors.xp, AppColors.success];

  List<_P> _make() {
    final r = math.Random();
    return List.generate(
      46,
      (_) => _P(
        angle: -math.pi / 2 + (r.nextDouble() - 0.5) * 2.2,
        speed: 260 + r.nextDouble() * 380,
        spin: (r.nextDouble() - 0.5) * 12,
        size: 6 + r.nextDouble() * 7,
        color: _colors[r.nextInt(_colors.length)],
      ),
    );
  }

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      _ps = _make();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isAnimating || _c.value > 0 && _c.value < 1
            ? CustomPaint(painter: _ConfettiPainter(_ps, _c.value), size: Size.infinite)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _P {
  final double angle, speed, spin, size;
  final Color color;
  _P({required this.angle, required this.speed, required this.spin, required this.size, required this.color});
}

class _ConfettiPainter extends CustomPainter {
  final List<_P> ps;
  final double t;
  _ConfettiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.62);
    for (final p in ps) {
      final dx = math.cos(p.angle) * p.speed * t;
      final dy = math.sin(p.angle) * p.speed * t + 520 * t * t; // gravity
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55), const Radius.circular(2)),
        Paint()..color = p.color.withOpacity((1 - t).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Fires one [ConfettiBurst] shortly after it first appears. Drop it in a Stack on "you did it" screens.
class AutoConfetti extends StatefulWidget {
  final bool enabled;
  const AutoConfetti({super.key, this.enabled = true});

  @override
  State<AutoConfetti> createState() => _AutoConfettiState();
}

class _AutoConfettiState extends State<AutoConfetti> {
  int _n = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _n++);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ConfettiBurst(trigger: _n);
}
