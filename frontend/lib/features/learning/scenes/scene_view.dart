import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/voice/bit_voice.dart';
import '../../../core/voice/voice_sheet.dart';
import '../../../core/widgets/ai/companion_says.dart';
import '../../../core/widgets/brand/bit_mascot.dart';
import '../../../core/widgets/brand/confetti.dart';
import 'scene_models.dart';
import 'stages/computer_stage.dart';
import 'stages/flow_stage.dart';
import 'stages/sequence_stage.dart';
import 'stages/structure_stage.dart';
import 'stages/table_stage.dart';

/// Plays a [SceneDoc]: Bit narrates every step, the stage shows it, and the learner steps, plays or scrubs. An
/// optional prediction question comes first (guess, then watch), and a takeaway closes the scene.
class SceneView extends StatefulWidget {
  final SceneDoc doc;
  const SceneView({super.key, required this.doc});

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> {
  int _i = 0;
  bool _playing = false;
  int _run = 0; // bumped to cancel an autoplay loop
  double _speed = 1;
  int? _guess;
  int _confetti = 0;

  SceneDoc get _d => widget.doc;
  bool get _needsGuess => _d.predict != null && _guess == null;
  bool get _atEnd => _i >= _d.steps.length - 1;

  @override
  void initState() {
    super.initState();
    BitVoice.instance.load();
    if (_needsGuess) {
      // Greet with the setup line (after the first frame so the page is up before the voice starts).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _d.intro.isNotEmpty) BitVoice.instance.speak(_d.intro, owner: this);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
    }
  }

  @override
  void dispose() {
    _run++;
    BitVoice.instance.stop(owner: this);
    super.dispose();
  }

  /// What Bit says for the current step (the last step also lands the takeaway).
  String get _line {
    final step = _d.steps[_i];
    return _atEnd && _d.takeaway.isNotEmpty ? '${step.say} ${_d.takeaway}'.trim() : step.say;
  }

  Future<void> _speakCurrent() => BitVoice.instance.speak(_line, owner: this);

  void _go(int i) {
    final clamped = i.clamp(0, _d.steps.length - 1);
    setState(() => _i = clamped);
    if (clamped == _d.steps.length - 1) _confetti++;
  }

  /// A manual step: stop any autoplay, move, and speak the new line.
  void _manual(int i) {
    _run++;
    _playing = false;
    _go(i);
    _speakCurrent();
  }

  /// Autoplay: narrate a step, wait until Bit has finished speaking (or a reading-time delay when muted), then
  /// move on. Tapping any control cancels it.
  Future<void> _toggle() async {
    if (_playing) {
      _run++;
      BitVoice.instance.stop(owner: this);
      setState(() => _playing = false);
      return;
    }
    final id = ++_run;
    setState(() => _playing = true);
    if (_atEnd) _go(0);
    while (mounted && _run == id) {
      final started = DateTime.now();
      final text = _line;
      if (BitVoice.instance.enabled && BitVoice.instance.available) {
        await BitVoice.instance.speak(text, owner: this);
      }
      // Muted, unavailable, or the engine returned instantly: still give a human reading time.
      final readMs = (1800 + text.length * 38) / _speed;
      final spent = DateTime.now().difference(started).inMilliseconds;
      if (mounted && _run == id && spent < readMs * 0.6) {
        await Future<void>.delayed(Duration(milliseconds: (readMs - spent).round().clamp(300, 20000)));
      }
      if (!mounted || _run != id) return;
      await Future<void>.delayed(Duration(milliseconds: (450 / _speed).round()));
      if (!mounted || _run != id) return;
      if (_atEnd) break;
      _go(_i + 1);
    }
    if (mounted && _run == id) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_d.steps.isEmpty) return const SizedBox.shrink();
    if (_needsGuess) return _predict();
    final step = _d.steps[_i];
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (_d.predict != null && _guess != null && _i == 0)
                Expanded(
                    child: Text(_guess == _d.predict!.answer ? 'Good instinct. Watch to confirm it.' : 'Interesting guess. Watch what really happens.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)))
              else
                const Spacer(),
              const VoiceButton(),
            ]),
            CompanionSays(mood: _atEnd ? BitMood.cheer : BitMood.curious, text: _line),
            const SizedBox(height: AppDimensions.spacingSm),
            // The machine view keeps its own state across steps so it can animate what changed (a value flashing,
            // an object appearing, an arrow drawing); the other stages simply cross-fade.
            if (_d.kind == SceneKind.computer)
              _stage()
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(_i), child: _stage()),
              ),
            if (step.note != null && step.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(step.note!, style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.xp)),
            ],
            const SizedBox(height: AppDimensions.spacingMd),
            _controls(),
            if (_atEnd && _d.predict != null && _d.predict!.reveal.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.success.withOpacity(0.6))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.emoji_objects_rounded, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_d.predict!.reveal, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
                ]),
              ),
            ],
          ],
        ),
        Positioned.fill(child: ConfettiBurst(trigger: _confetti)),
      ],
    );
  }

  Widget _stage() {
    final s = _d.steps[_i].state;
    switch (_d.kind) {
      case SceneKind.computer:
        return ComputerStage(s: s, prev: _i > 0 ? _d.steps[_i - 1].state : null, stepIndex: _i);
      case SceneKind.structure:
        return StructureStage(s: s);
      case SceneKind.table:
        return TableStage(s: s);
      case SceneKind.sequence:
        return SequenceStage(doc: _d, index: _i);
      case SceneKind.flow:
        return FlowStage(s: s);
    }
  }

  Widget _predict() {
    final p = _d.predict!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Align(alignment: Alignment.centerRight, child: VoiceButton()),
      CompanionSays(mood: BitMood.curious, text: _d.intro.isEmpty ? 'Before we start, make a guess.' : _d.intro),
      const SizedBox(height: AppDimensions.spacingMd),
      Text(p.question, style: AppTextStyles.display.copyWith(fontSize: 22, fontWeight: FontWeight.w500)),
      const SizedBox(height: AppDimensions.spacingMd),
      for (var i = 0; i < p.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () {
              setState(() => _guess = i);
              WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: AppColors.borderLight)),
              child: Row(children: [
                Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(9)),
                    child: Text(String.fromCharCode(65 + i), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800))),
                const SizedBox(width: 12),
                Expanded(child: Text(p.options[i], style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
              ]),
            ),
          ),
        ),
      Center(
          child: TextButton(
        onPressed: () {
          setState(() => _guess = -1);
          WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
        },
        child: const Text('Skip, just show me'),
      )),
    ]);
  }

  Widget _controls() {
    final total = _d.steps.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusLg), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => _manual(0), icon: const Icon(Icons.restart_alt_rounded), tooltip: 'Restart'),
          IconButton(onPressed: _i > 0 ? () => _manual(_i - 1) : null, icon: const Icon(Icons.skip_previous_rounded, size: 28), tooltip: 'Back'),
          GestureDetector(
            onTap: _toggle,
            child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.onAccent, size: 34)),
          ),
          IconButton(onPressed: !_atEnd ? () => _manual(_i + 1) : null, icon: const Icon(Icons.skip_next_rounded, size: 28), tooltip: 'Next'),
          TextButton(
              onPressed: () => setState(() => _speed = _speed == 1 ? 2 : (_speed == 2 ? 0.5 : 1)),
              child: Text('${_speed == _speed.roundToDouble() ? _speed.toInt() : _speed}x', style: AppTextStyles.bodyBold)),
        ]),
        Row(children: [
          Text('${_i + 1}', style: AppTextStyles.caption),
          Expanded(
              child: Slider(
                  value: _i.toDouble(),
                  min: 0,
                  max: (total - 1).toDouble().clamp(1, 1000),
                  divisions: total > 1 ? total - 1 : null,
                  onChanged: (v) {
                    _run++;
                    _playing = false;
                    _go(v.round());
                  },
                  onChangeEnd: (v) => _speakCurrent())),
          Text('$total', style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}
