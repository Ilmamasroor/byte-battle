import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../contract/viz_contract.dart';

/// The explanation layer: what is happening now, the source line that runs, the values in play and the output so
/// far. It reads only a [VizExplanation], so it works the same for a thread, a sort and a TCP handshake, and it
/// stays fully usable when 3D is off.
class ExplanationPanel extends StatelessWidget {
  final VizExplanation explanation;
  final List<String> code;
  final String? abstractionNote;

  /// Replaces the plain narration text (the screen passes Bit's speech bubble here).
  final Widget? narration;

  /// Hide the narration card and the hazard badge when another widget (caption, event inspector) already shows
  /// them, so the same sentence is not on screen twice.
  final bool showNarration;
  final bool showHazard;

  const ExplanationPanel(
      {super.key, required this.explanation, this.code = const [], this.abstractionNote, this.narration, this.showNarration = true, this.showHazard = true});

  @override
  Widget build(BuildContext context) {
    final e = explanation;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showNarration) narration ?? _NarrationCard(text: e.text),
      if (showHazard && e.hazard != null) ...[
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration:
                BoxDecoration(color: AppColors.error.withOpacity(0.14), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.6))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(e.hazard!, style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ],
      if (showNarration && e.note != null && e.note!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(e.note!, style: AppTextStyles.code.copyWith(fontSize: 11.5, color: AppColors.xp)),
      ],
      if (code.isNotEmpty) ...[
        const SizedBox(height: 10),
        _Code(lines: code, at: e.codeLines.toSet()),
      ],
      if (e.variables.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [for (final v in e.variables.entries) _VarChip(name: v.key, value: v.value)]),
      ],
      if (e.output.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF0F2A22), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withOpacity(0.4))),
          child: Text(e.output.join('\n'), style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.success)),
        ),
      ],
      if (abstractionNote != null) ...[
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(child: Text(abstractionNote!, style: AppTextStyles.caption)),
        ]),
      ],
    ]);
  }
}

class _NarrationCard extends StatelessWidget {
  final String text;
  const _NarrationCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: AppColors.border)),
        child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  final List<String> lines;
  final Set<int> at;
  const _Code({required this.lines, required this.at});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        for (var i = 0; i < lines.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            color: at.contains(i) ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 22, child: Text('${i + 1}', style: AppTextStyles.code.copyWith(fontSize: 11, color: at.contains(i) ? AppColors.primary : AppColors.textHint))),
              Expanded(
                  child: Text(lines[i],
                      style: AppTextStyles.code.copyWith(
                          fontSize: 12, color: at.contains(i) ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: at.contains(i) ? FontWeight.w700 : FontWeight.w400))),
              if (at.contains(i)) const Icon(Icons.arrow_left_rounded, size: 18, color: AppColors.primary),
            ]),
          ),
      ]),
    );
  }
}

class _VarChip extends StatelessWidget {
  final String name;
  final String value;
  const _VarChip({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$name ', style: AppTextStyles.code.copyWith(fontSize: 11, color: AppColors.textHint)),
        TextSpan(text: value, style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
      ])),
    );
  }
}
