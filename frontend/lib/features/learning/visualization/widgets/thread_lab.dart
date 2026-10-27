import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../viz3d/contract/viz_contract.dart';
import '../../viz3d/engine/narration_controller.dart';
import '../../viz3d/engine/viz_session.dart';
import '../../viz3d/modules/concurrency/thread_lanes.dart';
import '../../viz3d/modules/concurrency/thread_schedule_lesson.dart';
import '../../viz3d/render/viz_viewport.dart';
import '../../viz3d/ui/audio_controls.dart';
import '../../viz3d/ui/event_inspector.dart';
import '../../viz3d/ui/event_timeline.dart';
import '../../viz3d/ui/explanation_panel.dart';
import '../../viz3d/ui/narration_caption.dart';
import '../../viz3d/ui/provenance_badge.dart';
import '../../viz3d/ui/viz_controls.dart';
import '../../viz3d/ui/viz_shell.dart';

/// The "Watch" view for thread lessons: where the events come from, the lane picture (or the optional 3D chamber),
/// the execution timeline, controls, narration with captions, the event inspector, the source and the checked
/// outcome. Every piece reads the one [VizSession] (and its playback position), so the selected event is the same
/// everywhere at once.
class ThreadLab extends StatelessWidget {
  final VizSession session;
  final VisualizationModel model;
  final NarrationController narration;

  const ThreadLab({super.key, required this.session, required this.model, required this.narration});

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: session, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final lesson = session.lesson;
    final pb = session.controller;
    final tl = session.timeline;
    final variants = lesson.variants;
    final schedule = model.schedule(session.variantId);
    final lanes = tl is ReducerTimeline<ThreadSchedState, VizStep> ? tl : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (lesson.provenance != null) ...[ProvenanceBadge(provenance: lesson.provenance!), const SizedBox(height: AppDimensions.spacingMd)],
      if (variants.length > 1) ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in variants) VizChip(label: v.label, selected: v.id == session.variantId, onTap: () => session.setVariant(v.id)),
        ]),
        if (schedule != null && schedule.label.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(schedule.label, key: const Key('schedule-label'), style: AppTextStyles.caption)),
        const SizedBox(height: AppDimensions.spacingMd),
      ],
      Row(children: [
        VizChip(label: 'Thread lanes', icon: Icons.view_agenda_outlined, selected: !session.show3D, onTap: () => session.set3D(false)),
        const SizedBox(width: 8),
        VizChip(label: '3D view', icon: Icons.view_in_ar_rounded, selected: session.show3D, onTap: () => session.set3D(true)),
      ]),
      if (session.failure != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('3D could not start on this device, so you are seeing the thread lanes. Everything else works the same.', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
        ),
      const SizedBox(height: AppDimensions.spacingSm),
      if (session.show3D) ...[
        VizViewport(
          key: ValueKey('${lesson.id}|${session.variantId}'),
          timeline: tl,
          controller: pb,
          interactions: lesson.interactions,
          selectedId: session.selectedId,
          onSelect: session.select,
          onFailure: session.reportFailure,
        ),
        _SelectedNode(session: session),
      ] else if (lanes != null)
        ThreadLanes(key: ValueKey('lanes|${session.variantId}'), timeline: lanes, controller: pb, code: tl.code, expected: schedule?.expected),
      const SizedBox(height: AppDimensions.spacingMd),
      EventTimeline(timeline: tl, controller: pb, actorLabel: threadLabel),
      const SizedBox(height: AppDimensions.spacingMd),
      VizControls(controller: pb, markers: tl.markers),
      const SizedBox(height: AppDimensions.spacingSm),
      const AudioControls(),
      const SizedBox(height: AppDimensions.spacingSm),
      NarrationCaption(narration: narration, playback: pb, textAt: (p) => session.frameAt(p).explanation.narration),
      const SizedBox(height: AppDimensions.spacingSm),
      AnimatedBuilder(
        animation: pb,
        builder: (context, _) {
          final frame = session.frameAt(pb.position);
          final marks = tl.eventMarks;
          final mark = pb.position > 0 && pb.position <= marks.length ? marks[pb.position - 1] : null;
          final event = lanes != null && pb.position > 0 ? lanes.events[pb.position - 1] : null;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EventInspector(
              explanation: frame.explanation,
              position: pb.position,
              length: pb.length,
              actor: mark == null ? null : threadLabel(tl.actors[mark.actor]),
              kind: event == null ? null : _kind(event),
            ),
            const SizedBox(height: AppDimensions.spacingSm),
            ExplanationPanel(explanation: frame.explanation, code: tl.code, showNarration: false, showHazard: false),
          ]);
        },
      ),
      VizOutcomeCard(session: session),
    ]);
  }

  static String _kind(VizStep e) => switch (e.kind.toUpperCase()) {
        'COMPUTE' => 'calculate',
        'LOCK' => e.blocked ? 'wait for lock' : 'take lock',
        'UNLOCK' => 'release lock',
        final k => k.toLowerCase(),
      };
}

class _SelectedNode extends StatelessWidget {
  final VizSession session;
  const _SelectedNode({required this.session});

  @override
  Widget build(BuildContext context) {
    final id = session.selectedId;
    final node = id == null ? null : session.frame.scene.node(id);
    if (node == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accentCyan.withOpacity(0.6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('INSPECTING', style: AppTextStyles.eyebrow.copyWith(color: AppColors.accentCyan)),
          const Spacer(),
          InkWell(onTap: () => session.select(null), child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint)),
        ]),
        const SizedBox(height: 6),
        for (final e in node.inspect.entries.where((e) => e.value.isNotEmpty))
          Text.rich(TextSpan(children: [
            TextSpan(text: '${e.key}: ', style: AppTextStyles.caption),
            TextSpan(text: e.value, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ])),
      ]),
    );
  }
}
