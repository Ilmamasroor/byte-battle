import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/voice/bit_voice.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../engine/narration_controller.dart';
import '../engine/playback_controller.dart';

/// The caption for the event on screen, always shown, with a transcript of everything narrated so far. It reads the
/// same [textAt] the narration speaks, so what is written is exactly what is said, and it stays correct when audio is
/// muted, unavailable, or has failed.
class NarrationCaption extends StatefulWidget {
  final NarrationController narration;
  final VizPlaybackController playback;
  final String Function(int position) textAt;

  const NarrationCaption({super.key, required this.narration, required this.playback, required this.textAt});

  @override
  State<NarrationCaption> createState() => _NarrationCaptionState();
}

class _NarrationCaptionState extends State<NarrationCaption> {
  bool _transcript = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.narration, widget.playback, BitVoice.instance]),
      builder: (context, _) {
        final pos = widget.playback.position;
        final text = widget.textAt(pos);
        final speaking = widget.narration.speakingAt == pos;
        final canHear = widget.narration.canSpeak && !speaking;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            key: const Key('caption'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: speaking ? AppColors.accentCyan : AppColors.border)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BitMascot(size: 38, mood: speaking ? BitMood.cheer : BitMood.curious),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 14, height: 1.45)),
                ),
              ),
              if (speaking)
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.graphic_eq_rounded, key: Key('speaking'), size: 22, color: AppColors.accentCyan, semanticLabel: 'Speaking'))
              else if (canHear)
                IconButton(
                  key: const Key('hear-step'),
                  tooltip: 'Hear this step',
                  onPressed: widget.narration.hear,
                  icon: const Icon(Icons.volume_up_rounded, size: 22, color: AppColors.textSecondary),
                ),
            ]),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('transcript-toggle'),
              onPressed: () => setState(() => _transcript = !_transcript),
              icon: Icon(_transcript ? Icons.expand_less_rounded : Icons.subject_rounded, size: 18),
              label: Text(_transcript ? 'Hide transcript' : 'Show transcript'),
            ),
          ),
          if (_transcript)
            Container(
              key: const Key('transcript'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var p = 1; p <= pos; p++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: '$p.  ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800)),
                      TextSpan(text: widget.textAt(p), style: AppTextStyles.body.copyWith(fontSize: 12.5, color: p == pos ? AppColors.textPrimary : AppColors.textSecondary)),
                    ])),
                  ),
                if (pos == 0) Text('Nothing has happened yet. Step forward or press play.', style: AppTextStyles.caption),
              ]),
            ),
        ]);
      },
    );
  }
}
