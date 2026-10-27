import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../personalization/hero_prefs.dart';
import '../../voice/bit_voice.dart';
import '../brand/bit_mascot.dart';

/// The learner's companion talking: [BitMascot] plus a speech bubble whose text types out. Use it wherever the
/// app wants to *guide* (intros, reactions, hints) instead of just printing text. Tapping the bubble finishes the
/// typing instantly. Changing [text] restarts the typing.
class CompanionSays extends StatefulWidget {
  final String text;
  final BitMood mood;
  final double mascotSize;
  final bool showName;
  final VoidCallback? onDone;

  /// Read the text aloud in Bit's voice (respects the learner's mute and voice settings).
  final bool speak;

  const CompanionSays({
    super.key,
    required this.text,
    this.mood = BitMood.happy,
    this.mascotSize = 56,
    this.showName = true,
    this.onDone,
    this.speak = false,
  });

  @override
  State<CompanionSays> createState() => _CompanionSaysState();
}

class _CompanionSaysState extends State<CompanionSays> {
  Timer? _timer;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(CompanionSays old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    _timer?.cancel();
    _shown = 0;
    if (widget.speak) BitVoice.instance.speak(widget.text, owner: this);
    _timer = Timer.periodic(const Duration(milliseconds: 22), (t) {
      if (!mounted) return t.cancel();
      if (_shown >= widget.text.length) {
        t.cancel();
        widget.onDone?.call();
        return;
      }
      setState(() => _shown++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.speak) BitVoice.instance.stop(owner: this); // only this bubble's own sentence, never another component's
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _shown >= widget.text.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        BitMascot(size: widget.mascotSize, mood: done ? widget.mood : BitMood.happy),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _shown = widget.text.length),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showName)
                    ListenableBuilder(
                      listenable: HeroPrefs.instance,
                      builder: (context, _) => Text(
                        HeroPrefs.instance.companionName.toUpperCase(),
                        style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentCyan, fontSize: 10),
                      ),
                    ),
                  if (widget.showName) const SizedBox(height: 3),
                  // Reserve the final height up front so the bubble does not jump while typing.
                  Stack(
                    children: [
                      Opacity(
                        opacity: 0,
                        child: Text(widget.text, style: _style),
                      ),
                      Text(widget.text.substring(0, _shown.clamp(0, widget.text.length)), style: _style),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static final _style = AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 13.5, height: 1.45);
}
