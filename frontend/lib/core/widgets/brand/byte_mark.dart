import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// The Byte Battle mark: a flame-gradient tile holding a "B" built from pixel blocks (a byte of bits), with the
/// one missing corner bit floating free in aqua. That floating bit is also the mascot, [BitMascot], so the logo
/// and the character are the same story: every concept you learn adds a bit back.
///
/// Drawn in code: crisp at any size, no image asset, and the same geometry is used to generate the web icons.
class ByteMark extends StatelessWidget {
  final double size;
  final bool glow;

  const ByteMark({super.key, this.size = 48, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: ByteMarkPainter(glow: glow)),
    );
  }
}

class ByteMarkPainter extends CustomPainter {
  final bool glow;
  const ByteMarkPainter({this.glow = true});

  // 5 x 7 pixel "B". '#' = block, 'o' = the floating bit, '.' = empty.
  static const _glyph = [
    '####o',
    '#...#',
    '#...#',
    '####.',
    '#...#',
    '#...#',
    '####.',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final tile = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.3),
    );

    if (glow) {
      canvas.drawRRect(
        tile.shift(Offset(0, s * 0.05)),
        Paint()
          ..color = AppColors.primary.withOpacity(0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.14),
      );
    }

    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFB05C), AppColors.primary, Color(0xFFF0501F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    // soft top highlight
    canvas.save();
    canvas.clipRRect(tile);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s, s * 0.5),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, s, s * 0.5)),
    );
    canvas.restore();

    const cols = 5, rows = 7;
    final cell = s * 0.108;
    final gap = s * 0.026;
    final gw = cols * cell + (cols - 1) * gap;
    final gh = rows * cell + (rows - 1) * gap;
    final ox = (s - gw) / 2;
    final oy = (s - gh) / 2;

    final ink = Paint()..color = AppColors.onAccent;
    final bit = Paint()..color = AppColors.white;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ch = _glyph[r][c];
        if (ch == '.') continue;
        final rect = Rect.fromLTWH(ox + c * (cell + gap), oy + r * (cell + gap), cell, cell);
        if (ch == 'o') {
          // the floating bit: lifted up and out, aqua with a light ring
          final lifted = rect.shift(Offset(cell * 0.35, -cell * 0.35)).inflate(cell * 0.06);
          canvas.drawRRect(RRect.fromRectAndRadius(lifted.inflate(cell * 0.14), Radius.circular(cell * 0.3)), bit);
          canvas.drawRRect(
            RRect.fromRectAndRadius(lifted, Radius.circular(cell * 0.24)),
            Paint()..color = AppColors.accentCyan,
          );
        } else {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.26)), ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ByteMarkPainter old) => old.glow != glow;
}
