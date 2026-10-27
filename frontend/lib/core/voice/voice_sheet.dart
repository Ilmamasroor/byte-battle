import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../widgets/brand/bit_mascot.dart';
import 'bit_voice.dart';
import 'sound_cues.dart';

/// A speaker button: tap to mute/unmute Bit, long-press (or the tune icon) to open the voice settings.
class VoiceButton extends StatelessWidget {
  const VoiceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BitVoice.instance,
      builder: (context, _) {
        final v = BitVoice.instance;
        if (!v.available) return const SizedBox.shrink();
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            button: true,
            label: v.enabled ? 'Mute Bit' : 'Let Bit speak',
            child: GestureDetector(
              onTap: () => v.configure(enabled: !v.enabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: v.enabled ? AppColors.primary : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: v.enabled ? AppColors.primary : AppColors.border),
                ),
                child: Icon(v.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 20, color: v.enabled ? AppColors.onAccent : AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: "Bit's voice",
            visualDensity: VisualDensity.compact,
            onPressed: () => showVoiceSheet(context),
            icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
          ),
        ]);
      },
    );
  }
}

Future<void> showVoiceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg + 4))),
    builder: (_) => const _VoiceSheet(),
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  late final Future<List<String>> _voices = BitVoice.instance.voices();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding, 12, AppDimensions.screenPadding, 24),
        child: ListenableBuilder(
          listenable: BitVoice.instance,
          builder: (context, _) {
            final v = BitVoice.instance;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 18),
              Row(children: [
                const BitMascot(size: 48, mood: BitMood.cheer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Bit's voice", style: AppTextStyles.heading2),
                    Text('Spoken by your device. Nothing is recorded or uploaded.', style: AppTextStyles.caption),
                  ]),
                ),
                Switch(value: v.enabled, onChanged: (x) => v.configure(enabled: x)),
              ]),
              const SizedBox(height: 18),
              Text('VOICE', style: AppTextStyles.eyebrow),
              const SizedBox(height: 8),
              FutureBuilder<List<String>>(
                future: _voices,
                builder: (context, snap) {
                  final names = snap.data ?? const <String>[];
                  if (snap.connectionState != ConnectionState.done) return Text('Looking for voices...', style: AppTextStyles.caption);
                  if (names.isEmpty) return Text('Using your device default voice.', style: AppTextStyles.body);
                  final value = names.contains(v.voiceName) ? v.voiceName : null;
                  return DropdownButtonFormField<String?>(
                    value: value,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    dropdownColor: AppColors.surfaceRaised,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Device default')),
                      for (final n in names) DropdownMenuItem<String?>(value: n, child: Text(n, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (n) => n == null ? v.configure(clearVoice: true) : v.configure(voice: n),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text('VOLUME  ${(v.volume * 100).round()}%', style: AppTextStyles.eyebrow),
              Slider(value: v.volume, min: 0, max: 1, divisions: 10, label: '${(v.volume * 100).round()}%', onChanged: (x) => v.configure(volume: x)),
              if (SoundCues().available)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Sound cues', style: AppTextStyles.bodyBold),
                  subtitle: Text('A short tick when a value is written and an alert when an update is lost. Uses your device\'s system sounds.', style: AppTextStyles.caption),
                  value: v.sfxEnabled,
                  onChanged: (x) => v.configure(sfx: x),
                ),
              const SizedBox(height: 8),
              Text('SPEED', style: AppTextStyles.eyebrow),
              const SizedBox(height: 6),
              SegmentedButton<double>(
                key: const Key('speed-choice'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: BitVoice.slower, label: Text('Slower')),
                  ButtonSegment(value: BitVoice.normal, label: Text('Normal')),
                  ButtonSegment(value: BitVoice.faster, label: Text('Faster')),
                ],
                selected: {BitVoice.snapSpeed(v.speed)},
                onSelectionChanged: (s) => v.configure(speed: s.first),
              ),
              const SizedBox(height: 8),
              Text('PITCH  ${v.pitch < 0.95 ? 'deeper' : (v.pitch > 1.15 ? 'brighter' : 'natural')}', style: AppTextStyles.eyebrow),
              Slider(value: v.pitch, min: 0.8, max: 1.4, divisions: 6, onChanged: (x) => v.configure(pitch: x)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => v.speak('Hi, I am Bit. This is how I sound when I walk you through the code.'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Hear a sample'),
                ),
              ),
              const SizedBox(height: 8),
              const _SpeechLog(),
            ]);
          },
        ),
      ),
    );
  }
}

/// Temporary diagnostics for the voice reliability work: what the speech pipeline did, newest last. It records
/// identities, timings and settings, never the spoken text, and holds at most the last 150 entries.
class _SpeechLog extends StatelessWidget {
  const _SpeechLog();

  @override
  Widget build(BuildContext context) {
    final d = BitVoice.instance.diagnostics;
    return ExpansionTile(
      key: const Key('speech-log'),
      tilePadding: EdgeInsets.zero,
      title: Text('Speech log (temporary)', style: AppTextStyles.bodyBold),
      subtitle: Text('For fixing voice problems. Contains no spoken text.', style: AppTextStyles.caption),
      children: [
        ListenableBuilder(
          listenable: d,
          builder: (context, _) {
            final text = d.dump(BitVoice.instance.describe());
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TextButton.icon(
                  key: const Key('speech-log-copy'),
                  onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
                TextButton(onPressed: d.clear, child: const Text('Clear')),
              ]),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: SingleChildScrollView(reverse: true, child: SelectableText(text, style: AppTextStyles.code.copyWith(fontSize: 10.5))),
              ),
            ]);
          },
        ),
      ],
    );
  }
}
