import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../personalization/lens.dart';
import '../brand/bit_mascot.dart';
import 'key_term_text.dart';

/// The analogy as a little scene: the everyday picture, then a "what maps to what" board (real-world thing on the
/// left, the code idea on the right, revealed one pair at a time), then the memory tip from the companion.
class AnalogyScene extends StatefulWidget {
  final String analogy;
  final String connection;
  final String memoryTip;
  final Lens? lens;
  const AnalogyScene({super.key, required this.analogy, required this.connection, required this.memoryTip, this.lens});

  /// "The scoreboard is the shared resource; the umpire is the lock" -> [(scoreboard, shared resource), ...].
  static List<(String, String)> parseMapping(String connection) {
    final pairs = <(String, String)>[];
    final re = RegExp(r'^(?:the |a |an )?(.+?)\s+(?:is|are|represents?|acts? as)\s+(?:the |a |an )?(.+)$', caseSensitive: false);
    for (final raw in connection.split(RegExp(r'[;\n]|(?<=\.)\s+'))) {
      final part = raw.trim().replaceAll(RegExp(r'[.]+$'), '');
      final m = re.firstMatch(part);
      if (m != null && m.group(1)!.length < 60) pairs.add((m.group(1)!.trim(), m.group(2)!.trim()));
    }
    return pairs;
  }

  @override
  State<AnalogyScene> createState() => _AnalogySceneState();
}

class _AnalogySceneState extends State<AnalogyScene> {
  int _revealed = 0;

  @override
  Widget build(BuildContext context) {
    final pairs = AnalogyScene.parseMapping(widget.connection);
    final all = _revealed >= pairs.length;
    final lens = widget.lens;
    final accent = lens?.color ?? AppColors.accentCyan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lens?.id == 'movies')
          _FilmStrip(text: widget.analogy, title: lens!.pictureTitle, color: accent)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              gradient: LinearGradient(colors: [accent.withOpacity(0.16), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: accent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(lens?.icon ?? Icons.theater_comedy_rounded, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Text(lens?.pictureTitle ?? 'PICTURE THIS', style: AppTextStyles.eyebrow.copyWith(color: accent)),
                ]),
                const SizedBox(height: 14),
                Text(widget.analogy, style: AppTextStyles.display.copyWith(fontSize: 21, height: 1.35, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.spacingLg),
        Row(children: [
          Expanded(child: Text(lens?.mapTitle ?? 'NOW MAP IT TO CODE', overflow: TextOverflow.ellipsis, style: AppTextStyles.eyebrow)),
          if (pairs.isNotEmpty && !all)
            TextButton(onPressed: () => setState(() => _revealed++), child: const Text('Reveal next')),
          if (pairs.isNotEmpty && !all)
            TextButton(onPressed: () => setState(() => _revealed = pairs.length), child: const Text('All')),
        ]),
        const SizedBox(height: 6),
        if (pairs.isEmpty)
          KeyTermText(text: widget.connection, style: AppTextStyles.body)
        else
          for (var i = 0; i < pairs.length; i++)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: i >= _revealed
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _revealed = i + 1),
                        child: _MapRow(left: pairs[i].$1, right: null, index: i),
                      ),
                    )
                  : Padding(padding: const EdgeInsets.only(bottom: 10), child: _MapRow(left: pairs[i].$1, right: pairs[i].$2, index: i)),
            ),
        const SizedBox(height: AppDimensions.spacingMd),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.orchid.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.orchid.withOpacity(0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BitMascot(size: 40, mood: BitMood.curious),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lens?.tipTitle ?? 'HOLD ON TO THIS', style: AppTextStyles.eyebrow.copyWith(color: AppColors.orchid, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(widget.memoryTip, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapRow extends StatelessWidget {
  final String left;
  final String? right;
  final int index;
  const _MapRow({required this.left, required this.right, required this.index});

  @override
  Widget build(BuildContext context) {
    final revealed = right != null;
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.accentCyan.withOpacity(0.5)),
            ),
            child: Text(_cap(left), style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 18, color: revealed ? AppColors.primary : AppColors.textHint),
        ),
        Expanded(
          flex: 5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: revealed ? AppColors.primary.withOpacity(0.14) : AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: revealed ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              revealed ? _cap(right!) : 'tap to reveal',
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13, color: revealed ? AppColors.textPrimary : AppColors.textHint, fontWeight: revealed ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  static String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}


/// The analogy as a storyboard: up to three film frames (SCENE 1, 2, 3) on a strip with sprocket holes, swiped
/// sideways. Used by the Movies lens so the explanation literally plays like a short film.
class _FilmStrip extends StatelessWidget {
  final String text;
  final String title;
  final Color color;
  const _FilmStrip({required this.text, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final sentences = text.replaceAll(RegExp(r'\s+'), ' ').trim().split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
    final n = sentences.length.clamp(1, 3);
    final per = (sentences.length / n).ceil();
    final frames = [for (var i = 0; i < n; i++) sentences.skip(i * per).take(per).join(' ')].where((f) => f.isNotEmpty).toList();
    Widget holes() => SizedBox(
          height: 14,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (var i = 0; i < 14; i++) Container(width: 9, height: 7, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(2)))]),
        );
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF0A0A0D), borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: color.withOpacity(0.6))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
            child: Row(children: [
              Icon(Icons.movie_filter_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.eyebrow.copyWith(color: color)),
              const Spacer(),
              Text('swipe', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              Icon(Icons.chevron_right_rounded, color: color, size: 16),
            ]),
          ),
          holes(),
          const SizedBox(height: 6),
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.88),
              itemCount: frames.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [color.withOpacity(0.22), AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SCENE ${i + 1}  /  ${frames.length}', style: AppTextStyles.eyebrow.copyWith(color: color, fontSize: 10)),
                  const SizedBox(height: 8),
                  Expanded(child: SingleChildScrollView(child: Text(frames[i], style: AppTextStyles.display.copyWith(fontSize: 18, height: 1.4, fontWeight: FontWeight.w500)))),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 6),
          holes(),
        ],
      ),
    );
  }
}
