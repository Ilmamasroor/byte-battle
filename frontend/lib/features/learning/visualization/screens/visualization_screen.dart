import 'package:flutter/material.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/models/backend_models.dart';
import '../../../../core/network/backend_api.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../concepts/presentation/widgets/concept_progress.dart';
import '../../data/learning_progress_service.dart';
import '../../../../core/widgets/ai/companion_says.dart';
import '../../../../core/widgets/brand/bit_mascot.dart';
import '../../../../core/widgets/brand/confetti.dart';
import '../../../../core/voice/sound_cues.dart';
import '../../../../core/voice/voice_sheet.dart';
import '../../scenes/scene_models.dart';
import '../../scenes/scene_view.dart';
import '../../viz3d/engine/narration_controller.dart';
import '../../viz3d/engine/viz_session.dart';
import '../../viz3d/modules/concurrency/builtin_lost_update.dart';
import '../../viz3d/modules/concurrency/thread_schedule_lesson.dart';
import '../../viz3d/registry/viz_registry.dart';
import '../../viz3d/ui/narration_caption.dart';
import '../../viz3d/ui/provenance_badge.dart';
import '../../viz3d/ui/viz_shell.dart';
import '../widgets/scheduler_game.dart';
import '../widgets/thread_lab.dart';

/// "See it happen". Shows the concept as a visual that follows the real mechanism: the backend parses the
/// exercise's Java, simulates the schedules deterministically and returns the steps, the detected hazard and a fix
/// hint; this screen plays them back with a scrubber so the learner can SEE the lost update happen.
///
/// The picture comes from the shared visualization platform (`viz3d/`): one [VizSession] per source holds the
/// lesson, variant, playback position and selection, and the 3D view, the flat lane board and the controls all
/// read it, so there is a single source of truth for where the learner is.
class VisualizationScreen extends StatefulWidget {
  final String conceptId;

  const VisualizationScreen({super.key, required this.conceptId});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

enum _Source { sim, lab, scene }

class _VisualizationScreenState extends State<VisualizationScreen> {
  VisualizationModel? _viz;
  String? _error;
  bool _loading = true;

  VizSession? _sim; // the thread schedules: The bug / Another order / With synchronized / Deadlock
  NarrationController? _narration; // spoken narration and sound cues for _sim, tied to its playback
  NarrationController? _labNarration; // the same event-driven narration for the 3D lab
  VizSession? _lab; // every other lesson for this concept: input-driven simulations and 3D walkthroughs
  _Source _source = _Source.sim;
  bool _gameMode = false;
  SceneDoc? _scene;
  String? _prediction; // the learner's guess for the final value, before watching
  int _confetti = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeSessions();
    super.dispose();
  }

  void _disposeSessions() {
    _narration?.dispose();
    _narration = null;
    _labNarration?.dispose();
    _labNarration = null;
    _sim?.removeListener(_refresh);
    _sim?.controller.removeListener(_refresh);
    _sim?.dispose();
    _lab?.dispose();
    _sim = null;
    _lab = null;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _kind => _sim?.variantId ?? 'RACE'; // which schedule is being played

  /// The simulator said it cannot model this program accurately, so no sequence is drawn for it.
  bool get _unsupported => _viz != null && _viz!.support.status == VizSupport.unsupported;
  int get _shown => _sim?.controller.position ?? 0;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final scene = await SceneRepository.forConcept(widget.conceptId);
    VisualizationModel? viz;
    String? error;
    try {
      viz = await BackendApi.instance.conceptVisualization(widget.conceptId);
    } on NetworkException catch (e) {
      error = e.statusCode == 404 ? 'There is no visualization for this concept yet.' : e.message;
    } catch (_) {
      error = 'Could not load the visualization. Please try again.';
    }
    if (!mounted) return;
    viz ??= widget.conceptId == kRaceConditionsConceptId ? builtinLostUpdate() : null; // offline: the authored lost-update lesson
    _buildSessions(scene, viz);
    setState(() {
      _scene = scene;
      _viz = viz;
      _error = (_sim != null || _lab != null || scene != null) ? null : (error ?? 'No visualization available.');
      _loading = false;
    });
  }

  void _buildSessions(SceneDoc? scene, VisualizationModel? viz) {
    _disposeSessions();
    final res = VizRegistry.instance.resolve(VizSource(conceptId: widget.conceptId, scene: scene, simulation: (viz != null && viz.support.status == VizSupport.unsupported) ? null : viz));
    final thread = res.lessons.where(isThreadScheduleLesson).toList();
    final lab = res.lessons.where((l) => !isThreadScheduleLesson(l)).toList();
    if (thread.isNotEmpty) {
      final s = VizSession(
          lessons: thread,
          prefer3D: false, // the thread lanes explain this concept best; the 3D chamber stays one tap away
          variant: viz?.schedule('RACE') != null ? 'RACE' : (viz?.schedule('DEADLOCK') != null ? 'DEADLOCK' : null),
          onFinished: () {
            if (mounted && (_kind == 'SYNC' || _kind == 'SAFE')) setState(() => _confetti++);
          });
      s.addListener(_refresh);
      s.controller.addListener(_refresh);
      _sim = s;
      _narration = NarrationController(
        playback: s.controller,
        textAt: (p) => s.frameAt(p).explanation.narration,
        cueAt: (p) => SoundCue.parse(s.frameAt(p).explanation.cue),
      );
    }
    if (lab.isNotEmpty) {
      final l = VizSession(lessons: lab);
      _lab = l;
      _labNarration = NarrationController(playback: l.controller, textAt: (p) => l.frameAt(p).explanation.narration);
    }
    _source = _sim != null ? _Source.sim : (_lab != null ? _Source.lab : _Source.scene);
  }

  VizSchedule? get _schedule => _viz?.schedule(_kind);

  Future<void> _continue() async {
    await LearningProgressService.completeIfAt(widget.conceptId, 'VISUALIZE');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(RouteNames.relate, arguments: {'conceptId': widget.conceptId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('See it happen', style: AppTextStyles.heading2),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppDimensions.screenPadding, 0, AppDimensions.screenPadding, AppDimensions.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConceptProgress(
              current: ConceptStage.visualize,
              conceptId: widget.conceptId,
              routes: const {
                ConceptStage.concept: RouteNames.conceptDetail,
                ConceptStage.understand: RouteNames.understand,
                ConceptStage.visualize: RouteNames.explore,
                ConceptStage.relate: RouteNames.relate,
              },
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            Expanded(child: _content()),
            const SizedBox(height: AppDimensions.spacingMd),
            AppButton(label: 'Next: Relate', icon: Icons.arrow_forward_rounded, onPressed: _continue),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) return const LoadingView(message: 'Setting up the simulation...');
    if (_sim == null && _lab == null && _scene == null) {
      if (_unsupported) return SingleChildScrollView(child: UnsupportedNotice(support: _viz!.support));
      return ErrorView(message: _error ?? 'No visualization available.', onRetry: _load);
    }
    final Widget body;
    switch (_source) {
      case _Source.sim:
        body = _simView();
      case _Source.lab:
        body = _labView();
      case _Source.scene:
        body = _sceneView();
    }
    final sources = [if (_sim != null) _Source.sim, if (_lab != null) _Source.lab, if (_scene != null) _Source.scene];
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_unsupported) ...[UnsupportedNotice(support: _viz!.support), const SizedBox(height: AppDimensions.spacingMd)],
        if (sources.length > 1) ...[_sourceSwitch(sources), const SizedBox(height: AppDimensions.spacingMd)],
        body,
      ]),
    );
  }

  Widget _sceneView() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_scene!.title, style: AppTextStyles.display.copyWith(fontSize: 24)),
        const SizedBox(height: AppDimensions.spacingMd),
        SceneView(key: ValueKey(_scene!.conceptId), doc: _scene!),
      ]);

  Widget _labView() {
    final lab = _lab!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lab.lesson.title, style: AppTextStyles.display.copyWith(fontSize: 24)),
      const SizedBox(height: AppDimensions.spacingSm),
      const Align(alignment: Alignment.centerRight, child: VoiceButton()),
      VizShell(
        session: lab,
        // The lab's narration is one utterance per selected event, owned by the controller and paced by it; the bubble
        // only shows the same text (the guess-first question is spoken by its own bubble before playback exists).
        narrationBuilder: (context, e) => lab.needsGuess
            ? CompanionSays(speak: true, mood: BitMood.curious, text: e.text)
            : NarrationCaption(narration: _labNarration!, playback: lab.controller, textAt: (p) => lab.frameAt(p).explanation.narration),
      ),
    ]);
  }

  Widget _simView() {
    final sim = _sim!;
    final viz = _viz;
    final schedule = _schedule ?? viz?.schedules.first;
    if (viz == null || schedule == null) return ErrorView(message: _error ?? 'No visualization available.', onRetry: _load);
    final pb = sim.controller;
    final atEnd = pb.atEnd && schedule.steps.isNotEmpty;
    final raceKind = _kind == 'RACE' || _kind == 'RACE_ALT';
    final hazard = viz.hazards.isNotEmpty && raceKind ? viz.hazards.first : null;
    final raceSchedule = viz.schedule('RACE');
    final canPlay = raceSchedule != null && SchedulerGame.supports(raceSchedule);
    final fixKind = viz.schedule('SYNC') != null ? 'SYNC' : (viz.schedule('SAFE') != null ? 'SAFE' : null);
    final guessing = _kind == 'RACE' && _prediction == null && _shown == 0 && schedule.expected != null && schedule.actual != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(alignment: Alignment.centerRight, child: VoiceButton()),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
                label: 'Watch',
                icon: Icons.play_circle_outline_rounded,
                selected: !_gameMode,
                onTap: () => setState(() {
                      _gameMode = false;
                    })),
            _Pill(
              label: 'You are the scheduler',
              icon: Icons.sports_esports_rounded,
              selected: _gameMode,
              enabled: canPlay,
              onTap: () => setState(() {
                pb.pause();
                _narration?.cancel();
                _labNarration?.cancel();
                _gameMode = true;
              }),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        if (_gameMode && raceSchedule != null)
          SchedulerGame(schedule: raceSchedule)
        else if (guessing)
          _PredictCard(expected: schedule.expected!, actual: schedule.actual!, onPick: (v) => setState(() => _prediction = v))
        else ...[
          Stack(children: [
            ThreadLab(session: sim, model: viz, narration: _narration!),
            Positioned.fill(child: IgnorePointer(child: ConfettiBurst(trigger: _confetti))),
          ]),
          if (atEnd && raceKind && _prediction != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
              child: Text(
                _prediction == schedule.actual ? 'You predicted ${schedule.actual}, and that is what happened.' : 'You predicted $_prediction. It ended at ${schedule.actual}.',
                key: const Key('prediction-result'),
                style: AppTextStyles.bodyBold,
              ),
            ),
          if (atEnd && hazard != null && (hazard.fixSuggestion.isNotEmpty || viz.fixSuggestion.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingMd),
              child: _FixCard(text: hazard.fixSuggestion.isNotEmpty ? hazard.fixSuggestion : viz.fixSuggestion, onWatch: fixKind == null ? null : () => sim.setVariant(fixKind)),
            ),
        ],
      ],
    );
  }

  Widget _sourceSwitch(List<_Source> sources) {
    final sceneLabel = _scene?.kind == SceneKind.computer ? 'Inside the computer' : 'Animated walkthrough';
    String label(_Source s) => s == _Source.sim ? 'Thread simulator' : (s == _Source.lab ? '3D lab' : sceneLabel);
    IconData icon(_Source s) => s == _Source.sim ? Icons.account_tree_rounded : (s == _Source.lab ? Icons.view_in_ar_rounded : Icons.memory_rounded);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final s in sources)
        _Pill(
          label: label(s),
          icon: icon(s),
          selected: _source == s,
          onTap: () => setState(() {
            _sim?.controller.pause();
            _lab?.controller.pause();
            _narration?.cancel();
            _labNarration?.cancel();
            _source = s;
          }),
        ),
    ]);
  }

}

class _Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap, this.icon, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
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

class _PredictCard extends StatelessWidget {
  final String expected;
  final String actual;
  final ValueChanged<String> onPick;
  const _PredictCard({required this.expected, required this.actual, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final e = int.tryParse(expected);
    final options = {actual, expected, if (e != null) '${e + 1}'}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CompanionSays(
          speak: true,
          mood: BitMood.curious,
          text: 'Before we run it: two threads each add 1 to the same counter. Both start together. What do you think the counter ends at?',
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Row(
          children: [
            for (final o in options) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => onPick(o),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    alignment: Alignment.center,
                    child: Text(o, style: AppTextStyles.display.copyWith(fontSize: 36)),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Text('Tap your guess, then watch what really happens', style: AppTextStyles.caption)),
      ],
    );
  }
}

class _FixCard extends StatelessWidget {
  final String text;
  final VoidCallback? onWatch;
  const _FixCard({required this.text, this.onWatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.build_circle_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW TO FIX IT', style: AppTextStyles.eyebrow.copyWith(color: AppColors.success)),
                const SizedBox(height: 4),
                Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Synchronized makes this read, calculate and write run as one unit. It does not make every concurrent program safe.', style: AppTextStyles.caption),
                if (onWatch != null) TextButton(onPressed: onWatch, child: const Text('Watch it with synchronized')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
