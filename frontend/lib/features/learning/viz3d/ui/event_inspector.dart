import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../contract/viz_contract.dart';

/// Explains the selected event: which one it is, the statement, the value it changes (before and after), why it
/// matters, and whether it is where the lesson's anomaly happens. It reads only the [VizExplanation] of the
/// selected position, so it can never disagree with the scene or the code highlight.
class EventInspector extends StatelessWidget {
  final VizExplanation explanation;
  final int position;
  final int length;
  final String? actor; // who did it, already labelled
  final String? kind; // what kind of event it was

  const EventInspector({super.key, required this.explanation, required this.position, required this.length, this.actor, this.kind});

  @override
  Widget build(BuildContext context) {
    final e = explanation;
    final c = e.change;
    final atStart = position == 0;
    return Semantics(
      container: true,
      label: atStart ? 'Event inspector: before the first event' : 'Event inspector: event $position of ${length - 1}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: e.hazard != null ? AppColors.error.withOpacity(0.7) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(atStart ? 'BEFORE THE FIRST EVENT' : 'EVENT $position OF ${length - 1}', style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentCyan), overflow: TextOverflow.ellipsis)),
            if (actor != null && !atStart) ...[
              const SizedBox(width: 8),
              Flexible(child: Text('$actor${kind == null ? '' : ' · $kind'}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            ],
          ]),
          if (e.hazard != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                const SizedBox(width: 6),
                Text(e.hazard!, style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w800)),
              ]),
            ),
          ],
          if (e.note != null && e.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(e.note!, style: AppTextStyles.code.copyWith(fontSize: 12, color: AppColors.xp)),
          ],
          if (c != null) ...[
            const SizedBox(height: 8),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 4, children: [
              Text(c.what, style: AppTextStyles.caption),
              _Value(c.before),
              const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.textHint),
              _Value(c.after, strong: true),
              if (!c.isChange) Text('(no net change)', style: AppTextStyles.caption),
            ]),
          ],
          if (e.why != null && e.why!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('WHY IT MATTERS', style: AppTextStyles.eyebrow),
            const SizedBox(height: 3),
            Text(e.why!, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final String v;
  final bool strong;
  const _Value(this.v, {this.strong = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(8), border: Border.all(color: strong ? AppColors.primary : AppColors.border)),
        child: Text(v, style: AppTextStyles.code.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      );
}
