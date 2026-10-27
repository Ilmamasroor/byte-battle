import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import 'key_term_text.dart';

class StoryCardData {
  final String eyebrow;
  final String text;
  final IconData icon;
  final Color color;
  const StoryCardData({required this.eyebrow, required this.text, required this.icon, required this.color});
}

/// Turns a paragraph of AI text into swipeable "story" cards (tap right / left side, or swipe). Segmented progress
/// on top like a story reel, one idea per card, key terms highlighted. Far easier to read than a wall of text, and
/// it paces the learner through the explanation instead of dumping it.
class StoryDeck extends StatefulWidget {
  final List<StoryCardData> cards;
  final VoidCallback? onFinished;
  final double height;

  const StoryDeck({super.key, required this.cards, this.onFinished, this.height = 250});

  /// Splits [text] into sentences and groups them into at most [maxCards] cards with fitting labels.
  static List<StoryCardData> fromText(String text, {List<(String, IconData, Color)>? styles, int maxCards = 4}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return const [];
    final sentences = clean.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().isNotEmpty).toList();
    final look = styles ??
        const [
          ('THE BIG IDEA', Icons.lightbulb_rounded, AppColors.xp),
          ('WHY IT HAPPENS', Icons.psychology_rounded, AppColors.accentCyan),
          ('IN REAL LIFE', Icons.public_rounded, AppColors.primary),
          ('REMEMBER THIS', Icons.bookmark_rounded, AppColors.orchid),
        ];
    final n = sentences.length.clamp(1, maxCards);
    final per = (sentences.length / n).ceil();
    final cards = <StoryCardData>[];
    for (var i = 0; i < n; i++) {
      final chunk = sentences.skip(i * per).take(per).join(' ');
      if (chunk.isEmpty) continue;
      final s = look[i.clamp(0, look.length - 1)];
      cards.add(StoryCardData(eyebrow: s.$1, text: chunk, icon: s.$2, color: s.$3));
    }
    return cards;
  }

  @override
  State<StoryDeck> createState() => _StoryDeckState();
}

class _StoryDeckState extends State<StoryDeck> {
  int _i = 0;
  int _dir = 1;

  void _go(int d) {
    final next = _i + d;
    if (next < 0) return;
    if (next >= widget.cards.length) {
      widget.onFinished?.call();
      return;
    }
    setState(() {
      _dir = d;
      _i = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final c = widget.cards[_i];
    return Column(
      children: [
        Row(
          children: [
            for (var k = 0; k < widget.cards.length; k++) ...[
              if (k > 0) const SizedBox(width: 5),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    color: k <= _i ? widget.cards[k].color : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _go(d.localPosition.dx < context.size!.width * 0.3 ? -1 : 1),
          onHorizontalDragEnd: (d) => _go((d.primaryVelocity ?? 0) < 0 ? 1 : -1),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: Offset(0.12 * _dir, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(_i),
              width: double.infinity,
              constraints: BoxConstraints(minHeight: widget.height),
              padding: const EdgeInsets.all(AppDimensions.spacingLg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.color.withOpacity(0.18), AppColors.surface],
                ),
                border: Border.all(color: c.color.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(11)),
                      child: Icon(c.icon, size: 19, color: AppColors.onAccent),
                    ),
                    const SizedBox(width: 10),
                    Text(c.eyebrow, style: AppTextStyles.eyebrow.copyWith(color: c.color)),
                    const Spacer(),
                    Text('${_i + 1}/${widget.cards.length}', style: AppTextStyles.caption),
                  ]),
                  const SizedBox(height: 16),
                  KeyTermText(
                    text: c.text,
                    highlight: c.color,
                    style: AppTextStyles.display.copyWith(fontSize: 21, height: 1.35, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: _i == 0 ? 0.3 : 1,
              child: TextButton.icon(
                onPressed: _i == 0 ? null : () => _go(-1),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back'),
              ),
            ),
            Text('tap or swipe', style: AppTextStyles.caption),
            TextButton.icon(
              onPressed: () => _go(1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(_i == widget.cards.length - 1 ? 'Got it' : 'Next'),
            ),
          ],
        ),
      ],
    );
  }
}
