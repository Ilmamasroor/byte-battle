import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/voice/bit_voice.dart';
import '../../../../core/voice/sound_cues.dart';
import '../../../../core/voice/voice_sheet.dart';

/// Narration and sound-cue switches plus a shortcut to the voice settings (volume, speed, voice). Everything here is
/// optional: the visualization, captions and controls work the same with all of it off.
class AudioControls extends StatelessWidget {
  final SoundCues? cues;
  const AudioControls({super.key, this.cues});

  @override
  Widget build(BuildContext context) {
    final sfxAvailable = (cues ?? SoundCues()).available;
    return ListenableBuilder(
      listenable: BitVoice.instance,
      builder: (context, _) {
        final v = BitVoice.instance;
        return Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (v.available)
            _Toggle(
              key: const Key('narration-toggle'),
              on: v.enabled,
              onIcon: Icons.record_voice_over_rounded,
              offIcon: Icons.voice_over_off_rounded,
              label: 'Narration',
              onTap: () => v.configure(enabled: !v.enabled),
            )
          else
            Text('Voice is not available on this device. Captions below show everything that would be said.', key: const Key('voice-unavailable'), style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
          if (sfxAvailable)
            _Toggle(
              key: const Key('sfx-toggle'),
              on: v.sfxEnabled,
              onIcon: Icons.notifications_active_rounded,
              offIcon: Icons.notifications_off_rounded,
              label: 'Sound cues',
              onTap: () => v.configure(sfx: !v.sfxEnabled),
            ),
          IconButton(
            key: const Key('audio-settings'),
            tooltip: 'Voice, volume and speed',
            visualDensity: VisualDensity.compact,
            onPressed: () => showVoiceSheet(context),
            icon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textSecondary),
          ),
        ]);
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool on;
  final IconData onIcon;
  final IconData offIcon;
  final String label;
  final VoidCallback onTap;
  const _Toggle({super.key, required this.on, required this.onIcon, required this.offIcon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: on ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: on ? AppColors.primary : AppColors.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(on ? onIcon : offIcon, size: 18, color: on ? AppColors.onAccent : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('$label ${on ? 'on' : 'off'}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: on ? AppColors.onAccent : AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}
