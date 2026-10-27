import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../personalization/lens.dart';

/// The mnemonic as a poster: each word is a coloured tile with its first letter picked out. "Test yourself" hides
/// everything but the first letters and lets the learner tap each word to recall it (active recall beats re-reading).
class MemoryPoster extends StatefulWidget {
  final String mnemonic;
  final String memoryTip;
  final Lens? lens;
  const MemoryPoster({super.key, required this.mnemonic, required this.memoryTip, this.lens});

  @override
  State<MemoryPoster> createState() => _MemoryPosterState();
}

class _MemoryPosterState extends State<MemoryPoster> {
  bool _test = false;
  final Set<int> _revealed = {};
  bool _tip = false;

  static const _tints = [AppColors.primary, AppColors.accentCyan, AppColors.orchid, AppColors.xp, AppColors.success];

  @override
  Widget build(BuildContext context) {
    final words = widget.mnemonic.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final allRevealed = _test && _revealed.length == words.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: AppColors.primary.withOpacity(0.55)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 6),
                Text(_test ? 'CAN YOU RECALL IT?' : (widget.lens?.tipTitle ?? 'SAY IT OUT LOUD'), style: AppTextStyles.eyebrow.copyWith(color: AppColors.primary)),
              ]),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < words.length; i++)
                    _WordTile(
                      word: words[i],
                      color: _tints[i % _tints.length],
                      hidden: _test && !_revealed.contains(i),
                      onTap: _test ? () => setState(() => _revealed.add(i)) : null,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _test = !_test;
                      _revealed.clear();
                    }),
                    icon: Icon(_test ? Icons.visibility_rounded : Icons.psychology_alt_rounded, size: 18),
                    label: Text(_test ? 'Show it again' : 'Test yourself'),
                  ),
                ),
              ]),
              if (allRevealed)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Nailed it. That is how it sticks.', style: AppTextStyles.bodyBold.copyWith(color: AppColors.success)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        GestureDetector(
          onTap: () => setState(() => _tip = !_tip),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: _tip ? AppColors.xp.withOpacity(0.10) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: _tip ? AppColors.xp.withOpacity(0.6) : AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_tip ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded, color: AppColors.xp, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: _tip
                      ? Text(widget.memoryTip, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))
                      : Text('Tap to reveal the memory trick', style: AppTextStyles.bodyBold.copyWith(color: AppColors.xp)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  final String word;
  final Color color;
  final bool hidden;
  final VoidCallback? onTap;
  const _WordTile({required this.word, required this.color, required this.hidden, this.onTap});

  @override
  Widget build(BuildContext context) {
    final first = word.isEmpty ? '' : word[0];
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: hidden ? AppColors.surfaceRaised : color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hidden ? AppColors.border : color.withOpacity(0.7)),
        ),
        child: hidden
            ? Text('$first${'•' * (word.length - 1).clamp(1, 6)}', style: AppTextStyles.display.copyWith(fontSize: 18, color: color))
            : RichText(
                text: TextSpan(style: AppTextStyles.display.copyWith(fontSize: 18, fontWeight: FontWeight.w500), children: [
                  TextSpan(text: first, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  TextSpan(text: word.substring(1)),
                ]),
              ),
      ),
    );
  }
}
