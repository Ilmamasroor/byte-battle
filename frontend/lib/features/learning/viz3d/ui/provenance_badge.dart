import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../contract/viz_contract.dart';

/// States where the events on screen come from: a deterministic teaching simulation or an authored example. A
/// modelled sequence must never read as a recording of the learner's program running.
class ProvenanceBadge extends StatelessWidget {
  final VizProvenance provenance;
  const ProvenanceBadge({super.key, required this.provenance});

  @override
  Widget build(BuildContext context) {
    final authored = provenance.kind == VizProvenanceKind.authored;
    final color = authored ? AppColors.warning : AppColors.accentCyan;
    return Container(
      key: const Key('provenance'),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(authored ? Icons.edit_note_rounded : Icons.science_outlined, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(provenance.label.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(provenance.detail, style: AppTextStyles.caption),
            for (final c in provenance.caveats) Padding(padding: const EdgeInsets.only(top: 2), child: Text('• $c', style: AppTextStyles.caption)),
          ]),
        ),
      ]),
    );
  }
}

/// Says plainly when the simulator could not model a program faithfully, instead of drawing events it would have to guess.
class UnsupportedNotice extends StatelessWidget {
  final VizSupportInfo support;
  const UnsupportedNotice({super.key, required this.support});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('unsupported'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warning)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(child: Text('This program cannot be simulated accurately', style: AppTextStyles.bodyBold)),
        ]),
        const SizedBox(height: 8),
        for (final r in support.reasons) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(r, style: AppTextStyles.body)),
        Text('This is a limit of the teaching simulator, not a mistake in your answer.', style: AppTextStyles.caption),
      ]),
    );
  }
}
