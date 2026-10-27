import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../contract/viz_contract.dart';
import '../engine/viz_session.dart';
import '../render/scene_spec.dart';
import '../render/viz_viewport.dart';
import 'explanation_panel.dart';
import 'viz_controls.dart';

/// The universal visualization shell: lesson, variant and input choosers, the 3D viewport (or its fallback), the
/// inspector, the shared controls, the explanation and the checked outcome. It knows nothing about any topic; it
/// works against a [VizSession].
class VizShell extends StatelessWidget {
  final VizSession session;

  /// Replaces the default narration text (the lesson screen passes Bit's speech bubble).
  final Widget Function(BuildContext context, VizExplanation explanation)? narrationBuilder;
  final double viewportHeight;

  const VizShell({super.key, required this.session, this.narrationBuilder, this.viewportHeight = 340});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final lesson = session.lesson;
        if (session.needsGuess) return _PredictionCard(session: session, narrationBuilder: narrationBuilder);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (session.lessons.length > 1) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < session.lessons.length; i++)
                VizChip(label: _lessonLabel(session.lessons[i]), selected: i == session.lessonIndex, onTap: () => session.selectLesson(i)),
            ]),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
          if (lesson.variants.length > 1) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final v in lesson.variants) VizChip(label: v.label, selected: v.id == session.variantId, onTap: () => session.setVariant(v.id)),
            ]),
            const SizedBox(height: AppDimensions.spacingMd),
          ],
          for (final p in lesson.params) ...[
            _ParamRow(param: p, value: session.params[p.id] ?? p.initial, onPick: (v) => session.setParam(p.id, v)),
            const SizedBox(height: 10),
          ],
          _ViewToggle(session: session),
          const SizedBox(height: 10),
          _stage(context),
          const SizedBox(height: AppDimensions.spacingMd),
          _Inspector(session: session),
          VizControls(controller: session.controller, markers: session.timeline.markers),
          const SizedBox(height: AppDimensions.spacingMd),
          AnimatedBuilder(
            animation: session.controller,
            builder: (context, _) {
              final frame = session.frame;
              return ExplanationPanel(
                explanation: frame.explanation,
                code: session.timeline.code,
                abstractionNote: lesson.abstractionNote,
                narration: narrationBuilder?.call(context, frame.explanation),
              );
            },
          ),
          VizOutcomeCard(session: session),
          _Reveal(session: session),
        ]);
      },
    );
  }

  String _lessonLabel(VizLesson l) => l.params.isNotEmpty ? 'Try it yourself' : 'Walkthrough';

  Widget _stage(BuildContext context) {
    if (session.show3D) {
      return VizViewport(
        key: ValueKey('${session.lesson.id}|${session.variantId}|${session.params}'),
        timeline: session.timeline,
        controller: session.controller,
        interactions: session.lesson.interactions,
        selectedId: session.selectedId,
        onSelect: session.select,
        onFailure: session.reportFailure,
        height: viewportHeight,
      );
    }
    return FlatFallback(
        session: session,
        reason: session.failure != null || !session.prefer3D
            ? (session.failure != null ? '3D could not start here, so you are seeing the flat view. Everything below still works.' : null)
            : null);
  }
}

/// The learner-facing choice between 3D and the flat view, shown only when there is something to switch.
class _ViewToggle extends StatelessWidget {
  final VizSession session;
  const _ViewToggle({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      VizChip(label: '3D view', icon: Icons.view_in_ar_rounded, selected: session.show3D, onTap: () => session.set3D(true)),
      const SizedBox(width: 8),
      VizChip(label: 'Flat view', icon: Icons.article_outlined, selected: !session.show3D, onTap: () => session.set3D(false)),
    ]);
  }
}

/// What the learner sees when 3D is off or failed: the lesson's own 2D view if it has one, otherwise the whole
/// timeline as a readable step list. Either way the explanation is complete.
class FlatFallback extends StatelessWidget {
  final VizSession session;
  final String? reason;
  const FlatFallback({super.key, required this.session, this.reason});

  @override
  Widget build(BuildContext context) {
    final flat = session.lesson.flatBuilder;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (reason != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            Expanded(child: Text(reason!, style: AppTextStyles.caption.copyWith(color: AppColors.warning))),
          ]),
        ),
      if (flat != null) flat(context) else _StepList(session: session),
    ]);
  }
}

class _StepList extends StatelessWidget {
  final VizSession session;
  const _StepList({required this.session});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session.controller,
      builder: (context, _) {
        final tl = session.timeline;
        final cur = session.controller.position;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < tl.length; i++)
              InkWell(
                onTap: () => session.controller.seek(i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(color: i == cur ? AppColors.primary.withOpacity(0.16) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 26, child: Text('$i', style: AppTextStyles.code.copyWith(fontSize: 11, color: i == cur ? AppColors.primary : AppColors.textHint))),
                    Expanded(
                        child: Text(session.frameAt(i).explanation.text,
                            style: AppTextStyles.body.copyWith(
                                fontSize: 13, color: i == cur ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: i == cur ? FontWeight.w700 : FontWeight.w400))),
                  ]),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// Shown when a concept has nothing visualizable: says so plainly instead of drawing an empty scene.
class VizUnsupported extends StatelessWidget {
  final String reason;
  final Widget? fallback;
  const VizUnsupported({super.key, required this.reason, this.fallback});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusMd), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.view_in_ar_rounded, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(child: Text(reason, style: AppTextStyles.body)),
        ]),
      ),
      if (fallback != null) ...[const SizedBox(height: AppDimensions.spacingMd), fallback!],
    ]);
  }
}

class _Inspector extends StatelessWidget {
  final VizSession session;
  const _Inspector({required this.session});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session.controller,
      builder: (context, _) {
        final id = session.selectedId;
        if (id == null || !session.show3D) return const SizedBox.shrink();
        final SceneNode? node = session.frame.scene.node(id);
        if (node == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accentCyan.withOpacity(0.6))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.search_rounded, size: 16, color: AppColors.accentCyan),
                const SizedBox(width: 6),
                Text('INSPECTING', style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentCyan)),
                const Spacer(),
                InkWell(onTap: () => session.select(null), child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
              ]),
              const SizedBox(height: 6),
              for (final e in node.inspect.entries.where((e) => e.value.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${e.key}: ', style: AppTextStyles.caption),
                    TextSpan(text: e.value, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  ])),
                ),
              if (node.inspect.isEmpty) Text(node.label ?? node.id, style: AppTextStyles.body),
            ]),
          ),
        );
      },
    );
  }
}

/// The checked result of this run, and (for lessons with variants) every variant's result side by side so the
/// learner can compare outcomes.
class VizOutcomeCard extends StatelessWidget {
  final VizSession session;
  const VizOutcomeCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session.controller,
      builder: (context, _) {
        final tl = session.timeline;
        if (!session.controller.atEnd || tl.outcome == null) return const SizedBox.shrink();
        final lesson = session.lesson;
        final compare = lesson.interactions.contains(VizInteraction.compare) && lesson.variants.length > 1;
        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _OutcomeRow(label: compare ? lesson.variants.firstWhere((v) => v.id == session.variantId).label : 'Result', outcome: tl.outcome!, highlight: true),
            if (compare)
              for (final v in lesson.variants.where((v) => v.id != session.variantId))
                if (session.outcomeOf(v.id) != null) _OutcomeRow(label: v.label, outcome: session.outcomeOf(v.id)!, highlight: false),
          ]),
        );
      },
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final String label;
  final VizOutcome outcome;
  final bool highlight;
  const _OutcomeRow({required this.label, required this.outcome, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final ok = outcome.matches;
    final color = ok ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
          color: color.withOpacity(highlight ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: color.withOpacity(highlight ? 0.6 : 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: color)),
            const SizedBox(height: 4),
            Text('${outcome.label}: expected ${outcome.expected}, got ${outcome.actual}', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(outcome.meaning, style: AppTextStyles.body),
          ]),
        ),
      ]),
    );
  }
}

/// A pill used for lesson, variant and input choices.
class VizChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const VizChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: selected ? AppColors.onAccent : AppColors.textSecondary), const SizedBox(width: 6)],
            Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: selected ? AppColors.onAccent : AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

class _ParamRow extends StatelessWidget {
  final VizParam param;
  final String value;
  final ValueChanged<String> onPick;
  const _ParamRow({required this.param, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(param.label.toUpperCase(), style: AppTextStyles.eyebrow),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in param.choices) VizChip(label: c.label, selected: c.value == value, onTap: () => onPick(c.value)),
      ]),
    ]);
  }
}

/// The "guess first, then watch" step. Answering or skipping is recorded on the session, then the lesson plays.
class _PredictionCard extends StatelessWidget {
  final VizSession session;
  final Widget Function(BuildContext context, VizExplanation explanation)? narrationBuilder;
  const _PredictionCard({required this.session, this.narrationBuilder});

  @override
  Widget build(BuildContext context) {
    final p = session.lesson.predict!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (session.lesson.summary.isNotEmpty)
        narrationBuilder?.call(context, VizExplanation(session.lesson.summary)) ?? Text(session.lesson.summary, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
      const SizedBox(height: AppDimensions.spacingMd),
      Text(p.question, style: AppTextStyles.display.copyWith(fontSize: 22, fontWeight: FontWeight.w500)),
      const SizedBox(height: AppDimensions.spacingMd),
      for (var i = 0; i < p.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: () => session.answerPrediction(i),
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
      Center(child: TextButton(onPressed: () => session.answerPrediction(-1), child: const Text('Skip, just show me'))),
    ]);
  }
}

/// After the run, says whether the prediction held and why.
class _Reveal extends StatelessWidget {
  final VizSession session;
  const _Reveal({required this.session});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session.controller,
      builder: (context, _) {
        final p = session.lesson.predict;
        if (p == null || !session.controller.atEnd || p.reveal.isEmpty) return const SizedBox.shrink();
        final guess = session.guess;
        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.success.withOpacity(0.6))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.emoji_objects_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (guess != null && guess >= 0)
                    Text(guess == p.answer ? 'You called it.' : 'Not quite: the answer was ${p.options[p.answer]}.',
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                  Text(p.reveal, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
